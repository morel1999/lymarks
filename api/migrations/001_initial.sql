-- Migration 001 — schéma initial (05-data/02-database-schema.md).
-- Jouée par `npm run migrate` (scripts/migrate.ts), idempotente par construction
-- (IF NOT EXISTS partout) et journalisée dans schema_migrations.

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS users (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_id     text UNIQUE NOT NULL,
  tz           text NOT NULL DEFAULT 'Europe/Istanbul',
  digest_hour  smallint NOT NULL DEFAULT 8,     -- heure locale
  digest_optin boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now()
);

DO $$ BEGIN
  CREATE TYPE bookmark_status AS ENUM ('processing','ready','partial','failed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE bookmark_source AS ENUM ('x','youtube','linkedin','web');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- array_to_string() est STABLE, donc interdit dans un index ou une colonne
-- générée ; ce wrapper strict (résultat identique) est déclaré IMMUTABLE.
CREATE OR REPLACE FUNCTION keywords_text(text[]) RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
  AS $$ SELECT array_to_string($1, ' ') $$;

CREATE TABLE IF NOT EXISTS bookmarks (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  url           text NOT NULL,
  url_hash      text NOT NULL,                  -- sha256(url normalisée)
  source        bookmark_source NOT NULL DEFAULT 'web',
  title         text,
  note          text,                           -- jamais envoyée aux LLM
  summary       jsonb,                          -- {bullets:[≤3], lang}
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
  -- Document plein texte (titre, note, puces, mots-clés), maintenu par Postgres.
  fts tsvector GENERATED ALWAYS AS (
    to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(note,'') || ' ' ||
                coalesce(summary->>'bullets','') || ' ' || keywords_text(keywords))
  ) STORED,
  UNIQUE (user_id, url_hash)                    -- anti-doublon + idempotence
);
CREATE INDEX IF NOT EXISTS bookmarks_user_created ON bookmarks (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS bookmarks_url_hash ON bookmarks (url_hash);
CREATE INDEX IF NOT EXISTS bookmarks_embedding_hnsw ON bookmarks
  USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64);
CREATE INDEX IF NOT EXISTS bookmarks_fts ON bookmarks USING gin (fts);

CREATE TABLE IF NOT EXISTS subscriptions (
  user_id        uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  rc_app_user_id text NOT NULL,
  entitlement    text NOT NULL DEFAULT 'free',  -- 'free' | 'pro'
  expires_at     timestamptz,
  last_event_id  text,                          -- idempotence du webhook (Threat Model M7)
  last_event_at  timestamptz,                   -- rejet des événements arrivés dans le désordre
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS digests (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bookmark_id  uuid NOT NULL REFERENCES bookmarks(id) ON DELETE CASCADE,
  sent_at      timestamptz NOT NULL DEFAULT now(),
  action       text                             -- 'opened'|'snoozed'|'archived'|null
);
CREATE INDEX IF NOT EXISTS digests_user_sent ON digests (user_id, sent_at DESC);

CREATE TABLE IF NOT EXISTS push_tokens (
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token      text NOT NULL,
  platform   text NOT NULL,                     -- 'ios'|'android'
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, token)
);
