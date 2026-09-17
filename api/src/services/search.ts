// Recherche (SAD Flux 2, module M3) : helpers purs partagés par l'implémentation
// SQL (src/db/neon.ts) et par le dépôt en mémoire des tests.

/** Poids de la fusion Pro (Knowledge Vault §5, ⚠️ à calibrer). */
export const SEMANTIC_WEIGHT = 0.7;
export const TEXT_WEIGHT = 0.3;
export const SIMILAR_MIN_SCORE = 0.75;
export const MAX_QUERY_CHARS = 200;

/** Termes normalisés d'une requête : minuscules, sans ponctuation tsquery, ≤ 8. */
export function queryTerms(query: string): string[] {
  return query
    .toLowerCase()
    .slice(0, MAX_QUERY_CHARS)
    .split(/[\s,;:!?()[\]{}<>"'`|&*/\\]+/)
    .map((t) => t.replace(/^-+|-+$/g, ""))
    .filter((t) => t.length > 0)
    .slice(0, 8);
}

/**
 * Requête `to_tsquery('simple', …)` avec préfixe sur chaque terme : « flu »
 * trouve « flutter ». Null si la requête est vide.
 */
export function toTsQuery(query: string): string | null {
  const terms = queryTerms(query);
  if (terms.length === 0) return null;
  return terms.map((t) => `${t.replace(/'/g, "''")}:*`).join(" & ");
}

export function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length || a.length === 0) return 0;
  let dot = 0;
  let na = 0;
  let nb = 0;
  for (let i = 0; i < a.length; i += 1) {
    const x = a[i]!;
    const y = b[i]!;
    dot += x * y;
    na += x * x;
    nb += y * y;
  }
  if (na === 0 || nb === 0) return 0;
  return dot / (Math.sqrt(na) * Math.sqrt(nb));
}

export function fusedScore(semantic: number, text: number): number {
  return SEMANTIC_WEIGHT * Math.max(0, semantic) + TEXT_WEIGHT * Math.max(0, Math.min(1, text));
}

/** Rang texte ∈ [0,1) façon `ts_rank(…, 32)` : nb de termes trouvés / (nb + 1). */
export function textRank(haystack: string, query: string): number {
  const terms = queryTerms(query);
  if (terms.length === 0) return 0;
  const words = haystack.toLowerCase();
  const matched = terms.filter((t) => words.includes(t)).length;
  return matched === 0 ? 0 : matched / (matched + 1);
}
