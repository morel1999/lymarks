# ADR-003 — Cloudflare Workers + Hono
**Status:** accepted · 2026-08-07
**Context:** backend called from a share extension → every millisecond of latency degrades the <2 s capture.
**Decision:** Hono (TypeScript) on Workers: 0 ms cold start, global edge, `waitUntil` for async, Cron Triggers for the digest.
**Alternatives:** Node on VPS (extra ops), AWS Lambda (cold starts), Supabase Edge Functions (less network control).
**Consequences:** non-Node runtime (choose Workers-compatible libs); CPU/time limits → pipeline split, Queues option if needed.
