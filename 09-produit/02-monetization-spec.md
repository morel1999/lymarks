# Monetization Spec — Lymarks (RevenueCat)

> **Purpose:** products, entitlements, enforcement. · **Status:** living · **Updated:** 2026-09-19

## 1. Plans
| Plan | Content | Enforced limits |
|---|---|---|
| **Free** | Capture + AI summaries, keyword search | 30 active lymarks (`archived=false`), no semantic search, no digest |
| **Pro** monthly / annual | Unlimited, semantic search, Daily Digest, export | — |

Price ⚠️ TBD — proposal: €4.99/month · €39.99/year (−33%), to adjust by territory via the consoles. Free trial ⚠️ TBD (proposal: 7 days on annual only).

## 2. RevenueCat
Single entitlement **`pro`**; offerings `default` (monthly, annual). App: `purchases_flutter`, RevenueCat login with the Clerk ID (`appUserID = clerk_id`) to link purchases ↔ account. "Restore purchases" visible on the paywall and in settings (Apple requirement).

### Effective configuration (19/09, wired in code)
| Object | Value | Where it's read |
|---|---|---|
| Entitlement | `pro` | `RevenueCatBilling.proEntitlement`; webhook `entitlement_ids` |
| Current offering | `default` ("current") | `Purchases.getOfferings().current` |
| Packages | `$rc_monthly` → monthly, `$rc_annual` → annual (standard RevenueCat types; any other package is ignored) | `RevenueCatBilling.offer()` |
| Products (Test Store) | `lymarks_pro_monthly` (P1M), `lymarks_pro_annual` (P1Y) | RevenueCat only — the app only knows about packages |
| SDK key | `--dart-define=REVENUECAT_PUBLIC_KEY` (GitHub Secret, SDK public key; `REVENUECAT_API_KEY` remains the secret REST API key) | `AppConfig.revenuecatPublicKey` |
| Webhook | `POST https://lymarks-api…/webhooks/revenuecat`, header `Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>` (Workers secret) | `api/src/routes/webhooks.ts` |

**Shipaton Next Gen path: the Test Store.** Without a Play developer account, RevenueCat provides a Test Store app: the SDK, configured with its key, displays a simulated purchase sheet (succeed / fail / cancel), subscriptions renew at an accelerated pace (5 renewals, then cancellation), and **webhooks fire as in production** (`environment: SANDBOX`). Switching to Google Play later = create the Play app in RevenueCat, attach the same products/entitlement/offering, change the key at build time. The code does not move.

**App-side** (`app/lib/core/billing/`): `Billing` is the contract (offer, purchase, restore, identity); `RevenueCatBilling` implements it, `NoBilling` serves demo and tests; `BillingLink` follows the Clerk session (`identify` at sign-in, `forget` at sign-out). After a store-confirmed purchase, `ProfileNotifier` shows Pro immediately and re-reads `GET /me` (1, 2, 4, 8 s) until the webhook has set the right server-side — the app never waits, never decides.

## 3. Enforcement — absolute rule
**The source of truth for rights is the `subscriptions` table, fed by the RevenueCat webhook (signed, idempotent).** The API checks the plan on every: creation beyond 30 (`403 limit_reached`), semantic search, digest subscription, export. The client only displays — never decides (Threat Model M5).

## 4. Paywall triggers (UX Bible rule 11)
31st capture (after save, in-app banner — never in the share sheet) · 1st semantic search · digest activation · settings screen. Downgrade (Pro expiry): nothing is deleted; beyond 30 lymarks, read-only on the excess + capture blocked until archiving ⚠️ to validate.
