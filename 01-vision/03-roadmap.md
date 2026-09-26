# Product Roadmap — Lymarks

> **Purpose:** versioned milestones. · **Status:** living · **Updated:** 2026-09-18

> **V1.0 scope = Android only** (ADR-007). iOS in V1.1.

> **Reorientation — 2026-09-19: store submission dropped for this deadline.** The sprint targets the **Next Gen** category of the Shipaton (demo video + open-source repository, no developer account required), whose third criterion out of four is thoughtful use of RevenueCat. The "Play submission" milestones and the review buffer below are therefore obsolete; what replaces them: public repository, README, LICENSE, two-minute video, and Devpost page before 30/09. The rest of this document still describes the store path, which will become relevant again for a real release.

## Shipaton 2026 Sprint (V1.0)
| Step | Days | Content | Exit criterion |
|---|---|---|---|
| 1. Cloud infra | D1–D2 | Neon + pgvector (initial schema), Clerk configured, Hono API deployed on Workers | **Reached 18/09**: `https://lymarks-api.lymarks.workers.dev/health` → `{ok:true, db:ok}`, `/me` → 401 without token. Neon eu-central-1 migrated, Clerk linked, secrets in CI. |
| 2. Core Flutter + Share | D3–D6 | Flutter project ✔ (04/09), Android share sheet via native channel ✔ (ADR-008, 18/09), list + states ✔, **app connected to API + Clerk auth ✔ (18/09, ADR-010)** | **Reached 18/09**: real capture from Chrome on a physical Android, responsiveness judged good, `processing` cards visible. X and YouTube to confirm. End-to-end (capture → AI summary on device) to validate with next APK. |
| 3. AI pipeline + search | D7–D10 | Scraper → Groq → Gemini → Neon; full-text + cosine search | Code ready 18/09 (pipeline, anti-SSRF, hybrid search, on mocks). Criterion unchanged: a shared link surfaces via a semantic query **in production** |
| 4. Monetisation + store | D11–D14 | Play products, RevenueCat paywall, feature freeze at D11, submission ≤ D14 | Build submitted to Google Play |

**Store review buffer:** submitting at D14 leaves the necessary margin before 30/09/2026 (possible rejection → iteration, see Risk Register R1).

## Post-launch
- **V1.1:** **iOS** (Apple Sign-In, share extension with App Groups, Privacy Labels, IAP Apple — requires a Mac, see ADR-007), Daily Digest if out of V1.0 scope, YouTube transcripts, better extraction of JS-heavy pages.
- **V1.2:** iOS/Android widgets, manual tags, collections.
- **V2:** ⚠️ TBD — web app or public API. Decision after real usage data.
