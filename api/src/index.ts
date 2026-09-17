// Point d'entrée Cloudflare Workers : construit les dépendances depuis
// l'environnement (secrets + vars de wrangler.toml) et sert l'application.

import { createApp } from "./app.js";
import { createNeonDb } from "./db/neon.js";
import type { AppDeps } from "./deps.js";
import { createClerkVerifier } from "./middleware/auth.js";
import { GeminiEmbedder } from "./services/embedder.js";
import { processBookmark } from "./services/pipeline.js";
import { scrape } from "./services/scraper.js";
import { dohResolver } from "./services/ssrf.js";
import { ChatSummarizer, geminiChatProvider, groqProvider } from "./services/summarizer.js";

export interface Env {
  APP_VERSION: string;
  GROQ_MODEL: string;
  GEMINI_SUMMARY_MODEL: string;
  GEMINI_EMBEDDING_MODEL: string;
  // Secrets (.dev.vars en local, `wrangler secret` en prod).
  DATABASE_URL: string;
  CLERK_PUBLISHABLE_KEY: string;
  CLERK_SECRET_KEY?: string;
  GROQ_API_KEY: string;
  GEMINI_API_KEY: string;
  REVENUECAT_WEBHOOK_SECRET?: string;
  REVENUECAT_API_KEY?: string;
}

const log = (event: Record<string, unknown>): void => {
  console.warn(JSON.stringify({ ts: new Date().toISOString(), ...event }));
};

function required(env: Env, key: keyof Env): string {
  const value = env[key];
  if (!value) throw new Error(`Secret manquant : ${key}`);
  return value;
}

export function buildDeps(env: Env): AppDeps {
  const db = createNeonDb(required(env, "DATABASE_URL"));
  const embedder = new GeminiEmbedder({
    apiKey: required(env, "GEMINI_API_KEY"),
    model: env.GEMINI_EMBEDDING_MODEL || "text-embedding-004",
  });
  const summarizer = new ChatSummarizer({
    providers: [
      groqProvider(required(env, "GROQ_API_KEY"), env.GROQ_MODEL || "llama-3.3-70b-versatile"),
      geminiChatProvider(
        required(env, "GEMINI_API_KEY"),
        env.GEMINI_SUMMARY_MODEL || "gemini-2.5-flash",
      ),
    ],
    log,
  });
  const scrapeOptions = { resolve: dohResolver() };

  const clerkSecret = env.CLERK_SECRET_KEY;
  const rcKey = env.REVENUECAT_API_KEY;

  return {
    db,
    verifyToken: createClerkVerifier({ publishableKey: required(env, "CLERK_PUBLISHABLE_KEY") }),
    runPipeline: (job) =>
      processBookmark({ db, scrape, scrapeOptions, summarizer, embedder, log }, job),
    embedQuery: (q) => embedder.embed(q, "RETRIEVAL_QUERY"),
    revenuecatWebhookSecret: env.REVENUECAT_WEBHOOK_SECRET || null,
    deleteClerkUser: clerkSecret
      ? async (clerkId) => {
          const res = await fetch(`https://api.clerk.com/v1/users/${encodeURIComponent(clerkId)}`, {
            method: "DELETE",
            headers: { authorization: `Bearer ${clerkSecret}` },
          });
          if (!res.ok && res.status !== 404) throw new Error(`clerk HTTP ${res.status}`);
        }
      : null,
    deleteRevenuecatSubscriber: rcKey
      ? async (appUserId) => {
          const res = await fetch(
            `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
            {
              method: "DELETE",
              headers: { authorization: `Bearer ${rcKey}` },
            },
          );
          if (!res.ok && res.status !== 404) throw new Error(`revenuecat HTTP ${res.status}`);
        }
      : null,
    now: () => new Date(),
    version: env.APP_VERSION || "dev",
    log,
  };
}

let cached: { env: Env; app: ReturnType<typeof createApp> } | null = null;

export default {
  fetch(request: Request, env: Env, ctx: ExecutionContext): Response | Promise<Response> {
    if (!cached || cached.env !== env) cached = { env, app: createApp(buildDeps(env)) };
    return cached.app.fetch(request, env, ctx);
  },
} satisfies ExportedHandler<Env>;
