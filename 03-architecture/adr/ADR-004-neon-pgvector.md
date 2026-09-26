# ADR-004 — Neon Postgres + pgvector
**Status:** accepted · 2026-08-07
**Context:** store bookmarks, summaries and embeddings; cosine similarity search; separate dev/prod environments without a fixed cost.
**Decision:** Neon (serverless, Database Branching) with the pgvector extension (HNSW index).
**Alternatives:** Supabase (very close; Neon chosen for branching), Pinecone/Qdrant (a 2nd store to operate for 768-d × a few thousand rows: unjustified), SQLite/D1 (no mature pgvector).
**Consequences:** single store for data + vectors; standard SQL; Neon latency from the edge to measure (HTTP driver `@neondatabase/serverless`).
