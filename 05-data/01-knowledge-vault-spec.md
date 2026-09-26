# Knowledge Vault Specification — Lymarks

> **Purpose:** the knowledge memory: structure, indexing, re-surfacing. · **Status:** living · **Updated:** 2026-08-07

## 1. Unit of knowledge: the lymark
```
lymark = {
  url, url_hash, source,           // source ∈ {x, youtube, linkedin, web}
  title, user_note,
  summary: [bullet1, bullet2, bullet3],  // generated, in content language
  keywords: [..],                        // 3–6, generated
  embedding: vector(768),                // on title + bullets
  status, saved_count,
  created_at, last_opened_at, last_surfaced_at
}
```
The **user note** is the intent ("for my weekend project"): it weighs in the full-text search but is never sent to LLMs (Privacy §2).

## 2. Tags
V1.0: generated `keywords` = de facto tags (displayed as chips, clickable → search). Editable manual tags: V1.2. No folders, ever (philosophy: filing is the machine's job).

## 3. Relations and graph
V1.0: implicit relations only — "similar lymarks" = top-3 by cosine (>0.75) displayed on the detail card. Explicit graph: out of scope (⚠️ reassess in V2 if real usage demands it).

## 4. Re-surfacing (Daily Digest algorithm)
Candidates: `ready` lymarks, not opened for ≥7 days, not surfaced for ≥14 days, not archived.
```
score = 0.5 × relevance + 0.3 × forgetting + 0.2 × interest_freshness
  relevance         = cos(embedding, centroid of the last 10 saved lymarks)
  forgetting        = min(days_since_save / 30, 1)      // inspired by spaced repetition
  interest_freshness = 1 if keywords ∩ recent_keywords ≠ ∅, else 0.3
```
Selection = highest score; tie → oldest. "Snooze" → excluded for 7 days. "Archive" → excluded permanently. Weights ⚠️ to calibrate after 2 weeks of real data.

## 5. Search and indexing
- Full-text: Postgres `tsvector` on (title, note, bullets, keywords), `simple` config (multilingual FR/EN ⚠️ to validate).
- Semantic: pgvector, cosine distance, **HNSW** index (`m=16, ef_construction=64`) — created from migration 001 (zero cost at small scale, avoids a re-index).
- Pro fusion: `score = 0.7 × semantic + 0.3 × text` (⚠️ to calibrate, see SAD Flow 2).

## 6. Versioning and synchronisation
The server is the source of truth (automatic multi-device sync). Note update: last write wins (V1); offline conflict resolution: P2 (PRD). Re-summarising a lymark: replaces bullets+keywords+embedding, `summary_version += 1`.
