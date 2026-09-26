# ADR-002 — Clerk for authentication
**Status:** accepted · 2026-08-07
**Context:** Google/Apple/email required, zero time to spend on password security.
**Decision:** Clerk; the API verifies JWTs via JWKS (no network call to Clerk on the hot path).
**Alternatives:** Supabase Auth (would couple to another DB ecosystem), Firebase Auth (heavier native config), home-grown auth (excluded: risk + delay).
**Consequences:** paid SaaS dependency at scale; vendor lock-in limited (standard JWT); Apple Sign-In covered natively.
