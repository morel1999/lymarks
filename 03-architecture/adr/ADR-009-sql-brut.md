# ADR-009 — Data access: raw SQL, no ORM
**Status:** accepted · 2026-09-18
**Context:** the Database Schema proposed Drizzle ORM (⚠️ TBD) and the dependency register listed `drizzle-orm` + `@neondatabase/serverless` with the alternative "raw SQL + postgres.js". The reference schema is already written in SQL in the docs; the key operations — pgvector cosine distance (`<=>`), `to_tsquery` with prefixes, `ON CONFLICT … WHERE` for webhook idempotence — are SQL that every ORM ends up exposing as `sql\`…\``.
**Decision:** raw SQL via the HTTP driver `@neondatabase/serverless` (`neon(url).query(text, params)`), concentrated in a single file `api/src/db/neon.ts` implementing the `Db` contract (`api/src/db/types.ts`). Migrations = numbered SQL files in `api/migrations/`, run by `scripts/migrate.ts` (Node, one transaction per file, `schema_migrations` table). An in-memory repository implements the same contract for tests.
**Alternatives:** Drizzle — a TypeScript schema to maintain alongside the SQL doc, `drizzle-kit` on top of a 3.8 GB machine, and vector/FTS queries stay in raw SQL anyway; Prisma — heavy client, poor pgvector support on Workers.
**Consequences:**
- The `Db` contract is the testable boundary: routes never see SQL, M5/M6 suites run without a database (Coding Standards §3: "no SQL query outside `src/db/`").
- Row → object mapping is manual (`toBookmark`, `toUser`): readable, but must be updated on every added column — strict typechecking flags it.
- No Neon test branch in CI for now: `neon.ts` is verified by typechecking and by first deployment; an integration test on an ephemeral branch to add when the pipeline is running (Test Strategy, API integration).
- Reversible: switching to Drizzle later only changes `neon.ts`.
