// Résumeur : Groq (Llama 3.3 70B) en premier, Gemini Flash en secours
// (AI Architecture §1–§2). Les deux parlent le protocole « chat completions »
// d'OpenAI : une seule implémentation, deux points d'accès.
//
// Sortie validée par schéma (Threat Model M2) : une réponse hors format
// déclenche un second essai avec consigne de correction, puis le fournisseur
// suivant. Le texte scrapé ne quitte jamais ce module autrement que dans le
// prompt ; la note utilisateur n'y entre jamais (Privacy §2).

import { z } from "zod";
import { SUMMARIZE_FIX, SUMMARIZE_SYSTEM, summarizeUser } from "../prompts/summarize.v2.js";
import { normalizeCategory, type Category } from "./categories.js";

export interface SummaryOutput {
  bullets: string[];
  keywords: string[];
  lang: string | null;
  /** Toujours une entrée de la taxonomie : `other` si le modèle se trompe ou l'omet. */
  category: Category;
}

export interface Summarizer {
  summarize(input: { title: string | null; content: string }): Promise<SummaryOutput>;
}

export class SummarizeError extends Error {
  constructor(
    public readonly reason: string,
    message: string,
  ) {
    super(message);
    this.name = "SummarizeError";
  }
}

const MAX_BULLET = 120;

const summarySchema = z.object({
  bullets: z
    .array(
      z
        .string()
        .trim()
        .min(1)
        .max(MAX_BULLET + 40),
    )
    .max(3),
  keywords: z.array(z.string().trim().min(1).max(40)).max(8),
  lang: z
    .string()
    .trim()
    .regex(/^[a-zA-Z]{2,3}(-[a-zA-Z0-9]{2,8})?$/)
    .nullable()
    .optional(),
  // Accessoire : une valeur absente ou farfelue ne vaut pas un retry, elle
  // est ramenée à `other` par tidySummary.
  category: z.unknown().optional(),
});

/** Nettoie et borne une sortie déjà conforme au schéma. */
export function tidySummary(raw: z.infer<typeof summarySchema>): SummaryOutput {
  const bullets = raw.bullets
    .map((b) =>
      b
        .replace(/\s+/g, " ")
        .replace(/^[-•*]\s*/, "")
        .trim(),
    )
    .filter(Boolean)
    .map((b) => (b.length > MAX_BULLET ? `${b.slice(0, MAX_BULLET - 1).trimEnd()}…` : b))
    .slice(0, 3);
  const seen = new Set<string>();
  const keywords: string[] = [];
  for (const k of raw.keywords) {
    const key = k.toLowerCase().replace(/\s+/g, " ").trim();
    if (key && !seen.has(key)) {
      seen.add(key);
      keywords.push(key);
    }
    if (keywords.length === 6) break;
  }
  const lang = raw.lang ? raw.lang.slice(0, 2).toLowerCase() : null;
  return { bullets, keywords, lang, category: normalizeCategory(raw.category) };
}

/** Extrait le premier objet JSON d'une réponse, même entourée de texte ou de ```. */
export function parseModelJson(text: string): unknown {
  const trimmed = text
    .trim()
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```$/, "");
  try {
    return JSON.parse(trimmed);
  } catch {
    const start = trimmed.indexOf("{");
    const end = trimmed.lastIndexOf("}");
    if (start < 0 || end <= start) throw new SummarizeError("not_json", "Réponse sans JSON");
    try {
      return JSON.parse(trimmed.slice(start, end + 1));
    } catch {
      throw new SummarizeError("not_json", "JSON invalide");
    }
  }
}

/** Null si la réponse est un JSON conforme, sinon la raison. */
function validate(text: string): string | null {
  let json: unknown;
  try {
    json = parseModelJson(text);
  } catch (err) {
    return (err as Error).message;
  }
  const parsed = summarySchema.safeParse(json);
  return parsed.success ? null : parsed.error.issues.map((i) => i.message).join("; ");
}

export interface ChatProvider {
  name: string;
  baseUrl: string;
  apiKey: string;
  model: string;
  /**
   * Modèle raisonnant (gpt-oss, Gemini 3.x) : il dépense des jetons de
   * réflexion avant la réponse. On lui demande le minimum et on laisse de
   * la marge, sinon `content` revient vide avec `finish_reason: length`.
   */
  reasoning?: boolean;
}

export const groqProvider = (apiKey: string, model: string): ChatProvider => ({
  name: "groq",
  baseUrl: "https://api.groq.com/openai/v1",
  apiKey,
  model,
  reasoning: /gpt-oss|qwen3|deepseek-r/i.test(model),
});

export const geminiChatProvider = (apiKey: string, model: string): ChatProvider => ({
  name: "gemini",
  baseUrl: "https://generativelanguage.googleapis.com/v1beta/openai",
  apiKey,
  model,
  reasoning: /gemini-[3-9]/i.test(model),
});

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

export interface ChatSummarizerOptions {
  providers: ChatProvider[];
  fetch?: typeof fetch;
  /** Pause avant le 2ᵉ essai sur un même fournisseur (2 s en prod, 0 en test). */
  retryDelayMs?: number;
  timeoutMs?: number;
  log?: (event: Record<string, unknown>) => void;
}

/**
 * Enchaîne les fournisseurs. Sur chacun : 1 appel, puis 1 retry (erreur
 * réseau/HTTP → backoff ; sortie non conforme → consigne de correction).
 */
export class ChatSummarizer implements Summarizer {
  private readonly fetchFn: typeof fetch;

  constructor(private readonly opts: ChatSummarizerOptions) {
    if (opts.providers.length === 0) throw new Error("ChatSummarizer : aucun fournisseur");
    // Jamais `fetch` nu : appelé ensuite comme `this.fetchFn(...)`, il
    // recevrait l'instance en `this` et Workers lève « Illegal invocation »
    // (constaté en prod le 18/09 ; invisible en test, où `fetch` est injecté).
    this.fetchFn = opts.fetch ?? ((input, init) => fetch(input, init));
  }

  async summarize(input: { title: string | null; content: string }): Promise<SummaryOutput> {
    const base: ChatMessage[] = [
      { role: "system", content: SUMMARIZE_SYSTEM },
      { role: "user", content: summarizeUser(input.title, input.content) },
    ];
    let lastError: Error = new SummarizeError("unavailable", "Aucun fournisseur disponible");

    for (const provider of this.opts.providers) {
      let messages = base;
      for (let attempt = 0; attempt < 2; attempt += 1) {
        let text: string;
        try {
          text = await this.complete(provider, messages);
        } catch (err) {
          // Erreur réseau/HTTP : backoff puis second essai sur le même fournisseur.
          lastError = err instanceof Error ? err : new Error(String(err));
          this.opts.log?.({
            event: "summarize_retry",
            provider: provider.name,
            attempt,
            reason: lastError.message,
          });
          if (attempt === 0 && (this.opts.retryDelayMs ?? 2000) > 0) {
            await new Promise((r) => setTimeout(r, this.opts.retryDelayMs ?? 2000));
          }
          continue;
        }
        const problem = validate(text);
        if (problem === null) return tidySummary(summarySchema.parse(parseModelJson(text)));
        // Sortie hors format (Threat Model M2) : retry immédiat avec la consigne
        // de correction (AI Architecture §3), la réponse fautive en contexte.
        lastError = new SummarizeError("schema", problem);
        this.opts.log?.({
          event: "summarize_retry",
          provider: provider.name,
          attempt,
          reason: problem,
        });
        messages = [
          ...base,
          { role: "assistant", content: text },
          { role: "user", content: SUMMARIZE_FIX },
        ];
      }
    }
    throw lastError;
  }

  private async complete(provider: ChatProvider, messages: ChatMessage[]): Promise<string> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.opts.timeoutMs ?? 25_000);
    try {
      const res = await this.fetchFn(`${provider.baseUrl}/chat/completions`, {
        method: "POST",
        signal: controller.signal,
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${provider.apiKey}`,
        },
        body: JSON.stringify({
          model: provider.model,
          temperature: 0.2,
          max_tokens: provider.reasoning ? 1200 : 400,
          ...(provider.reasoning ? { reasoning_effort: "low" } : {}),
          response_format: { type: "json_object" },
          messages,
        }),
      });
      if (!res.ok) {
        const reason =
          res.status === 429 ? "rate_limited" : res.status >= 500 ? "provider_down" : "http_error";
        throw new SummarizeError(reason, `${provider.name} HTTP ${res.status}`);
      }
      const body = (await res.json()) as { choices?: Array<{ message?: { content?: string } }> };
      const content = body.choices?.[0]?.message?.content;
      if (typeof content !== "string" || !content.trim()) {
        throw new SummarizeError("empty", `${provider.name} : réponse vide`);
      }
      return content;
    } catch (err) {
      if (controller.signal.aborted)
        throw new SummarizeError("timeout", `${provider.name} : délai dépassé`);
      throw err;
    } finally {
      clearTimeout(timer);
    }
  }
}
