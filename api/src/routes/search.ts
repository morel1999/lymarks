// /search — plein texte pour tous (F4), hybride sémantique + texte en Pro (F8).
// Le mode sémantique est refusé en Free côté serveur : le client n'affiche
// que le paywall (Monetization §3).

import { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../deps.js";
import type { AuthVariables } from "../middleware/auth.js";
import { HttpError, parseQuery } from "../middleware/errors.js";
import { canSearchSemantic } from "../services/plan.js";
import { MAX_QUERY_CHARS, queryTerms } from "../services/search.js";
import { toBookmarkDto } from "./serialize.js";

const searchSchema = z.object({
  q: z.string().trim().min(1).max(MAX_QUERY_CHARS),
  mode: z.enum(["text", "semantic"]).default("text"),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export function searchRoutes(deps: AppDeps): Hono<{ Variables: AuthVariables }> {
  const app = new Hono<{ Variables: AuthVariables }>();

  app.get("/", async (c) => {
    const { q, mode, limit } = parseQuery(c, searchSchema);
    const user = c.var.user;
    if (queryTerms(q).length === 0) return c.json({ items: [], mode });

    if (mode === "text") {
      const hits = await deps.db.bookmarks.searchText(user.id, q, limit);
      return c.json({
        items: hits.map((h) => ({
          bookmark: toBookmarkDto(h.bookmark, deps.now()),
          score: h.score,
        })),
        mode,
      });
    }

    const plan = await deps.db.subscriptions.getPlan(user.id);
    if (!canSearchSemantic(plan)) {
      throw new HttpError(403, "pro_required", "La recherche sémantique est réservée au plan Pro");
    }
    let vector: number[];
    try {
      vector = await deps.embedQuery(q);
    } catch (err) {
      deps.log({ event: "search_embed_failed", reason: (err as Error).message });
      // Dégradation : la recherche texte répond quand même.
      const hits = await deps.db.bookmarks.searchText(user.id, q, limit);
      return c.json({
        items: hits.map((h) => ({
          bookmark: toBookmarkDto(h.bookmark, deps.now()),
          score: h.score,
        })),
        mode: "text",
        degraded: true,
      });
    }
    const hits = await deps.db.bookmarks.searchHybrid(user.id, q, vector, limit);
    return c.json({
      items: hits.map((h) => ({ bookmark: toBookmarkDto(h.bookmark, deps.now()), score: h.score })),
      mode,
    });
  });

  return app;
}
