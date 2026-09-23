// Types des lignes SQL et du contrat de dépôt (repository).
//
// Le contrat `Db` est la seule frontière entre les routes et Postgres :
// aucune requête SQL hors de src/db/ (Coding Standards §3), et toute méthode
// qui touche une ressource utilisateur reçoit `userId` explicitement — c'est
// la garantie anti-IDOR (Threat Model M6).

import type { Category } from "../services/categories.js";

export type BookmarkStatus = "processing" | "ready" | "partial" | "failed";
export type BookmarkSource = "x" | "youtube" | "linkedin" | "web";
export type Plan = "free" | "pro";

export interface UserRow {
  id: string;
  clerkId: string;
  tz: string;
  digestHour: number;
  digestOptin: boolean;
  /** Emoji (séquences comprises) ou null ; jamais un fichier. */
  avatar: string | null;
  createdAt: Date;
}

export interface Summary {
  bullets: string[];
  lang: string | null;
}

export interface BookmarkRow {
  id: string;
  userId: string;
  url: string;
  urlHash: string;
  source: BookmarkSource;
  title: string | null;
  note: string | null;
  summary: Summary | null;
  keywords: string[];
  /** Entrée de la taxonomie fermée (services/categories.ts) ; `other` tant que rien n'est résumé. */
  category: string;
  /** Aperçu og:image en https absolu, ou null. */
  imageUrl: string | null;
  status: BookmarkStatus;
  failureReason: string | null;
  summaryVersion: number;
  savedCount: number;
  archived: boolean;
  /** Au-dela de la limite Free : enregistre, mais inaccessible. */
  locked: boolean;
  createdAt: Date;
  updatedAt: Date;
  lastOpenedAt: Date | null;
  lastSurfacedAt: Date | null;
  /** Absent des lectures de liste (colonne lourde), présent après `get`. */
  embedding?: number[] | null;
}

export interface NewBookmark {
  url: string;
  urlHash: string;
  source: BookmarkSource;
  title: string | null;
  note: string | null;
  /** Enregistre mais inaccessible : le pipeline ne tourne pas dessus. */
  locked?: boolean;
}

/** Résultat du pipeline d'ingestion, écrit en une seule mise à jour. */
export interface PipelineResult {
  status: Exclude<BookmarkStatus, "processing">;
  title: string | null;
  summary: Summary | null;
  keywords: string[];
  category: Category;
  imageUrl: string | null;
  embedding: number[] | null;
  failureReason: string | null;
}

/** Résumé réutilisable d'un autre utilisateur (cache par url_hash, AI Architecture §2). */
export interface CachedSummary {
  title: string | null;
  summary: Summary;
  keywords: string[];
  category: string;
  imageUrl: string | null;
  embedding: number[] | null;
}

export interface ListOptions {
  limit: number;
  /** Curseur keyset : uniquement les lymarks créés avant cet instant. */
  before?: Date;
  archived?: boolean;
  status?: BookmarkStatus;
}

export interface BookmarkPatch {
  note?: string | null | undefined;
  archived?: boolean | undefined;
}

export interface UserSettingsPatch {
  tz?: string | undefined;
  digestHour?: number | undefined;
  digestOptin?: boolean | undefined;
}

export interface SearchHit {
  bookmark: BookmarkRow;
  score: number;
}

export interface SubscriptionEvent {
  eventId: string;
  occurredAt: Date;
  entitlement: Plan;
  expiresAt: Date | null;
  rcAppUserId: string;
}

export interface Db {
  users: {
    findByClerkId(clerkId: string): Promise<UserRow | null>;
    create(clerkId: string): Promise<UserRow>;
    get(userId: string): Promise<UserRow | null>;
    updateSettings(userId: string, patch: UserSettingsPatch): Promise<UserRow | null>;
    /** Pose (string) ou retire (null) l'avatar. Null si l'utilisateur n'existe pas. */
    setAvatar(userId: string, avatar: string | null): Promise<UserRow | null>;
    /** Purge tout (cascade) — Privacy §5. */
    delete(userId: string): Promise<void>;
  };
  bookmarks: {
    insert(userId: string, data: NewBookmark): Promise<BookmarkRow>;
    countLocked(userId: string): Promise<number>;
    /** Passage en Pro : tout redevient accessible. Rend les lignes liberees. */
    unlockAll(userId: string): Promise<BookmarkRow[]>;
    findByHash(userId: string, urlHash: string): Promise<BookmarkRow | null>;
    /** Doublon d'URL : saved_count + 1, note remplacée si fournie (PRD §3). */
    bumpDuplicate(
      userId: string,
      urlHash: string,
      note: string | null,
    ): Promise<BookmarkRow | null>;
    list(userId: string, opts: ListOptions): Promise<BookmarkRow[]>;
    get(userId: string, id: string): Promise<BookmarkRow | null>;
    update(userId: string, id: string, patch: BookmarkPatch): Promise<BookmarkRow | null>;
    delete(userId: string, id: string): Promise<boolean>;
    markOpened(userId: string, id: string, at: Date): Promise<boolean>;
    /** Compte des lymarks actifs = base de la limite Free (Monetization §1). */
    countActive(userId: string): Promise<number>;
    /** Captures depuis `since` = base du rate limiting 30/h (Security §5). */
    countCreatedSince(userId: string, since: Date): Promise<number>;
    /** Repasse en `processing` avant un retry ; false si le lymark n'est pas au user. */
    /**
     * Repasse en `processing` une entrée en échec ou partielle — ou en
     * traitement depuis avant `stalledBefore` (abandonnée). Null sinon.
     */
    resetForRetry(userId: string, id: string, stalledBefore: Date): Promise<BookmarkRow | null>;
    /** Écrit le résultat du pipeline. Pas de userId : appelé hors requête, sur un id qu'on a créé. */
    setResult(id: string, result: PipelineResult): Promise<void>;
    findCachedSummary(urlHash: string): Promise<CachedSummary | null>;
    searchText(userId: string, query: string, limit: number): Promise<SearchHit[]>;
    searchHybrid(
      userId: string,
      query: string,
      embedding: number[],
      limit: number,
    ): Promise<SearchHit[]>;
    similar(userId: string, id: string, limit: number, minScore: number): Promise<SearchHit[]>;
    exportAll(userId: string): Promise<BookmarkRow[]>;
  };
  subscriptions: {
    getPlan(userId: string): Promise<Plan>;
    /** Idempotent : ignore un event déjà vu ou plus ancien que le dernier appliqué. */
    applyEvent(
      clerkId: string,
      event: SubscriptionEvent,
    ): Promise<"applied" | "ignored" | "unknown_user">;
  };
  /** Ping pour /health : lève si la base ne répond pas. */
  ping(): Promise<void>;
}
