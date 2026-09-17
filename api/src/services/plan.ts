// Limites de plan et quotas, appliqués côté serveur uniquement
// (Monetization Spec §3, Security §5, Threat Model M4/M5).

import type { Plan } from "../db/types.js";

/** Lymarks actifs autorisés en Free. */
export const FREE_ACTIVE_LIMIT = 30;

/** Captures par heure et par utilisateur, tous plans. */
export const CAPTURES_PER_HOUR = 30;

/** Fenêtre du quota de capture. */
export const CAPTURE_WINDOW_MS = 60 * 60 * 1000;

export function activeLimitFor(plan: Plan): number | null {
  return plan === "pro" ? null : FREE_ACTIVE_LIMIT;
}

export function canCreate(plan: Plan, activeCount: number): boolean {
  const limit = activeLimitFor(plan);
  return limit === null || activeCount < limit;
}

export function canSearchSemantic(plan: Plan): boolean {
  return plan === "pro";
}

export function canUseDigest(plan: Plan): boolean {
  return plan === "pro";
}
