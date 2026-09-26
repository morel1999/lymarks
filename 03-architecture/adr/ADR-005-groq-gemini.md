# ADR-005 — Groq (Llama 3.3) for summaries, Gemini for embeddings
**Status:** accepted · 2026-08-07
**Context:** near-real-time 3-bullet summaries, minimal cost per lymark; high-quality multilingual embeddings.
**Decision:** Groq Llama 3.3 70B (inference speed, low cost); Gemini `text-embedding-004` (768-d) for vectorisation.
**Alternatives:** GPT-4o-mini / Claude Haiku (summaries: more expensive or slower), OpenAI embeddings (higher dimension = extra storage/latency with no proven gain here).
**Consequences:** two AI providers → two keys to protect; summary fallback to define (see AI Architecture §4); embeddings locked to 768-d (migration = full re-embedding, cost accepted).

**Revision 2026-09-18 (first real test):** all three models from the original decision returned 404 — `llama-3.3-70b-versatile` pulled by Groq, `gemini-2.5-flash` "no longer available to new users", `text-embedding-004` removed. Verified live on each provider's `GET /models` and replaced, without changing the architecture: Groq **`openai/gpt-oss-120b`** (summary in 1.2 s; reasoning model → `reasoning_effort: low` and output margin), Gemini fallback **`gemini-flash-lite-latest`** (1.3 s; `gemini-3.6-flash`, recommended by Google, was 503 "high demand"), embeddings **`gemini-embedding-001`** truncated to 768-d and **normalised** in the embedder (Google only normalises native 3072-d output). Names live in `wrangler.toml`; `api/scripts/try-pipeline.ts <url>` replays the real pipeline locally. Lesson: a hosted model has a lifespan of a few months — verify all three before every demo.
