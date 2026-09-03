# ADR-003 — Cloudflare Workers + Hono
**Statut :** accepté · 2026-08-07
**Contexte :** backend appelé depuis une share extension → chaque milliseconde de latence dégrade la capture <2 s.
**Décision :** Hono (TypeScript) sur Workers : 0 ms cold start, edge mondial, `waitUntil` pour l'async, Cron Triggers pour le digest.
**Alternatives :** Node sur VPS (ops en plus), AWS Lambda (cold starts), Supabase Edge Functions (moins de contrôle réseau).
**Conséquences :** runtime non-Node (choisir des libs compatibles Workers) ; limites CPU/temps → pipeline découpé, option Queues si besoin.
