# PRD — Lymarks

> **Purpose:** define features, behaviours, flows and priorities precisely. · **Status:** living · **Updated:** 2026-09-17

> **V1.0 = Android only** (ADR-007). Everything iOS-specific below is deferred to V1.1.

Priorities: **P0** = essential for V1.0 (Shipaton) · **P1** = V1.0 if time allows, otherwise V1.1 · **P2** = post-launch.

## 1. Features

### P0 — Core
| # | Feature | Expected behaviour |
|---|---|---|
| F1 | Capture via share menu | From any app (X, Chrome, YouTube, LinkedIn; Safari in V1.1): Share → Lymarks opens a lightweight native sheet. Optional note field. **Save** button. Closes immediately; processing in background. Target: <2 s tap→close. |
| F2 | AI pipeline | Backend: page text extraction → 3-bullet summary + keywords (Groq Llama 3.3) → embedding (Gemini) → stored in Neon. Target <15 s. The user never waits for this pipeline. |
| F3 | Lymark list | Reverse-chronological order. Card: title, favicon/source, 3 bullets, personal note, tags. States: `processing` (animated skeleton), `ready`, `partial`, `failed` (retry button). |
| F4 | Keyword search (Free) | Full-text search (title, note, summary, tags). Results <500 ms. |
| F5 | Auth | Clerk: Google / email in V1.0. Apple Sign-In in V1.1 with iOS (mandatory on iOS when a social login is offered). |
| F6 | Freemium + Paywall | Free limit: 30 lymarks. RevenueCat paywall triggered on the 31st save and on the 1st semantic search. Enforcement **server-side** (see `../09-produit/02-monetization-spec.md`). |
| F7 | Account deletion in-app | Required by Google Play (since 2024, any app with account creation) and Apple. Deletes everything (see Privacy Spec). |

### P1
| # | Feature | Behaviour |
|---|---|---|
| F8 | Semantic search (Pro) | Natural-language query → embedding → pgvector cosine similarity → results merged with full-text. |
| F9 | Smart Daily Digest (Pro) | Max 1 push notification/day, configurable time (default 8:30 local): "1 forgotten link" chosen by the re-surfacing algorithm (see `../05-data/01-knowledge-vault-spec.md`). Opt-out in 1 gesture. |
| F10 | Data export (Pro) | Full JSON export from settings. ⚠️ TBD: GDPR portability may require export even on Free (see Privacy Spec §6). |
| F11 | Note dictation | Via native keyboard dictation (no specific dev required; to verify in share sheet on iOS). |

### P2
Offline sync conflict resolution for multi-device sync (cloud already provides basic sync), home-screen widgets, editable manual tags, collections/projects, web app.

## 2. Main user flows
1. **Capture:** source app → Share → Lymarks → [optional note] → Save → back to source app. No extra step, ever.
2. **Retrieve:** open app → search field → natural-language query → open link. ⚠️ TBD: in-app browser (Custom Tabs / SFSafariViewController — proposed) or external.
3. **Digest:** 8:30 notification → tap → lymark detail → read / snooze / archive.
4. **Upgrade:** hit a limit → paywall → purchase → immediate unlock (entitlement `pro`).

## 3. Edge cases and behaviours
- **Page inaccessible to scraping** (press paywall, X without login, 100% JS page): fallback = title + OG tags only, status `partial`, summary from metadata; never a silent failure.
- **YouTube video:** V1.0 = title + description. ⚠️ TBD: transcript in V1.1.
- **URL duplicate (same user):** `saved_count` increment + note update; no duplicate in DB.
- **Multiple URLs in one share:** the first is saved, the user is notified in the sheet ("N more links, saving the first"). Decided at implementation, ADR-008.
- **Share without URL:** explicit refusal in the sheet ("No link in what you shared"). Lymarks saves links only.
- **Offline at capture:** local queue, sent when network returns; capture UX is identical.
- **Malicious page content:** scraped text is treated as untrusted (anti-injection, see Threat Model M2).

## 4. Constraints
- Shipaton deadline: **30/09/2026**. Next Gen requires a public repository + demo video, not a store publication.
- Solo developer, 14-day sprint: all P0 must be achievable alone.
- AI cost per lymark controlled (see `../06-ia/01-ai-architecture.md` §Costs).
- Android 10+ ⚠️ to confirm against `receive_sharing_intent` constraints. iOS 16+ in V1.1.

## 5. Explicitly out of V1.0 scope
Desktop web clipper, collaboration/collection sharing, Pocket/Instapaper import, team mode.
