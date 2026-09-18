// Taxonomie fermée des lymarks. Le résumeur choisit une entrée ; tout ce qui
// n'en fait pas partie (modèle créatif, champ absent, casse différente)
// retombe sur `other` : la catégorie ne fait jamais échouer un résumé.

export const CATEGORIES = [
  "ai",
  "development",
  "design",
  "product",
  "business",
  "science",
  "culture",
  "sport",
  "lifestyle",
  "other",
] as const;

export type Category = (typeof CATEGORIES)[number];

export function isCategory(x: string): x is Category {
  return (CATEGORIES as readonly string[]).includes(x);
}

/** Minuscule, sans espaces autour ; inconnu ou non textuel → `other`. */
export function normalizeCategory(x: unknown): Category {
  if (typeof x !== "string") return "other";
  const key = x.trim().toLowerCase();
  return isCategory(key) ? key : "other";
}
