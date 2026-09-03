# ADR-004 — Neon Postgres + pgvector
**Statut :** accepté · 2026-08-07
**Contexte :** stocker bookmarks, résumés et embeddings ; recherche par similarité cosinus ; env dev/prod séparés sans coût fixe.
**Décision :** Neon (serverless, Database Branching) avec l'extension pgvector (index HNSW).
**Alternatives :** Supabase (très proche ; Neon retenu pour le branching), Pinecone/Qdrant (une 2ᵉ base à opérer pour 768 d × quelques milliers de lignes : injustifié), SQLite/D1 (pas de pgvector mature).
**Conséquences :** un seul store pour données + vecteurs ; SQL standard ; latence Neon depuis l'edge à mesurer (driver HTTP `@neondatabase/serverless`).
