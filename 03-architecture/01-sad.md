# Software Architecture Document (SAD) — Lymarks

> **Purpose:** component map, flows, and module specs. · **Status:** living · **Updated:** 2026-08-07

## Overview

```
[Flutter App] ──(share intent)── [Share Extension iOS/Android]
      │                                  │
      └────────── HTTPS + JWT Clerk ─────┘
                        │
              [Hono API @ Cloudflare Workers]
                        │  (waitUntil / Queues for async)
   ┌───────────┬────────┼─────────────┬──────────────┐
[Scraper]  [Summarizer] [Embedder]  [Neon Postgres] [Push]
(fetch +    (Groq        (Gemini     (+ pgvector)   (FCM/APNs)
Readability) Llama 3.3)  emb-004)
```

Auth: **Clerk** (JWT verified by Hono middleware via JWKS). Monetisation: **RevenueCat** (webhook → `subscriptions` table).

## Flow 1 — Lymark ingestion
1. Share extension → `POST /bookmarks` `{url, note?}` (JWT).
2. API responds **201 immediately** (`status: processing`) then continues in background (`ctx.waitUntil`). ⚠️ TBD: move to Cloudflare Queues if Workers timeouts are a problem on large pages.
3. Scraper: fetch the URL (SSRF protections, see Security §3) → text extraction (Readability-like), truncated to ~8,000 tokens.
4. Summarizer: Groq → `{bullets[3], keywords[], lang}` (strict JSON).
5. Embedder: Gemini `text-embedding-004` on `title + bullets + note` → vector(768).
6. UPDATE bookmark → `status: ready` (or `partial`/`failed`).

## Flow 2 — Search
`GET /search?q=` → if Free plan: Postgres full-text (`tsvector` or `ILIKE` V1). If Pro: query embedding (Gemini) + `ORDER BY embedding <=> $1` (cosine, HNSW index) merged with full-text (weighted score 0.7 semantic / 0.3 text ⚠️ to calibrate).

## Flow 3 — Daily Digest
Workers Cron Trigger (every 30 min) → selects Pro users whose local time = chosen time → re-surfacing algorithm (see Knowledge Vault Spec §4) → FCM/APNs push. ⚠️ TBD: FCM only (covers iOS via APNs) — proposed for a single channel.

## Module specifications

### M1 — Share Extension (Flutter + native)
**Responsibilities:** intercept shared URL+text, capture note, POST, close. **Interfaces:** `receive_sharing_intent`; `POST /bookmarks`. **Events:** `share_received`, `bookmark_submitted`, `queued_offline`. **Tests:** share from X, Safari, Chrome, YouTube, LinkedIn on real iOS and Android devices (edge cases: text without URL, multi-URL).

### M2 — Ingestion Pipeline (Workers)
**Responsibilities:** orchestrate scraper→LLM→embedding→DB; idempotence by `(user_id, url_hash)`; retries (1 Groq retry, then `failed`). **Interfaces:** internal; output = `bookmarks` row. **Tests:** Groq/Gemini mocks; OK / paywalled / JS-only / 404 / >8k tokens / prompt injection in content pages.

### M3 — Search Engine (Workers + Neon)
**Responsibilities:** text + vector queries, fusion, strict scoping by `user_id`. **Tests:** recall on 50-bookmark test set; P95 latency <800 ms.

### M4 — Digest Engine (Cron Workers)
**Responsibilities:** scoring, link selection, push send, `digests` logging. **Tests:** never 2 pushes/day; timezone respected; opt-out effective.

### M5 — Paywall & Entitlements (Flutter + Workers)
**Responsibilities:** display RevenueCat paywall, reflect `pro` entitlement server-side (webhook), **enforce limits server-side**. **Tests:** sandbox purchase, restore, expiration, bypass attempt (direct API call in Free beyond 30).

## Appendix — Tech stack and roles
| Layer | Tech | Role | Pinned version |
|---|---|---|---|
| Mobile | Flutter (Dart 3) | UI 60–120 FPS, share extension | ⚠️ pin at D1 |
| Auth | Clerk | Accounts, Google/Apple OAuth, JWT | current stable SDK |
| API | Hono (TS) on Cloudflare Workers | Minimal latency, 0 ms cold start | same |
| DB | Neon Postgres + pgvector | Data + vectors, dev/prod branching | pgvector ≥0.7 |
| LLM | Groq (Llama 3.3 70B) | 3-bullet summaries, keyword extraction | — |
| Embeddings | Gemini `text-embedding-004` | 768-d vectors | — |
| Payments | RevenueCat (`purchases_flutter`) | Subscriptions, entitlements | — |
| Push | FCM (+APNs) | Digest | ⚠️ TBD |

Justification for each choice: see `adr/`.
