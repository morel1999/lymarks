# Database Schema — Lymarks (Neon Postgres)

> **But :** tables, relations, index, migrations. · **Statut :** vivant · **Màj :** 2026-09-18

Outil de migrations : **SQL brut, fichiers numérotés dans `api/migrations/`, joués par `api/scripts/migrate.ts`** (ADR-009 ; Drizzle écarté). Le SQL ci-dessous est celui de `api/migrations/001_initial.sql`, la source de vérité. Écarts par rapport à la première version : `bookmarks.failure_reason` et `updated_at`, index `bookmarks_url_hash` (cache de résumés inter-utilisateurs), `subscriptions.last_event_id` / `last_event_at` (idempotence du webhook, M7), table `schema_migrations`.

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE users (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_id     text UNIQUE NOT NULL,
  tz           text NOT NULL DEFAULT 'Europe/Istanbul',
  digest_hour  smallint NOT NULL DEFAULT 8,     -- heure locale
  digest_optin boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TYPE bookmark_status AS ENUM ('processing','ready','partial','failed');
CREATE TYPE bookmark_source AS ENUM ('x','youtube','linkedin','web');

CREATE TABLE bookmarks (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  url           text NOT NULL,
  url_hash      text NOT NULL,                  -- sha256(url normalisée)
  source        bookmark_source NOT NULL DEFAULT 'web',
  title         text,
  note          text,                           -- jamais envoyée aux LLM
  summary       jsonb,                           -- {bullets:[3], lang}
  keywords      text[] NOT NULL DEFAULT '{}',
  embedding     vector(768),
  status        bookmark_status NOT NULL DEFAULT 'processing',
  failure_reason text,                          -- code court, affiché à l'utilisateur
  summary_version int NOT NULL DEFAULT 1,
  saved_count   int NOT NULL DEFAULT 1,
  archived      boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  last_opened_at   timestamptz,
  last_surfaced_at timestamptz,
  UNIQUE (user_id, url_hash)                    -- anti-doublon + idempotence
);
CREATE INDEX bookmarks_user_created ON bookmarks (user_id, created_at DESC);
CREATE INDEX bookmarks_url_hash ON bookmarks (url_hash);
CREATE INDEX bookmarks_embedding_hnsw ON bookmarks
  USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64);
CREATE INDEX bookmarks_fts ON bookmarks USING gin (
  to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(note,'') || ' ' ||
              coalesce(summary->>'bullets','') || ' ' || array_to_string(keywords,' ')));

CREATE TABLE subscriptions (
  user_id      uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  rc_app_user_id text NOT NULL,
  entitlement  text NOT NULL DEFAULT 'free',    -- 'free' | 'pro'
  expires_at   timestamptz,
  last_event_id text,                           -- idempotence du webhook (M7)
  last_event_at timestamptz,                    -- rejet des événements dans le désordre
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE digests (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bookmark_id  uuid NOT NULL REFERENCES bookmarks(id) ON DELETE CASCADE,
  sent_at      timestamptz NOT NULL DEFAULT now(),
  action       text                              -- 'opened'|'snoozed'|'archived'|null
);
CREATE INDEX digests_user_sent ON digests (user_id, sent_at DESC);

CREATE TABLE push_tokens (
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token      text NOT NULL,
  platform   text NOT NULL,                      -- 'ios'|'android'
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, token)
);
```

## Règles
- **Toute requête applicative filtre par `user_id`** (issu du JWT). Test d'intégration M6 dédié.
- `ON DELETE CASCADE` partout → la suppression de compte = `DELETE FROM users` (Privacy §5).
- Migrations : numérotées, jouées par la CI (`npm run migrate`, transaction par fichier, journal `schema_migrations`) ; jamais de `DROP` sans migration de repli notée.
- Tout accès passe par le contrat `Db` (`api/src/db/types.ts`) : une implémentation Neon, une en mémoire pour les tests (ADR-009).
- Compte des lymarks Free : `SELECT count(*) WHERE user_id=$1 AND archived=false` — pas de compteur dénormalisé en V1.
