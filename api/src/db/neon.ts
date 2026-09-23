// Implémentation Neon (pilote HTTP serverless) du contrat `Db`.
//
// SQL brut plutôt qu'un ORM (ADR-009) : le schéma est déjà écrit en SQL dans la
// doc, et pgvector (`<=>`) comme la recherche plein texte se manipulent
// mieux à la main. Chaque requête sur une ressource utilisateur contient
// `user_id = ${userId}` — c'est la règle absolue du Database Schema.

import { neon } from "@neondatabase/serverless";
import { fusedScore, SEMANTIC_WEIGHT, TEXT_WEIGHT, toTsQuery } from "../services/search.js";
import type {
  BookmarkPatch,
  BookmarkRow,
  CachedSummary,
  Db,
  ListOptions,
  NewBookmark,
  PipelineResult,
  Plan,
  SearchHit,
  SubscriptionEvent,
  Summary,
  UserRow,
  UserSettingsPatch,
} from "./types.js";

type Sql = ReturnType<typeof neon>;
type Row = Record<string, unknown>;

const BOOKMARK_COLUMNS = `id, user_id, url, url_hash, source, title, note, summary, keywords,
  category, image_url, status, failure_reason, summary_version, saved_count, archived,
  locked, created_at, updated_at, last_opened_at, last_surfaced_at`;

// `fts` est une colonne générée (migration 001) : le document plein texte est
// maintenu par Postgres et indexé en GIN, sans répéter l'expression ici.

function asDate(v: unknown): Date {
  return v instanceof Date ? v : new Date(String(v));
}
function asDateOrNull(v: unknown): Date | null {
  return v === null || v === undefined ? null : asDate(v);
}
function parseVector(v: unknown): number[] | null {
  if (v === null || v === undefined) return null;
  if (Array.isArray(v)) return v as number[];
  try {
    return JSON.parse(String(v)) as number[];
  } catch {
    return null;
  }
}

function toUser(r: Row): UserRow {
  return {
    id: String(r["id"]),
    clerkId: String(r["clerk_id"]),
    tz: String(r["tz"]),
    digestHour: Number(r["digest_hour"]),
    digestOptin: Boolean(r["digest_optin"]),
    avatar: (r["avatar"] as string | null) ?? null,
    createdAt: asDate(r["created_at"]),
  };
}

function toBookmark(r: Row): BookmarkRow {
  const row: BookmarkRow = {
    id: String(r["id"]),
    userId: String(r["user_id"]),
    url: String(r["url"]),
    urlHash: String(r["url_hash"]),
    source: r["source"] as BookmarkRow["source"],
    title: (r["title"] as string | null) ?? null,
    note: (r["note"] as string | null) ?? null,
    summary: (r["summary"] as Summary | null) ?? null,
    keywords: (r["keywords"] as string[] | null) ?? [],
    category: String(r["category"] ?? "other"),
    imageUrl: (r["image_url"] as string | null) ?? null,
    status: r["status"] as BookmarkRow["status"],
    failureReason: (r["failure_reason"] as string | null) ?? null,
    summaryVersion: Number(r["summary_version"]),
    savedCount: Number(r["saved_count"]),
    archived: Boolean(r["archived"]),
    locked: Boolean(r["locked"]),
    createdAt: asDate(r["created_at"]),
    updatedAt: asDate(r["updated_at"]),
    lastOpenedAt: asDateOrNull(r["last_opened_at"]),
    lastSurfacedAt: asDateOrNull(r["last_surfaced_at"]),
  };
  if ("embedding" in r) row.embedding = parseVector(r["embedding"]);
  return row;
}

export function createNeonDb(databaseUrl: string): Db {
  const sql: Sql = neon(databaseUrl);
  const q = (text: string, params: unknown[] = []): Promise<Row[]> =>
    sql.query(text, params) as Promise<Row[]>;

  return {
    async ping() {
      await q("SELECT 1");
    },

    users: {
      async findByClerkId(clerkId) {
        const rows = await q("SELECT * FROM users WHERE clerk_id = $1", [clerkId]);
        return rows[0] ? toUser(rows[0]) : null;
      },
      async create(clerkId) {
        const rows = await q(
          `INSERT INTO users (clerk_id) VALUES ($1)
           ON CONFLICT (clerk_id) DO UPDATE SET clerk_id = EXCLUDED.clerk_id
           RETURNING *`,
          [clerkId],
        );
        return toUser(rows[0]!);
      },
      async get(userId) {
        const rows = await q("SELECT * FROM users WHERE id = $1", [userId]);
        return rows[0] ? toUser(rows[0]) : null;
      },
      async updateSettings(userId, patch: UserSettingsPatch) {
        const rows = await q(
          `UPDATE users SET
             tz = coalesce($2, tz),
             digest_hour = coalesce($3, digest_hour),
             digest_optin = coalesce($4, digest_optin)
           WHERE id = $1 RETURNING *`,
          [userId, patch.tz ?? null, patch.digestHour ?? null, patch.digestOptin ?? null],
        );
        return rows[0] ? toUser(rows[0]) : null;
      },
      async setAvatar(userId, avatar) {
        const rows = await q("UPDATE users SET avatar = $2 WHERE id = $1 RETURNING *", [
          userId,
          avatar,
        ]);
        return rows[0] ? toUser(rows[0]) : null;
      },
      async delete(userId) {
        await q("DELETE FROM users WHERE id = $1", [userId]);
      },
    },

    bookmarks: {
      async insert(userId, data: NewBookmark) {
        const rows = await q(
          `INSERT INTO bookmarks (user_id, url, url_hash, source, title, note, locked)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           RETURNING ${BOOKMARK_COLUMNS}`,
          [
            userId,
            data.url,
            data.urlHash,
            data.source,
            data.title,
            data.note,
            data.locked ?? false,
          ],
        );
        return toBookmark(rows[0]!);
      },
      async countLocked(userId) {
        const rows = await q(
          `SELECT count(*)::int AS n FROM bookmarks WHERE user_id = $1 AND locked`,
          [userId],
        );
        return Number(rows[0]?.["n"] ?? 0);
      },
      async unlockAll(userId) {
        // Les lignes liberees n'ont jamais traverse le pipeline : l'appelant
        // les y envoie, c'est le seul moment ou on paie les modeles.
        const rows = await q(
          `UPDATE bookmarks SET locked = false, updated_at = now()
           WHERE user_id = $1 AND locked
           RETURNING ${BOOKMARK_COLUMNS}`,
          [userId],
        );
        return rows.map(toBookmark);
      },
      async findByHash(userId, urlHash) {
        const rows = await q(
          `SELECT ${BOOKMARK_COLUMNS} FROM bookmarks WHERE user_id = $1 AND url_hash = $2`,
          [userId, urlHash],
        );
        return rows[0] ? toBookmark(rows[0]) : null;
      },
      async bumpDuplicate(userId, urlHash, note) {
        const rows = await q(
          `UPDATE bookmarks SET
             saved_count = saved_count + 1,
             note = coalesce($3, note),
             archived = false,
             updated_at = now()
           WHERE user_id = $1 AND url_hash = $2
           RETURNING ${BOOKMARK_COLUMNS}`,
          [userId, urlHash, note],
        );
        return rows[0] ? toBookmark(rows[0]) : null;
      },
      async list(userId, opts: ListOptions) {
        const rows = await q(
          `SELECT ${BOOKMARK_COLUMNS} FROM bookmarks
           WHERE user_id = $1
             AND ($2::timestamptz IS NULL OR created_at < $2)
             AND ($3::boolean IS NULL OR archived = $3)
             AND ($4::bookmark_status IS NULL OR status = $4)
           ORDER BY created_at DESC, id DESC
           LIMIT $5`,
          [userId, opts.before ?? null, opts.archived ?? null, opts.status ?? null, opts.limit],
        );
        return rows.map(toBookmark);
      },
      async get(userId, id) {
        const rows = await q(
          `SELECT ${BOOKMARK_COLUMNS}, embedding::text AS embedding
           FROM bookmarks WHERE user_id = $1 AND id = $2`,
          [userId, id],
        );
        return rows[0] ? toBookmark(rows[0]) : null;
      },
      async update(userId, id, patch: BookmarkPatch) {
        const rows = await q(
          `UPDATE bookmarks SET
             note = CASE WHEN $3::boolean THEN $4 ELSE note END,
             archived = coalesce($5, archived),
             updated_at = now()
           WHERE user_id = $1 AND id = $2
           RETURNING ${BOOKMARK_COLUMNS}`,
          [userId, id, "note" in patch, patch.note ?? null, patch.archived ?? null],
        );
        return rows[0] ? toBookmark(rows[0]) : null;
      },
      async delete(userId, id) {
        const rows = await q("DELETE FROM bookmarks WHERE user_id = $1 AND id = $2 RETURNING id", [
          userId,
          id,
        ]);
        return rows.length > 0;
      },
      async markOpened(userId, id, at) {
        const rows = await q(
          "UPDATE bookmarks SET last_opened_at = $3 WHERE user_id = $1 AND id = $2 RETURNING id",
          [userId, id, at],
        );
        return rows.length > 0;
      },
      async countActive(userId) {
        // Les verrouilles ne comptent pas : la limite Free porte sur ce qui
        // est accessible. Les compter reviendrait a bloquer a jamais l'ajout
        // de nouveaux liens lisibles, meme apres avoir archive.
        const rows = await q(
          `SELECT count(*)::int AS n FROM bookmarks
           WHERE user_id = $1 AND archived = false AND locked = false`,
          [userId],
        );
        return Number(rows[0]?.["n"] ?? 0);
      },
      async countCreatedSince(userId, since) {
        const rows = await q(
          "SELECT count(*)::int AS n FROM bookmarks WHERE user_id = $1 AND created_at >= $2",
          [userId, since],
        );
        return Number(rows[0]?.["n"] ?? 0);
      },
      async resetForRetry(userId, id, stalledBefore) {
        const rows = await q(
          `UPDATE bookmarks SET status = 'processing', failure_reason = NULL, updated_at = now()
           WHERE user_id = $1 AND id = $2
             AND (status IN ('failed', 'partial')
                  OR (status = 'processing' AND updated_at < $3))
           RETURNING ${BOOKMARK_COLUMNS}`,
          [userId, id, stalledBefore],
        );
        return rows[0] ? toBookmark(rows[0]) : null;
      },
      async setResult(id, result: PipelineResult) {
        await q(
          `UPDATE bookmarks SET
             status = $2,
             title = coalesce($3, title),
             summary = $4::jsonb,
             keywords = $5::text[],
             embedding = $6::vector,
             failure_reason = $7,
             category = $8,
             image_url = $9,
             summary_version = CASE WHEN status = 'processing' AND summary IS NOT NULL
                                    THEN summary_version + 1 ELSE summary_version END,
             updated_at = now()
           WHERE id = $1`,
          [
            id,
            result.status,
            result.title,
            result.summary ? JSON.stringify(result.summary) : null,
            result.keywords,
            result.embedding ? JSON.stringify(result.embedding) : null,
            result.failureReason,
            result.category,
            result.imageUrl,
          ],
        );
      },
      async findCachedSummary(urlHash): Promise<CachedSummary | null> {
        const rows = await q(
          `SELECT title, summary, keywords, category, image_url, embedding::text AS embedding
           FROM bookmarks
           WHERE url_hash = $1 AND status = 'ready' AND summary IS NOT NULL
           ORDER BY updated_at DESC LIMIT 1`,
          [urlHash],
        );
        const r = rows[0];
        if (!r) return null;
        return {
          title: (r["title"] as string | null) ?? null,
          summary: r["summary"] as Summary,
          keywords: (r["keywords"] as string[] | null) ?? [],
          category: String(r["category"] ?? "other"),
          imageUrl: (r["image_url"] as string | null) ?? null,
          embedding: parseVector(r["embedding"]),
        };
      },
      async searchText(userId, query, limit): Promise<SearchHit[]> {
        const ts = toTsQuery(query);
        if (!ts) return [];
        const rows = await q(
          `SELECT ${BOOKMARK_COLUMNS}, ts_rank(fts, to_tsquery('simple', $2), 32) AS score
           FROM bookmarks
           WHERE user_id = $1 AND archived = false AND fts @@ to_tsquery('simple', $2)
           ORDER BY score DESC, created_at DESC
           LIMIT $3`,
          [userId, ts, limit],
        );
        return rows.map((r) => ({ bookmark: toBookmark(r), score: Number(r["score"]) }));
      },
      async searchHybrid(userId, query, embedding, limit): Promise<SearchHit[]> {
        const ts = toTsQuery(query);
        // Fusion 0,7 sémantique / 0,3 texte (Knowledge Vault §5), calculée en
        // sous-requête pour ordonner sur le score composé.
        const rows = await q(
          `SELECT * FROM (
             SELECT ${BOOKMARK_COLUMNS},
                    greatest(0, 1 - (embedding <=> $3::vector)) AS semantic,
                    CASE WHEN $2::text IS NULL THEN 0
                         ELSE ts_rank(fts, to_tsquery('simple', $2), 32) END AS text
             FROM bookmarks
             WHERE user_id = $1 AND archived = false AND embedding IS NOT NULL
           ) scored
           ORDER BY (${SEMANTIC_WEIGHT} * semantic + ${TEXT_WEIGHT} * text) DESC, created_at DESC
           LIMIT $4`,
          [userId, ts, JSON.stringify(embedding), limit],
        );
        return rows.map((r) => ({
          bookmark: toBookmark(r),
          score: fusedScore(Number(r["semantic"]), Number(r["text"])),
        }));
      },
      async similar(userId, id, limit, minScore): Promise<SearchHit[]> {
        const rows = await q(
          `SELECT ${BOOKMARK_COLUMNS}, 1 - (b.embedding <=> ref.embedding) AS score
           FROM bookmarks b,
                (SELECT embedding FROM bookmarks WHERE user_id = $1 AND id = $2 AND embedding IS NOT NULL) ref
           WHERE b.user_id = $1 AND b.id <> $2 AND b.archived = false AND b.embedding IS NOT NULL
             AND 1 - (b.embedding <=> ref.embedding) >= $4
           ORDER BY score DESC LIMIT $3`,
          [userId, id, limit, minScore],
        );
        return rows.map((r) => ({ bookmark: toBookmark(r), score: Number(r["score"]) }));
      },
      async exportAll(userId) {
        const rows = await q(
          `SELECT ${BOOKMARK_COLUMNS} FROM bookmarks WHERE user_id = $1 ORDER BY created_at DESC`,
          [userId],
        );
        return rows.map(toBookmark);
      },
    },

    subscriptions: {
      async getPlan(userId): Promise<Plan> {
        const rows = await q(
          `SELECT entitlement FROM subscriptions
           WHERE user_id = $1 AND (expires_at IS NULL OR expires_at > now())`,
          [userId],
        );
        return rows[0]?.["entitlement"] === "pro" ? "pro" : "free";
      },
      async applyEvent(clerkId, event: SubscriptionEvent) {
        const users = await q("SELECT id FROM users WHERE clerk_id = $1", [clerkId]);
        const userId = users[0]?.["id"];
        if (!userId) return "unknown_user";
        const rows = await q(
          `INSERT INTO subscriptions (user_id, rc_app_user_id, entitlement, expires_at, last_event_id, last_event_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, now())
           ON CONFLICT (user_id) DO UPDATE SET
             rc_app_user_id = EXCLUDED.rc_app_user_id,
             entitlement = EXCLUDED.entitlement,
             expires_at = EXCLUDED.expires_at,
             last_event_id = EXCLUDED.last_event_id,
             last_event_at = EXCLUDED.last_event_at,
             updated_at = now()
           WHERE subscriptions.last_event_id IS DISTINCT FROM EXCLUDED.last_event_id
             AND (subscriptions.last_event_at IS NULL OR subscriptions.last_event_at <= EXCLUDED.last_event_at)
           RETURNING user_id`,
          [
            userId,
            event.rcAppUserId,
            event.entitlement,
            event.expiresAt,
            event.eventId,
            event.occurredAt,
          ],
        );
        return rows.length > 0 ? "applied" : "ignored";
      },
    },
  };
}
