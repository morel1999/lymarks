// Embeddings Gemini (AI Architecture §1). Entrée : « titre. puce1 puce2 puce3 »
// ou une requête de recherche telle quelle. Jamais la note utilisateur
// (Privacy §2). Sortie : 768 dimensions, contrôlées avant écriture.

export const EMBEDDING_DIMENSIONS = 768;

export interface Embedder {
  embed(text: string, taskType: "RETRIEVAL_DOCUMENT" | "RETRIEVAL_QUERY"): Promise<number[]>;
}

export class EmbedError extends Error {
  constructor(
    public readonly reason: string,
    message: string,
  ) {
    super(message);
    this.name = "EmbedError";
  }
}

/** Texte vectorisé pour un lymark : titre + puces, borné. */
export function embeddingInput(title: string | null, bullets: string[]): string {
  const parts = [title?.trim(), ...bullets.map((b) => b.trim())].filter(Boolean);
  return parts.join(". ").replace(/\.\./g, ".").slice(0, 2000);
}

export interface GeminiEmbedderOptions {
  apiKey: string;
  model: string;
  fetch?: typeof fetch;
  timeoutMs?: number;
}

export class GeminiEmbedder implements Embedder {
  private readonly fetchFn: typeof fetch;

  constructor(private readonly opts: GeminiEmbedderOptions) {
    // Jamais `fetch` nu : appelé ensuite comme `this.fetchFn(...)`, il
    // recevrait l'instance en `this` et Workers lève « Illegal invocation »
    // (constaté en prod le 18/09 ; invisible en test, où `fetch` est injecté).
    this.fetchFn = opts.fetch ?? ((input, init) => fetch(input, init));
  }

  async embed(text: string, taskType: "RETRIEVAL_DOCUMENT" | "RETRIEVAL_QUERY"): Promise<number[]> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.opts.timeoutMs ?? 15_000);
    try {
      const model = this.opts.model.startsWith("models/")
        ? this.opts.model
        : `models/${this.opts.model}`;
      const res = await this.fetchFn(
        `https://generativelanguage.googleapis.com/v1beta/${model}:embedContent`,
        {
          method: "POST",
          signal: controller.signal,
          headers: { "content-type": "application/json", "x-goog-api-key": this.opts.apiKey },
          body: JSON.stringify({
            model,
            content: { parts: [{ text }] },
            taskType,
            // Ignoré par text-embedding-004 (déjà 768), respecté par les
            // modèles plus larges : le schéma vector(768) reste valable.
            outputDimensionality: EMBEDDING_DIMENSIONS,
          }),
        },
      );
      if (!res.ok) {
        const reason =
          res.status === 429 ? "rate_limited" : res.status >= 500 ? "provider_down" : "http_error";
        throw new EmbedError(reason, `gemini HTTP ${res.status}`);
      }
      const body = (await res.json()) as { embedding?: { values?: unknown } };
      const values = body.embedding?.values;
      if (!Array.isArray(values) || values.length !== EMBEDDING_DIMENSIONS) {
        throw new EmbedError(
          "dimensions",
          `Embedding inattendu (${Array.isArray(values) ? values.length : "?"} dims)`,
        );
      }
      if (!values.every((v) => typeof v === "number" && Number.isFinite(v))) {
        throw new EmbedError("dimensions", "Embedding non numérique");
      }
      return values as number[];
    } catch (err) {
      if (controller.signal.aborted) throw new EmbedError("timeout", "gemini : délai dépassé");
      throw err;
    } finally {
      clearTimeout(timer);
    }
  }
}
