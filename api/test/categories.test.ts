import { describe, expect, it } from "vitest";
import { CATEGORIES, normalizeCategory } from "../src/services/categories.js";

describe("normalizeCategory", () => {
  it("accepte chaque entrée de la taxonomie, quelle que soit la casse ou les espaces", () => {
    for (const c of CATEGORIES) {
      expect(normalizeCategory(c)).toBe(c);
      expect(normalizeCategory(`  ${c.toUpperCase()} `)).toBe(c);
    }
  });

  it("ramène tout le reste à other : inconnu, vide, absent, non textuel", () => {
    expect(normalizeCategory("cooking")).toBe("other");
    expect(normalizeCategory("ai ")).toBe("ai");
    expect(normalizeCategory("")).toBe("other");
    expect(normalizeCategory(undefined)).toBe("other");
    expect(normalizeCategory(null)).toBe("other");
    expect(normalizeCategory(42)).toBe("other");
    expect(normalizeCategory(["ai"])).toBe("other");
  });
});
