// Dépôt en mémoire, même contrat que Neon. Sert aux tests de routes et de
// pipeline sans base : il reproduit les règles métier des requêtes SQL
// (filtrage par user_id, doublon, cache par hash, fusion de scores).

import type {
  BookmarkRow,
  CachedSummary,
  Db,
  SearchHit,
  Summary,
  SubscriptionEvent,
  UserRow,
} from "../../src/db/types.js";
import { cosineSimilarity, fusedScore, textRank } from "../../src/services/search.js";

interface SubscriptionRow {
  userId: string;
  rcAppUserId: string;
  entitlement: "free" | "pro";
  expiresAt: Date | null;
  lastEventId: string | null;
  lastEventAt: Date | null;
}

export class MemoryDb implements Db {
  users_ = new Map<string, UserRow>();
  bookmarks_ = new Map<string, BookmarkRow & { embedding: number[] | null }>();
  subscriptions_ = new Map<string, SubscriptionRow>();
  now: () => Date = () => new Date();
  private tick = 0;

  /** Horodatage strictement croissant pour un tri stable. */
  private stamp(): Date {
    this.tick += 1;
    return new Date(this.now().getTime() + this.tick);
  }

  private haystack(b: BookmarkRow): string {
    return [b.title, b.note, ...(b.summary?.bullets ?? []), ...b.keywords]
      .filter(Boolean)
      .join(" ");
  }

  async ping(): Promise<void> {}

  users = {
    findByClerkId: async (clerkId: string): Promise<UserRow | null> =>
      [...this.users_.values()].find((u) => u.clerkId === clerkId) ?? null,
    create: async (clerkId: string): Promise<UserRow> => {
      const existing = await this.users.findByClerkId(clerkId);
      if (existing) return existing;
      const user: UserRow = {
        id: crypto.randomUUID(),
        clerkId,
        tz: "Europe/Istanbul",
        digestHour: 8,
        digestOptin: false,
        createdAt: this.stamp(),
      };
      this.users_.set(user.id, user);
      return user;
    },
    get: async (userId: string): Promise<UserRow | null> => this.users_.get(userId) ?? null,
    updateSettings: async (
      userId: string,
      patch: {
        tz?: string | undefined;
        digestHour?: number | undefined;
        digestOptin?: boolean | undefined;
      },
    ) => {
      const u = this.users_.get(userId);
      if (!u) return null;
      const next: UserRow = {
        ...u,
        tz: patch.tz ?? u.tz,
        digestHour: patch.digestHour ?? u.digestHour,
        digestOptin: patch.digestOptin ?? u.digestOptin,
      };
      this.users_.set(userId, next);
      return next;
    },
    delete: async (userId: string): Promise<void> => {
      this.users_.delete(userId);
      for (const [id, b] of this.bookmarks_) if (b.userId === userId) this.bookmarks_.delete(id);
      this.subscriptions_.delete(userId);
    },
  };

  bookmarks = {
    insert: async (
      userId: string,
      data: {
        url: string;
        urlHash: string;
        source: BookmarkRow["source"];
        title: string | null;
        note: string | null;
      },
    ) => {
      if (await this.bookmarks.findByHash(userId, data.urlHash))
        throw new Error("duplicate key (user_id, url_hash)");
      const at = this.stamp();
      const row: BookmarkRow & { embedding: number[] | null } = {
        id: crypto.randomUUID(),
        userId,
        url: data.url,
        urlHash: data.urlHash,
        source: data.source,
        title: data.title,
        note: data.note,
        summary: null,
        keywords: [],
        status: "processing",
        failureReason: null,
        summaryVersion: 1,
        savedCount: 1,
        archived: false,
        createdAt: at,
        updatedAt: at,
        lastOpenedAt: null,
        lastSurfacedAt: null,
        embedding: null,
      };
      this.bookmarks_.set(row.id, row);
      return this.strip(row);
    },
    findByHash: async (userId: string, urlHash: string) => {
      const row = [...this.bookmarks_.values()].find(
        (b) => b.userId === userId && b.urlHash === urlHash,
      );
      return row ? this.strip(row) : null;
    },
    bumpDuplicate: async (userId: string, urlHash: string, note: string | null) => {
      const row = [...this.bookmarks_.values()].find(
        (b) => b.userId === userId && b.urlHash === urlHash,
      );
      if (!row) return null;
      row.savedCount += 1;
      row.note = note ?? row.note;
      row.archived = false;
      row.updatedAt = this.stamp();
      return this.strip(row);
    },
    list: async (
      userId: string,
      opts: { limit: number; before?: Date; archived?: boolean; status?: BookmarkRow["status"] },
    ) =>
      [...this.bookmarks_.values()]
        .filter((b) => b.userId === userId)
        .filter((b) => !opts.before || b.createdAt < opts.before)
        .filter((b) => opts.archived === undefined || b.archived === opts.archived)
        .filter((b) => !opts.status || b.status === opts.status)
        .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
        .slice(0, opts.limit)
        .map((b) => this.strip(b)),
    get: async (userId: string, id: string) => {
      const row = this.bookmarks_.get(id);
      return row && row.userId === userId ? { ...row, embedding: row.embedding } : null;
    },
    update: async (
      userId: string,
      id: string,
      patch: { note?: string | null | undefined; archived?: boolean | undefined },
    ) => {
      const row = this.bookmarks_.get(id);
      if (!row || row.userId !== userId) return null;
      if ("note" in patch) row.note = patch.note ?? null;
      if (patch.archived !== undefined) row.archived = patch.archived;
      row.updatedAt = this.stamp();
      return this.strip(row);
    },
    delete: async (userId: string, id: string) => {
      const row = this.bookmarks_.get(id);
      if (!row || row.userId !== userId) return false;
      this.bookmarks_.delete(id);
      return true;
    },
    markOpened: async (userId: string, id: string, at: Date) => {
      const row = this.bookmarks_.get(id);
      if (!row || row.userId !== userId) return false;
      row.lastOpenedAt = at;
      return true;
    },
    countActive: async (userId: string) =>
      [...this.bookmarks_.values()].filter((b) => b.userId === userId && !b.archived).length,
    countCreatedSince: async (userId: string, since: Date) =>
      [...this.bookmarks_.values()].filter((b) => b.userId === userId && b.createdAt >= since)
        .length,
    resetForRetry: async (userId: string, id: string, stalledBefore: Date) => {
      const row = this.bookmarks_.get(id);
      if (!row || row.userId !== userId) return null;
      const retryable =
        row.status === "failed" ||
        row.status === "partial" ||
        (row.status === "processing" && row.updatedAt < stalledBefore);
      if (!retryable) return null;
      row.status = "processing";
      row.failureReason = null;
      row.updatedAt = this.stamp();
      return this.strip(row);
    },
    setResult: async (
      id: string,
      result: {
        status: BookmarkRow["status"];
        title: string | null;
        summary: Summary | null;
        keywords: string[];
        embedding: number[] | null;
        failureReason: string | null;
      },
    ) => {
      const row = this.bookmarks_.get(id);
      if (!row) return;
      if (row.status === "processing" && row.summary) row.summaryVersion += 1;
      row.status = result.status;
      row.title = result.title ?? row.title;
      row.summary = result.summary;
      row.keywords = result.keywords;
      row.embedding = result.embedding;
      row.failureReason = result.failureReason;
      row.updatedAt = this.stamp();
    },
    findCachedSummary: async (urlHash: string): Promise<CachedSummary | null> => {
      const row = [...this.bookmarks_.values()]
        .filter((b) => b.urlHash === urlHash && b.status === "ready" && b.summary)
        .sort((a, b) => b.updatedAt.getTime() - a.updatedAt.getTime())[0];
      if (!row) return null;
      return {
        title: row.title,
        summary: row.summary!,
        keywords: row.keywords,
        embedding: row.embedding,
      };
    },
    searchText: async (userId: string, query: string, limit: number): Promise<SearchHit[]> =>
      [...this.bookmarks_.values()]
        .filter((b) => b.userId === userId && !b.archived)
        .map((b) => ({ bookmark: this.strip(b), score: textRank(this.haystack(b), query) }))
        .filter((h) => h.score > 0)
        .sort(
          (a, b) =>
            b.score - a.score || b.bookmark.createdAt.getTime() - a.bookmark.createdAt.getTime(),
        )
        .slice(0, limit),
    searchHybrid: async (
      userId: string,
      query: string,
      embedding: number[],
      limit: number,
    ): Promise<SearchHit[]> =>
      [...this.bookmarks_.values()]
        .filter((b) => b.userId === userId && !b.archived && b.embedding)
        .map((b) => ({
          bookmark: this.strip(b),
          score: fusedScore(
            cosineSimilarity(b.embedding!, embedding),
            textRank(this.haystack(b), query),
          ),
        }))
        .sort((a, b) => b.score - a.score)
        .slice(0, limit),
    similar: async (
      userId: string,
      id: string,
      limit: number,
      minScore: number,
    ): Promise<SearchHit[]> => {
      const ref = this.bookmarks_.get(id);
      if (!ref || ref.userId !== userId || !ref.embedding) return [];
      return [...this.bookmarks_.values()]
        .filter((b) => b.userId === userId && b.id !== id && !b.archived && b.embedding)
        .map((b) => ({
          bookmark: this.strip(b),
          score: cosineSimilarity(b.embedding!, ref.embedding!),
        }))
        .filter((h) => h.score >= minScore)
        .sort((a, b) => b.score - a.score)
        .slice(0, limit);
    },
    exportAll: async (userId: string) =>
      [...this.bookmarks_.values()]
        .filter((b) => b.userId === userId)
        .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
        .map((b) => this.strip(b)),
  };

  subscriptions = {
    getPlan: async (userId: string): Promise<"free" | "pro"> => {
      const s = this.subscriptions_.get(userId);
      if (!s) return "free";
      if (s.expiresAt && s.expiresAt <= this.now()) return "free";
      return s.entitlement;
    },
    applyEvent: async (
      clerkId: string,
      event: SubscriptionEvent,
    ): Promise<"applied" | "ignored" | "unknown_user"> => {
      const user = await this.users.findByClerkId(clerkId);
      if (!user) return "unknown_user";
      const current = this.subscriptions_.get(user.id);
      if (
        current &&
        (current.lastEventId === event.eventId ||
          (current.lastEventAt && current.lastEventAt > event.occurredAt))
      ) {
        return "ignored";
      }
      this.subscriptions_.set(user.id, {
        userId: user.id,
        rcAppUserId: event.rcAppUserId,
        entitlement: event.entitlement,
        expiresAt: event.expiresAt,
        lastEventId: event.eventId,
        lastEventAt: event.occurredAt,
      });
      return "applied";
    },
  };

  /** Copie sans embedding, comme les lectures de liste SQL. */
  private strip(row: BookmarkRow & { embedding: number[] | null }): BookmarkRow {
    const { embedding: _embedding, ...rest } = row;
    return {
      ...rest,
      keywords: [...rest.keywords],
      summary: rest.summary ? { ...rest.summary, bullets: [...rest.summary.bullets] } : null,
    };
  }
}
