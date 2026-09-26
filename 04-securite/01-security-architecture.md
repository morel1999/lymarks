# Security Architecture — Lymarks

> **Purpose:** security measures by layer. · **Status:** living · **Updated:** 2026-08-07

## 1. Authentication and sessions
- Clerk JWTs verified on **every** request by Hono middleware (signature via cached JWKS, short `exp`, controlled audience).
- No unauthenticated endpoint except `/health` and the RevenueCat webhook (protected by its own dedicated signature).
- `user_id` extracted from the JWT only — never from the body — and injected into **every** SQL query (`WHERE user_id = $1`). No enumerable resource IDs: UUID v4 everywhere.

## 2. Secrets
- Groq, Gemini, Neon, RevenueCat webhook secret keys: **Cloudflare Workers Secrets** exclusively. Zero keys in the Flutter app, zero keys in the repo (`.dev.vars` gitignored, GitLeaks in CI ⚠️ to confirm in Coding Standards).
- The mobile app only talks to the Lymarks API — never directly to Groq/Gemini/Neon.
- Only the Clerk publishable key (public by design) is bundled client-side.

## 3. Scraper — anti-SSRF (critical surface #1)
The user submits an arbitrary URL that **our** server will fetch:
- Allowed schemes: `http(s)` only.
- DNS resolution then blocking of private/reserved IPs (10/8, 172.16/12, 192.168/16, 127/8, 169.254/16, ::1, fd00::/8) — re-checked **after every redirect** (max 3).
- Timeout 10 s, max size 2 MB, allowed content-types: `text/html`, `application/xhtml+xml`.
- Fetch goes from the Cloudflare edge, no credentials, User-Agent identified as `LymarksBot/1.0`.

## 4. Untrusted content → LLM
Scraped text can contain hostile instructions. See Threat Model M2. Measures: strict system prompt (content is data, not instruction), JSON-schema-validated output (max 3 bullets, bounded lengths), no tools given to the LLM, escaped at display in Flutter.

## 5. Quotas and abuse
- Per-user rate limiting: 30 captures/h, 60 searches/h (Workers Rate Limiting ⚠️ or Neon counter). Protects Groq/Gemini costs.
- Plan limits enforced server-side (see Monetization Spec §3).

## 6. Transport, storage, client
- TLS everywhere (Cloudflare/Neon default), HSTS.
- Neon: encryption at rest (native), minimal-rights SQL application role, dev branch ≠ prod.
- Flutter: tokens in secure storage (`flutter_secure_storage`: Keychain/Keystore), no sensitive data in logs, certificate pinning ⚠️ TBD (proposed: no in V1, complexity > risk).

## 7. Delivery chain
- Build signing: App Store (automatic), Play App Signing.
- CI: lint + tests + secrets scan before any deployment (`wrangler deploy` from CI only).
- Pinned dependencies (pubspec.lock / package-lock committed), audit before release.
