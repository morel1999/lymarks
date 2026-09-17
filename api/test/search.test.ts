import { describe, expect, it } from "vitest";
import {
  cosineSimilarity,
  fusedScore,
  queryTerms,
  textRank,
  toTsQuery,
} from "../src/services/search.js";

describe("toTsQuery", () => {
  it("préfixe chaque terme et neutralise la syntaxe tsquery", () => {
    expect(toTsQuery("Flutter riverpod")).toBe("flutter:* & riverpod:*");
    expect(toTsQuery("a & b | c ! (d)")).toBe("a:* & b:* & c:* & d:*");
    expect(toTsQuery("l'état")).toBe("l:* & état:*");
    expect(toTsQuery("   ")).toBeNull();
  });

  it("borne à 8 termes", () => {
    expect(queryTerms("1 2 3 4 5 6 7 8 9 10")).toHaveLength(8);
  });
});

describe("scores", () => {
  it("cosinus : identiques = 1, orthogonaux = 0", () => {
    expect(cosineSimilarity([1, 0], [1, 0])).toBeCloseTo(1);
    expect(cosineSimilarity([1, 0], [0, 1])).toBeCloseTo(0);
    expect(cosineSimilarity([1, 0], [1])).toBe(0);
  });

  it("fusion 0,7 / 0,3 bornée", () => {
    expect(fusedScore(1, 1)).toBeCloseTo(1);
    expect(fusedScore(0.5, 0)).toBeCloseTo(0.35);
    expect(fusedScore(-1, 2)).toBeCloseTo(0.3);
  });

  it("rang texte façon ts_rank normalisé", () => {
    expect(textRank("flutter riverpod state", "flutter")).toBeCloseTo(0.5);
    expect(textRank("flutter riverpod state", "flutter state")).toBeCloseTo(2 / 3);
    expect(textRank("cuisine", "flutter")).toBe(0);
  });
});
