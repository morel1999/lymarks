# Privacy Specification — Lymarks

> **Purpose:** what data, where, how long, and how to delete everything. · **Status:** living · **Updated:** 2026-08-07

## 1. Data collected
| Data | Why | Where |
|---|---|---|
| Identity (email, name, OAuth ID) | Account | Clerk |
| URL, title, extracted content (temporary), personal note | Core service | Neon (extracted content not retained after summary ⚠️ confirmed: we keep only title+bullets+keywords) |
| Summaries, keywords, embeddings | Search/digest | Neon |
| Push token, timezone, digest time | Digest | Neon |
| Subscription status | Pro rights | RevenueCat + Neon |

No third-party analytics collected in V1.0 (⚠️ TBD if added: consent + privacy label update).

## 2. What is sent to third parties
- **Groq**: extracted page text (not the personal note ⚠️ decision: the note is NOT sent to the LLM, it is purely local to the card).
- **Gemini**: title + bullets (+ Pro search queries) for vectorisation.
- **Clerk / RevenueCat**: identity / purchases, respectively.
No data sold, no advertising profiling.

## 3. What stays local (device)
Offline queue, UI preferences, display cache. Everything else is server-side (multi-device sync follows from this).

## 4. Retention
Account data and lymarks: retained while the account exists. API logs: 7 days, without request bodies. Digest events: 90 days (algorithm tuning).

## 5. Deletion and portability
- **In-app account deletion** (Apple requirement): Neon purge (bookmarks, embeddings, digests, subscriptions) + Clerk deletion + RevenueCat subscriber delete. Effect ≤30 days, immediate for access.
- **JSON export**: url, note, summary, tags, dates. Planned for Pro. ⚠️ TBD: GDPR (art. 20) requires portability for Free too → proposal: export available to all, highlighted for Pro.
- Deleting a single lymark: also deletes its embedding and digest events.

## 6. Compliance
GDPR (EU) / KVKK (Turkey): legal basis = performance of contract; digest = interest-profile-based processing → freely enabled/disabled. App Store Privacy Labels and Play Data Safety form filled from this document (see Store Compliance).
