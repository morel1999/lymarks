// Forme JSON exposée à l'app. Miroir de `app/lib/shared/models/lymark.dart` :
// tout changement ici se répercute dans le client Flutter.

import type { BookmarkRow, UserRow, Plan } from "../db/types.js";
import { isStalled } from "../services/pipeline.js";
import { activeLimitFor } from "../services/plan.js";
import { domainOf } from "../services/url.js";

export interface BookmarkDto {
  id: string;
  url: string;
  domain: string;
  title: string | null;
  source: BookmarkRow["source"];
  status: BookmarkRow["status"];
  bullets: string[];
  keywords: string[];
  category: string;
  imageUrl: string | null;
  lang: string | null;
  note: string | null;
  savedAt: string;
  updatedAt: string;
  lastOpenedAt: string | null;
  archived: boolean;
  savedCount: number;
  failureReason: string | null;
}

export function toBookmarkDto(b: BookmarkRow, now: Date = new Date()): BookmarkDto {
  // Un traitement abandonné (Worker annulé) est montré comme un échec
  // relançable plutôt qu'un squelette éternel.
  const stalled = isStalled(b, now);
  return {
    id: b.id,
    url: b.url,
    domain: domainOf(b.url),
    title: b.title,
    source: b.source,
    status: stalled ? "failed" : b.status,
    bullets: b.summary?.bullets ?? [],
    keywords: b.keywords,
    category: b.category,
    imageUrl: b.imageUrl,
    lang: b.summary?.lang ?? null,
    note: b.note,
    savedAt: b.createdAt.toISOString(),
    updatedAt: b.updatedAt.toISOString(),
    lastOpenedAt: b.lastOpenedAt?.toISOString() ?? null,
    archived: b.archived,
    savedCount: b.savedCount,
    failureReason: stalled ? "stalled" : b.failureReason,
  };
}

export interface MeDto {
  id: string;
  plan: Plan;
  lymarkCount: number;
  lymarkLimit: number | null;
  tz: string;
  digestHour: number;
  digestOptin: boolean;
  avatar: string | null;
  createdAt: string;
}

export function toMeDto(u: UserRow, plan: Plan, lymarkCount: number): MeDto {
  return {
    id: u.id,
    plan,
    lymarkCount,
    lymarkLimit: activeLimitFor(plan),
    tz: u.tz,
    digestHour: u.digestHour,
    digestOptin: u.digestOptin,
    avatar: u.avatar,
    createdAt: u.createdAt.toISOString(),
  };
}
