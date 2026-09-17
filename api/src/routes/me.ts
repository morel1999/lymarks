// /me — profil, réglages du digest, export (Privacy §5) et suppression de
// compte (F7, exigence Google Play).

import { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../deps.js";
import type { AuthVariables } from "../middleware/auth.js";
import { HttpError, notFound, parseBody } from "../middleware/errors.js";
import { canUseDigest } from "../services/plan.js";
import { toMeDto } from "./serialize.js";

const settingsSchema = z
  .object({
    tz: z
      .string()
      .trim()
      .regex(/^[A-Za-z_]+(?:\/[A-Za-z0-9_+-]+){0,2}$/)
      .optional(),
    digestHour: z.number().int().min(0).max(23).optional(),
    digestOptin: z.boolean().optional(),
  })
  .refine((v) => Object.keys(v).length > 0, { message: "Rien à modifier" });

export function meRoutes(deps: AppDeps): Hono<{ Variables: AuthVariables }> {
  const app = new Hono<{ Variables: AuthVariables }>();

  app.get("/", async (c) => {
    const user = await deps.db.users.get(c.var.user.id);
    if (!user) throw notFound();
    const [plan, count] = await Promise.all([
      deps.db.subscriptions.getPlan(user.id),
      deps.db.bookmarks.countActive(user.id),
    ]);
    return c.json({ me: toMeDto(user, plan, count) });
  });

  app.patch("/", async (c) => {
    const patch = await parseBody(c, settingsSchema);
    const userId = c.var.user.id;
    const plan = await deps.db.subscriptions.getPlan(userId);
    if (patch.digestOptin === true && !canUseDigest(plan)) {
      throw new HttpError(403, "pro_required", "Le Daily Digest est réservé au plan Pro");
    }
    const user = await deps.db.users.updateSettings(userId, patch);
    if (!user) throw notFound();
    const count = await deps.db.bookmarks.countActive(userId);
    return c.json({ me: toMeDto(user, plan, count) });
  });

  // Portabilité : disponible pour tous (RGPD art. 20), mise en avant en Pro.
  app.get("/export", async (c) => {
    const rows = await deps.db.bookmarks.exportAll(c.var.user.id);
    return c.json({
      exportedAt: deps.now().toISOString(),
      lymarks: rows.map((b) => ({
        url: b.url,
        title: b.title,
        note: b.note,
        bullets: b.summary?.bullets ?? [],
        keywords: b.keywords,
        savedAt: b.createdAt.toISOString(),
        lastOpenedAt: b.lastOpenedAt?.toISOString() ?? null,
        archived: b.archived,
      })),
    });
  });

  app.delete("/", async (c) => {
    const { id, clerkId } = c.var.user;
    // 1. Neon d'abord : bookmarks, embeddings, digests, abonnement (cascade).
    await deps.db.users.delete(id);
    // 2. Clerk : sans cela l'utilisateur pourrait se reconnecter sur un compte vide.
    if (deps.deleteClerkUser) {
      try {
        await deps.deleteClerkUser(clerkId);
      } catch (err) {
        deps.log({ event: "clerk_delete_failed", userId: id, reason: (err as Error).message });
        throw new HttpError(
          502,
          "identity_delete_failed",
          "Données supprimées, compte d'identité à purger",
        );
      }
    }
    // 3. RevenueCat : best-effort, l'abonné n'a plus rien à quoi être lié.
    if (deps.deleteRevenuecatSubscriber) {
      await deps.deleteRevenuecatSubscriber(clerkId).catch((err: Error) => {
        deps.log({ event: "revenuecat_delete_failed", userId: id, reason: err.message });
      });
    }
    deps.log({ event: "account_deleted", userId: id });
    return c.body(null, 204);
  });

  return app;
}
