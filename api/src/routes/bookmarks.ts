// /bookmarks — capture (F1/F2), liste (F3), fiche, note, archivage,
// suppression, retry, ouverture, similaires.

import { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../deps.js";
import type { AuthVariables } from "../middleware/auth.js";
import { HttpError, notFound, parseBody, parseQuery } from "../middleware/errors.js";
import {
  activeLimitFor,
  canCreate,
  CAPTURE_WINDOW_MS,
  CAPTURES_PER_HOUR,
} from "../services/plan.js";
import { SIMILAR_MIN_SCORE } from "../services/search.js";
import { detectSource, normalizeUrl, urlHash } from "../services/url.js";
import { toBookmarkDto } from "./serialize.js";

const createSchema = z.object({
  url: z.string().trim().min(1).max(2048),
  note: z.string().trim().max(2000).nullable().optional(),
  title: z.string().trim().max(500).nullable().optional(),
});

const patchSchema = z
  .object({
    note: z.string().trim().max(2000).nullable().optional(),
    archived: z.boolean().optional(),
  })
  .refine((v) => "note" in v || "archived" in v, { message: "Rien à modifier" });

const listSchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(50),
  before: z.coerce.date().optional(),
  archived: z
    .enum(["true", "false"])
    .transform((v) => v === "true")
    .optional(),
  status: z.enum(["processing", "ready", "partial", "failed"]).optional(),
});

const idSchema = z.uuid();

function background(
  promise: Promise<unknown>,
  ctx: () => { waitUntil(p: Promise<unknown>): void },
): void {
  const safe = promise.catch((err: unknown) => {
    console.error(JSON.stringify({ event: "pipeline_crashed", message: (err as Error)?.message }));
  });
  try {
    ctx().waitUntil(safe);
  } catch {
    // Hors Workers (tests sans contexte) : la promesse tourne seule.
  }
}

export function bookmarksRoutes(deps: AppDeps): Hono<{ Variables: AuthVariables }> {
  const app = new Hono<{ Variables: AuthVariables }>();

  app.post("/", async (c) => {
    const body = await parseBody(c, createSchema);
    const user = c.var.user;
    const normalized = normalizeUrl(body.url);
    if (!normalized) throw new HttpError(400, "invalid_url", "URL http(s) attendue");
    const hash = await urlHash(normalized);

    // Doublon : pas de nouvelle ligne, pas de nouveau passage IA (PRD §3).
    const existing = await deps.db.bookmarks.findByHash(user.id, hash);
    if (existing) {
      const bumped = await deps.db.bookmarks.bumpDuplicate(user.id, hash, body.note ?? null);
      return c.json({ bookmark: toBookmarkDto(bumped ?? existing), duplicate: true }, 200);
    }

    const plan = await deps.db.subscriptions.getPlan(user.id);
    const active = await deps.db.bookmarks.countActive(user.id);
    if (!canCreate(plan, active)) {
      throw new HttpError(403, "limit_reached", "Limite du plan Free atteinte", {
        limit: activeLimitFor(plan),
        count: active,
      });
    }
    const since = new Date(deps.now().getTime() - CAPTURE_WINDOW_MS);
    const recent = await deps.db.bookmarks.countCreatedSince(user.id, since);
    if (recent >= CAPTURES_PER_HOUR) {
      throw new HttpError(429, "rate_limited", "Trop de captures, réessaie dans une heure");
    }

    const created = await deps.db.bookmarks.insert(user.id, {
      url: normalized,
      urlHash: hash,
      source: detectSource(normalized),
      title: body.title ?? null,
      note: body.note ?? null,
    });
    deps.log({
      event: "bookmark_created",
      userId: user.id,
      bookmarkId: created.id,
      source: created.source,
    });
    background(
      deps.runPipeline({
        id: created.id,
        url: created.url,
        urlHash: created.urlHash,
        title: created.title,
      }),
      () => c.executionCtx,
    );
    return c.json({ bookmark: toBookmarkDto(created), duplicate: false }, 201);
  });

  app.get("/", async (c) => {
    const query = parseQuery(c, listSchema);
    const opts = {
      limit: query.limit,
      ...(query.before ? { before: query.before } : {}),
      ...(query.archived !== undefined ? { archived: query.archived } : {}),
      ...(query.status ? { status: query.status } : {}),
    };
    const rows = await deps.db.bookmarks.list(c.var.user.id, opts);
    const last = rows[rows.length - 1];
    return c.json({
      items: rows.map(toBookmarkDto),
      nextCursor: rows.length === query.limit && last ? last.createdAt.toISOString() : null,
    });
  });

  app.get("/:id", async (c) => {
    const id = idSchema.parse(c.req.param("id"));
    const row = await deps.db.bookmarks.get(c.var.user.id, id);
    if (!row) throw notFound();
    return c.json({ bookmark: toBookmarkDto(row) });
  });

  app.patch("/:id", async (c) => {
    const id = idSchema.parse(c.req.param("id"));
    const patch = await parseBody(c, patchSchema);
    const row = await deps.db.bookmarks.update(c.var.user.id, id, patch);
    if (!row) throw notFound();
    return c.json({ bookmark: toBookmarkDto(row) });
  });

  app.delete("/:id", async (c) => {
    const id = idSchema.parse(c.req.param("id"));
    const deleted = await deps.db.bookmarks.delete(c.var.user.id, id);
    if (!deleted) throw notFound();
    return c.body(null, 204);
  });

  app.post("/:id/opened", async (c) => {
    const id = idSchema.parse(c.req.param("id"));
    const ok = await deps.db.bookmarks.markOpened(c.var.user.id, id, deps.now());
    if (!ok) throw notFound();
    return c.body(null, 204);
  });

  app.post("/:id/retry", async (c) => {
    const id = idSchema.parse(c.req.param("id"));
    const row = await deps.db.bookmarks.resetForRetry(c.var.user.id, id);
    if (!row) {
      const exists = await deps.db.bookmarks.get(c.var.user.id, id);
      if (!exists) throw notFound();
      throw new HttpError(409, "not_retryable", "Ce lymark n'est ni en échec ni partiel");
    }
    background(
      deps.runPipeline({ id: row.id, url: row.url, urlHash: row.urlHash, title: row.title }),
      () => c.executionCtx,
    );
    return c.json({ bookmark: toBookmarkDto(row) }, 202);
  });

  app.get("/:id/similar", async (c) => {
    const id = idSchema.parse(c.req.param("id"));
    const ref = await deps.db.bookmarks.get(c.var.user.id, id);
    if (!ref) throw notFound();
    const hits = await deps.db.bookmarks.similar(c.var.user.id, id, 3, SIMILAR_MIN_SCORE);
    return c.json({
      items: hits.map((h) => ({ bookmark: toBookmarkDto(h.bookmark), score: h.score })),
    });
  });

  return app;
}
