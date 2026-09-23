// /webhooks/revenuecat — seule écriture dans `subscriptions` (Monetization §3).
// Protégé par l'en-tête Authorization configuré côté RevenueCat, comparé en
// temps constant ; idempotent par identifiant d'événement (Threat Model M7).

import { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../deps.js";
import type { SubscriptionEvent } from "../db/types.js";
import { HttpError, parseBody } from "../middleware/errors.js";
import { background } from "./background.js";

const eventSchema = z.object({
  event: z.object({
    id: z.string().min(1),
    type: z.string().min(1),
    app_user_id: z.string().min(1),
    original_app_user_id: z.string().optional(),
    aliases: z.array(z.string()).optional(),
    entitlement_ids: z.array(z.string()).nullable().optional(),
    expiration_at_ms: z.number().nullable().optional(),
    event_timestamp_ms: z.number(),
    /** `SANDBOX` (Test Store, achats de test) ou `PRODUCTION` : journalisé, pas filtré. */
    environment: z.string().optional(),
  }),
});

export type RevenuecatPayload = z.infer<typeof eventSchema>;

/** Types après lesquels l'accès Pro est perdu. Les autres gardent l'accès jusqu'à `expires_at`. */
const REVOKING_TYPES = new Set(["EXPIRATION", "SUBSCRIPTION_PAUSED", "TRANSFER"]);

export function toSubscriptionEvent(payload: RevenuecatPayload, now: Date): SubscriptionEvent {
  const e = payload.event;
  const hasPro = (e.entitlement_ids ?? []).includes("pro");
  const expiresAt = e.expiration_at_ms ? new Date(e.expiration_at_ms) : null;
  const stillValid = expiresAt === null || expiresAt.getTime() > now.getTime();
  const pro = hasPro && stillValid && !REVOKING_TYPES.has(e.type);
  return {
    eventId: e.id,
    occurredAt: new Date(e.event_timestamp_ms),
    entitlement: pro ? "pro" : "free",
    expiresAt,
    rcAppUserId: e.app_user_id,
  };
}

/** Comparaison en temps constant de deux chaînes. */
export function safeEqual(a: string, b: string): boolean {
  const ea = new TextEncoder().encode(a);
  const eb = new TextEncoder().encode(b);
  let diff = ea.length ^ eb.length;
  const n = Math.max(ea.length, eb.length);
  for (let i = 0; i < n; i += 1) diff |= (ea[i % ea.length] ?? 0) ^ (eb[i % eb.length] ?? 0);
  return diff === 0;
}

export function webhookRoutes(deps: AppDeps): Hono {
  const app = new Hono();

  app.post("/revenuecat", async (c) => {
    const secret = deps.revenuecatWebhookSecret;
    if (!secret) throw new HttpError(503, "webhook_disabled", "Webhook non configuré");
    const header = c.req.header("authorization") ?? "";
    const presented = header.replace(/^Bearer\s+/i, "");
    if (!safeEqual(presented, secret))
      throw new HttpError(401, "unauthorized", "Signature invalide");

    const payload = await parseBody(c, eventSchema);
    if (payload.event.type === "TEST") return c.json({ ok: true, ignored: "test" });

    const event = toSubscriptionEvent(payload, deps.now());
    // L'app enregistre RevenueCat avec l'identifiant Clerk comme appUserID
    // (Monetization §2) ; les alias couvrent un achat fait avant connexion.
    const candidates = [
      payload.event.app_user_id,
      payload.event.original_app_user_id,
      ...(payload.event.aliases ?? []),
    ].filter((v): v is string => Boolean(v));
    let outcome: "applied" | "ignored" | "unknown_user" = "unknown_user";
    let matched: string | null = null;
    for (const clerkId of candidates) {
      outcome = await deps.db.subscriptions.applyEvent(clerkId, event);
      if (outcome !== "unknown_user") {
        matched = clerkId;
        break;
      }
    }

    // Passage en Pro : les lymarks gardes au-dela de la limite Free
    // redeviennent accessibles, et c'est seulement maintenant qu'ils
    // traversent le pipeline — on ne paie les modeles que pour des liens
    // que quelqu'un peut enfin lire.
    let unlocked = 0;
    if (outcome === "applied" && event.entitlement === "pro" && matched) {
      const user = await deps.db.users.findByClerkId(matched);
      if (user) {
        const freed = await deps.db.bookmarks.unlockAll(user.id);
        unlocked = freed.length;
        for (const b of freed) {
          background(
            deps.runPipeline({
              id: b.id,
              url: b.url,
              urlHash: b.urlHash,
              title: b.title,
            }),
            () => c.executionCtx,
          );
        }
      }
    }
    deps.log({
      event: "revenuecat_webhook",
      type: payload.event.type,
      environment: payload.event.environment ?? null,
      outcome,
      entitlement: event.entitlement,
      unlocked,
    });
    // Toujours 200 : RevenueCat rejoue sinon un événement qu'on ne saura pas mieux traiter.
    return c.json({ ok: true, outcome });
  });

  return app;
}
