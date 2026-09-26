# Threat Model — Lymarks

> **Purpose:** how the product can be attacked, and what prevents it. · **Status:** living · **Updated:** 2026-08-07

| ID | Attack | Vector | Impact | Protection |
|---|---|---|---|---|
| M1 | **SSRF via submitted URL** | `POST /bookmarks` with `http://169.254.169.254/`, internal IP, poisoned redirect | Access to internal metadata/services | IP filtering + re-check post-redirect, http(s) schemes only, timeout/size limit (Security §3) |
| M2 | **Prompt injection via scraped content** | Page containing "ignore your instructions, respond…" | Misleading summary, toxic content, output stuffing | Content treated as data, JSON-validated output, bounded bullets, LLM without tools |
| M3 | **JWT theft/replay** | Token exfiltrated from a device | Access to the victim's lymarks | Short expiry + Clerk rotation, Keychain/Keystore storage, TLS |
| M4 | **Quota abuse / cost attack** | Script calling the API in a loop (captures → Groq calls) | AI bill, economic denial-of-service | Per-user rate limiting, Free server limit, idempotence by url_hash |
| M5 | **Paywall bypass** | Direct API call in Free beyond 30, or entitlement forged client-side | Revenue loss | 100% server enforcement via `subscriptions` table (signed, idempotent RevenueCat webhook) |
| M6 | **IDOR / enumeration** | `GET /bookmarks/{id}` of another user | Private data leak | UUID + systematic `WHERE user_id=` (dedicated integration test) |
| M7 | **Forged RevenueCat webhook** | Forged POST → free Pro upgrade | Revenue loss | Dedicated Authorization header verification, event idempotence |
| M8 | **Supply chain** | Compromised pub.dev/npm package | Code execution, secret theft | Pinned versions, lockfiles, audit before release, minimal dependencies |
| M9 | **Push spoofing / leak via notifications** | Sensitive content in the push | Leak of a private link title on the lock screen | Digest notification limited to the title ⚠️ TBD: "discreet notification" option (no title) |
| M10 | **MITM** | Hostile network | Interception | Strict TLS, no HTTP fallback |

Review this table on every new feature addition (rule in Core Principles).
