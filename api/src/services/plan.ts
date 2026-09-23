// Limites de plan et quotas, appliqués côté serveur uniquement
// (Monetization Spec §3, Security §5, Threat Model M4/M5).

import type { Plan } from "../db/types.js";

/** Lymarks actifs autorisés en Free. */
export const FREE_ACTIVE_LIMIT = 30;

/**
 * Lymarks verrouilles gardes pour un compte Free.
 *
 * Au-dela de FREE_ACTIVE_LIMIT, une capture n'est plus refusee : elle est
 * enregistree et verrouillee, pour qu'aucun lien partage ne se perde. Ce
 * plafond protege la base d'un compte qui en enregistrerait des milliers ;
 * un usage normal ne le touche pas.
 */
export const FREE_LOCKED_LIMIT = 100;

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

/**
 * Vrai quand la capture doit etre enregistree mais inaccessible : plan Free
 * ayant atteint sa limite d'actifs. Le lien est garde, floute cote app.
 */
export function shouldLock(plan: Plan, activeCount: number): boolean {
  return !canCreate(plan, activeCount);
}

/**
 * Vrai quand meme le stockage verrouille est plein : la capture est alors
 * refusee pour de bon, et l'utilisateur le voit au moment du partage.
 */
export function lockedStorageFull(plan: Plan, lockedCount: number): boolean {
  return plan !== "pro" && lockedCount >= FREE_LOCKED_LIMIT;
}

export function canSearchSemantic(plan: Plan): boolean {
  return plan === "pro";
}

export function canUseDigest(plan: Plan): boolean {
  return plan === "pro";
}
