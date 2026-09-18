import { afterEach, describe, expect, it, vi } from "vitest";
import { EMBEDDING_DIMENSIONS, embeddingInput, GeminiEmbedder } from "../src/services/embedder.js";

describe("embeddingInput", () => {
  it("assemble titre + puces, jamais la note", () => {
    expect(embeddingInput("Titre", ["Un.", "Deux"])).toBe("Titre. Un. Deux");
    expect(embeddingInput(null, ["Seule"])).toBe("Seule");
    expect(embeddingInput(null, [])).toBe("");
  });
});

describe("GeminiEmbedder", () => {
  it("appelle embedContent avec la clé en en-tête et demande 768 dimensions", async () => {
    let captured: { url: string; init: RequestInit } | null = null;
    const fetchFn = (async (input: RequestInfo | URL, init?: RequestInit) => {
      captured = { url: String(input), init: init! };
      return new Response(
        JSON.stringify({ embedding: { values: new Array(EMBEDDING_DIMENSIONS).fill(0.5) } }),
      );
    }) as typeof fetch;
    const e = new GeminiEmbedder({
      apiKey: "AIza-test",
      model: "text-embedding-004",
      fetch: fetchFn,
    });
    const v = await e.embed("hello", "RETRIEVAL_DOCUMENT");
    expect(v).toHaveLength(EMBEDDING_DIMENSIONS);
    const { url, init } = captured!;
    expect(url).toBe(
      "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent",
    );
    expect(url).not.toContain("AIza-test");
    expect(new Headers(init.headers).get("x-goog-api-key")).toBe("AIza-test");
    expect(JSON.parse(String(init.body))).toMatchObject({
      taskType: "RETRIEVAL_DOCUMENT",
      outputDimensionality: 768,
    });
  });

  it("rejette une dimension inattendue ou une erreur HTTP", async () => {
    const bad = (async () =>
      new Response(JSON.stringify({ embedding: { values: [1, 2, 3] } }))) as typeof fetch;
    await expect(
      new GeminiEmbedder({ apiKey: "k", model: "m", fetch: bad }).embed("x", "RETRIEVAL_QUERY"),
    ).rejects.toMatchObject({ reason: "dimensions" });
    const down = (async () => new Response("", { status: 503 })) as typeof fetch;
    await expect(
      new GeminiEmbedder({ apiKey: "k", model: "m", fetch: down }).embed("x", "RETRIEVAL_QUERY"),
    ).rejects.toMatchObject({ reason: "provider_down" });
  });
});

describe("GeminiEmbedder — fetch global", () => {
  afterEach(() => vi.unstubAllGlobals());

  it("appelle le fetch global sans `this` (Workers refuse « Illegal invocation »)", async () => {
    const strictFetch = async function (this: unknown, _input: RequestInfo | URL) {
      if (this !== undefined && this !== globalThis) throw new TypeError("Illegal invocation");
      return new Response(
        JSON.stringify({ embedding: { values: new Array(EMBEDDING_DIMENSIONS).fill(0.1) } }),
      );
    };
    vi.stubGlobal("fetch", strictFetch);
    const e = new GeminiEmbedder({ apiKey: "k", model: "m" });
    expect(await e.embed("x", "RETRIEVAL_QUERY")).toHaveLength(EMBEDDING_DIMENSIONS);
  });
});
