// /bookmarks — capture (F1/F2), liste (F3), fiche, note, archivage,
// suppression, retry, ouverture, similaires.

import { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../deps.js";
import type { AuthVariables } from "../middleware/auth.js";
import { HttpError, notFound, parseBody, parseQuery } from "../middleware/errors.js";
import {
  activeLimitFor,
  CAPTURE_WINDOW_MS,
  CAPTURES_PER_HOUR,
  FREE_LOCKED_LIMIT,
  lockedStorageFull,
  shouldLock,
} from "../services/plan.js";
import { STALL_AFTER_MS, isStalled } from "../services/pipeline.js";
import { MAX_IMAGE_URL_CHARS } from "../services/scraper.js";
import { SIMILAR_MIN_SCORE } from "../services/search.js";
import { detectSource, normalizeUrl, urlHash } from "../services/url.js";
import { background } from "./background.js";
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

// Page lue par le téléphone (repli quand le serveur est bloqué). Le texte est
// borné large : le pipeline le tronque au même budget que le scraper.
const contentSchema = z.object({
  title: z.string().trim().max(300).optional(),
  text: z.string().trim().min(1).max(50_000),
  description: z.string().trim().max(1000).optional(),
  lang: z.string().trim().min(2).max(8).optional(),
  imageUrl: z
    .url({ protocol: /^https$/ })
    .max(MAX_IMAGE_URL_CHARS)
    .optional(),
});

const idSchema = z.uuid();

export function bookmarksRoutes(deps: AppDeps): Hono<{ Variables: AuthVariables }> {
  const app = new Hono<{ Variables: AuthVariables }>();
  const stalledBefore = (): Date => new Date(deps.now().getTime() - STALL_AFTER_MS);

  app.post("/", async (c) => {
    const body = await parseBody(c, createSchema);
    const user = c.var.user;
    const normalized = normalizeUrl(body.url);
    if (!normalized) throw new HttpError(400, "invalid_url", "URL http(s) attendue");
    const hash = await urlHash(normalized);

    // Doublon : pas de nouvelle ligne, pas de nouveau passage IA (PRD §3).
    const existing = await deps.db.bookmarks.findByHash(user.id, hash);
    if (existing) {
      // Doublon d'un traitement abandonné (l'envoi précédent a été coupé en
      // route) : on relance, c'est ce que l'utilisateur attend.
      if (isStalled(existing, deps.now())) {
        const reset = await deps.db.bookmarks.resetForRetry(user.id, existing.id, stalledBefore());
        if (reset) {
          deps.log({ event: "bookmark_requeued", userId: user.id, bookmarkId: reset.id });
          background(
            deps.runPipeline({
              id: reset.id,
              url: reset.url,
              urlHash: reset.urlHash,
              title: reset.title,
            }),
            () => c.executionCtx,
          );
          return c.json({ bookmark: toBookmarkDto(reset, deps.now()), duplicate: true }, 200);
        }
      }
      const bumped = await deps.db.bookmarks.bumpDuplicate(user.id, hash, body.note ?? null);
      return c.json(
        { bookmark: toBookmarkDto(bumped ?? existing, deps.now()), duplicate: true },
        200,
      );
    }

    const plan = await deps.db.subscriptions.getPlan(user.id);
    const active = await deps.db.bookmarks.countActive(user.id);
    // Au-dela de la limite Free, le lien n'est plus refuse : il est
    // enregistre et verrouille. Un partage qui echoue en silence fait perdre
    // des liens a un utilisateur qui continue de defiler ailleurs, sans
    // savoir que rien n'arrive. Il les verra, floutes, avec le pourquoi.
    const locked = shouldLock(plan, active);
    if (locked) {
      const lockedCount = await deps.db.bookmarks.countLocked(user.id);
      if (lockedStorageFull(plan, lockedCount)) {
        throw new HttpError(403, "limit_reached", "Limite du plan Free atteinte", {
          limit: activeLimitFor(plan),
          count: active,
          lockedLimit: FREE_LOCKED_LIMIT,
          locked: lockedCount,
        });
      }
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
      locked,
    });
    deps.log({
      event: "bookmark_created",
      userId: user.id,
      bookmarkId: created.id,
      source: created.source,
      locked,
    });
    // Un lymark verrouille ne traverse pas le pipeline : on ne paie Groq et
    // Gemini qu'au deverrouillage, jamais pour un lien que personne ne lira.
    if (!locked) {
      background(
        deps.runPipeline({
          id: created.id,
          url: created.url,
          urlHash: created.urlHash,
          title: created.title,
        }),
        () => c.executionCtx,
      );
    }
    return c.json({ bookmark: toBookmarkDto(created, deps.now()), duplicate: false }, 201);
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
      items: rows.map((b) => toBookmarkDto(b, deps.now())),
      nextCursor: rows.length === query.limit && last ? last.createdAt.toISOString() : null,
    });
  });

  app.get("/:id", async (c) => {
    const id = idSchema.parse(c.req.param("id"));
    const row = await deps.db.bookmarks.get(c.var.user.id, id);
    if (!row) throw notFound();
    return c.json({ bookmark: toBookmarkDto(row, deps.now()) });
  });

  app.patch("/:id", async (c) => {
    const id = idSchema.parse(c.req.param("id"));
    const patch = await parseBody(c, patchSchema);
    const row = await deps.db.bookmarks.update(c.var.user.id, id, patch);
    if (!row) throw notFound();
    return c.json({ bookmark: toBookmarkDto(row, deps.now()) });
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
    const row = await deps.db.bookmarks.resetForRetry(c.var.user.id, id, stalledBefore());
    if (!row) {
      const exists = await deps.db.bookmarks.get(c.var.user.id, id);
      if (!exists) throw notFound();
      throw new HttpError(409, "not_retryable", "Ce lymark n'est ni en échec ni partiel");
    }
    background(
      deps.runPipeline({ id: row.id, url: row.url, urlHash: row.urlHash, title: row.title }),
      () => c.executionCtx,
    );
    return c.json({ bookmark: toBookmarkDto(row, deps.now()) }, 202);
  });

  // Repli client : le serveur n'a pas pu lire la page (anti-robot, paywall),
  // le téléphone l'a lue et nous la confie. Mêmes conditions que `retry`,
  // même pipeline, l'étape scrape en moins.
  app.post("/:id/content", async (c) => {
    const id = idSchema.parse(c.req.param("id"));
    const body = await parseBody(c, contentSchema);
    const user = c.var.user;
    const row = await deps.db.bookmarks.resetForRetry(user.id, id, stalledBefore());
    if (!row) {
      const exists = await deps.db.bookmarks.get(user.id, id);
      if (!exists) throw notFound();
      throw new HttpError(409, "not_retryable", "Ce lymark n'est ni en échec ni partiel");
    }
    // Jamais le texte lui-même dans les journaux (Privacy §4), sa taille suffit.
    deps.log({
      event: "bookmark_content_received",
      userId: user.id,
      bookmarkId: row.id,
      chars: body.text.length,
      hasImage: body.imageUrl !== undefined,
    });
    background(
      deps.runPipeline({
        id: row.id,
        url: row.url,
        urlHash: row.urlHash,
        title: row.title,
        page: {
          title: body.title || null,
          description: body.description || null,
          text: body.text,
          lang: body.lang ?? null,
          imageUrl: body.imageUrl ?? null,
        },
      }),
      () => c.executionCtx,
    );
    return c.json({ bookmark: toBookmarkDto(row, deps.now()) }, 202);
  });

  app.get("/:id/similar", async (c) => {
    const id = idSchema.parse(c.req.param("id"));
    const ref = await deps.db.bookmarks.get(c.var.user.id, id);
    if (!ref) throw notFound();
    const hits = await deps.db.bookmarks.similar(c.var.user.id, id, 3, SIMILAR_MIN_SCORE);
    return c.json({
      items: hits.map((h) => ({ bookmark: toBookmarkDto(h.bookmark, deps.now()), score: h.score })),
    });
  });

  return app;
}
