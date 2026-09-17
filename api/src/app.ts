// Assemblage de l'application Hono. Pure fonction des dépendances : les tests
// l'instancient avec des doubles, `index.ts` avec l'environnement Workers.

import { Hono } from "hono";
import type { AppDeps } from "./deps.js";
import { requireAuth, type AuthVariables } from "./middleware/auth.js";
import { errorResponse } from "./middleware/errors.js";
import { bookmarksRoutes } from "./routes/bookmarks.js";
import { meRoutes } from "./routes/me.js";
import { searchRoutes } from "./routes/search.js";
import { webhookRoutes } from "./routes/webhooks.js";

export function createApp(deps: AppDeps): Hono {
  const app = new Hono();
  app.onError(errorResponse);
  app.notFound((c) => c.json({ error: "not_found", message: "Route inconnue" }, 404));

  // En-têtes de transport (Security §6). Pas de CORS : l'app mobile n'en a pas besoin.
  app.use("*", async (c, next) => {
    await next();
    c.header("strict-transport-security", "max-age=31536000; includeSubDomains");
    c.header("x-content-type-options", "nosniff");
    c.header("cache-control", "no-store");
  });

  app.get("/health", async (c) => {
    let db: "ok" | "down" = "ok";
    try {
      await deps.db.ping();
    } catch {
      db = "down";
    }
    return c.json({ ok: db === "ok", version: deps.version, db }, db === "ok" ? 200 : 503);
  });

  app.route("/webhooks", webhookRoutes(deps));

  const authed = new Hono<{ Variables: AuthVariables }>();
  authed.use("*", requireAuth(deps.verifyToken, deps.db));
  authed.route("/bookmarks", bookmarksRoutes(deps));
  authed.route("/search", searchRoutes(deps));
  authed.route("/me", meRoutes(deps));
  app.route("/", authed);

  return app;
}
