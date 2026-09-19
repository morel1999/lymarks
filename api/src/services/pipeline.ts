// Pipeline d'ingestion (SAD Flux 1, module M2) : scrape → résumé → embedding →
// mise à jour. Tourne après le 201, dans `ctx.waitUntil` ; l'utilisateur ne
// l'attend jamais. Toute sortie est un statut final : jamais d'échec silencieux
// (PRD §3).

import type { Db, PipelineResult } from "../db/types.js";
import { normalizeCategory } from "./categories.js";
import { embeddingInput, type Embedder } from "./embedder.js";
import { MAX_CHARS, ScrapeError, type PageContent, type ScrapeOptions } from "./scraper.js";
import type { Summarizer } from "./summarizer.js";

export interface PipelineDeps {
  db: Db;
  scrape: (url: string, opts: ScrapeOptions) => Promise<PageContent>;
  scrapeOptions: ScrapeOptions;
  summarizer: Summarizer;
  embedder: Embedder;
  log: (event: Record<string, unknown>) => void;
}

/** Page lue par le téléphone quand le serveur n'a pas pu la lire (anti-robot, paywall). */
export interface ProvidedPage {
  title: string | null;
  description: string | null;
  text: string;
  lang: string | null;
  imageUrl: string | null;
}

export interface PipelineJob {
  id: string;
  url: string;
  urlHash: string;
  /** Titre transmis par la feuille de partage : sert de secours. */
  title: string | null;
  /** Fournie par `POST /bookmarks/:id/content` : remplace l'étape scrape. */
  page?: ProvidedPage;
}

/** En dessous, la page n'a pas livré de vrai contenu : on résume ses métadonnées → `partial`. */
const THIN_CONTENT_CHARS = 200;
/** En dessous, sans description, image ni vrai titre : page non rendue (voir `isShell`). */
const SHELL_TEXT_CHARS = 40;

/**
 * Au-delà, une entrée `processing` est tenue pour abandonnée : le pipeline ne
 * dépasse jamais ~1 min (scrape 10 s, 2 fournisseurs × 2 essais × 25 s au
 * pire), donc rien n'aboutira plus. Constaté en prod le 18/09 : requête de
 * création annulée par le client (mobile + VPN), l'invocation Workers meurt
 * avec elle et emporte le `waitUntil` — la ligne restait en traitement sans
 * fin. Servie comme échec relançable, et relancée par une nouvelle capture.
 */
export const STALL_AFTER_MS = 2 * 60_000;

export function isStalled(b: { status: string; updatedAt: Date }, now: Date): boolean {
  return b.status === "processing" && now.getTime() - b.updatedAt.getTime() > STALL_AFTER_MS;
}

export async function processBookmark(
  deps: PipelineDeps,
  job: PipelineJob,
): Promise<PipelineResult> {
  const started = Date.now();
  const result = await run(deps, job);
  await deps.db.bookmarks.setResult(job.id, result);
  deps.log({
    event: "pipeline_done",
    bookmarkId: job.id,
    status: result.status,
    reason: result.failureReason,
    ms: Date.now() - started,
  });
  return result;
}

async function run(deps: PipelineDeps, job: PipelineJob): Promise<PipelineResult> {
  // 1. Cache inter-utilisateurs : même page, même résumé (AI Architecture §2).
  const cached = await deps.db.bookmarks.findCachedSummary(job.urlHash).catch(() => null);
  if (cached) {
    deps.log({ event: "pipeline_cache_hit", bookmarkId: job.id });
    return {
      status: cached.embedding ? "ready" : "partial",
      title: job.title ?? cached.title,
      summary: cached.summary,
      keywords: cached.keywords,
      category: normalizeCategory(cached.category),
      imageUrl: cached.imageUrl,
      embedding: cached.embedding,
      failureReason: null,
    };
  }

  // 2. Scrape — sauf si le téléphone a déjà lu la page pour nous.
  let page: PageContent;
  if (job.page) {
    page = providedPage(job.url, job.page);
  } else {
    try {
      page = await deps.scrape(job.url, deps.scrapeOptions);
    } catch (err) {
      const reason = err instanceof ScrapeError ? err.reason : "scrape_error";
      deps.log({
        event: "pipeline_scrape_failed",
        bookmarkId: job.id,
        reason,
        detail: (err as Error).message,
      });
      return failed(job.title, reason);
    }
  }

  const title = page.title ?? job.title;
  const thin = page.text.length < THIN_CONTENT_CHARS;
  const content = thin ? [page.description, page.text].filter(Boolean).join("\n") : page.text;
  if (!content.trim() && !title) return failed(null, "empty_page");
  // Une « coquille » (texte quasi nul, aucune métadonnée) est une page rendue
  // en JavaScript ou un mur de connexion servi 200 aux IP Cloudflare
  // (Instagram, Dribbble, pages de partage Xiaomi — constaté le 19/09) : rien
  // à résumer ici, mais le téléphone, lui, peut la lire — même issue que
  // `blocked`, que l'app sait rattraper.
  if (isShell(page)) {
    deps.log({ event: "pipeline_shell_page", bookmarkId: job.id });
    return failed(job.title, "blocked");
  }

  // 3. Résumé (le résumeur gère retry et fallback).
  let summary;
  try {
    summary = await deps.summarizer.summarize({ title, content });
  } catch (err) {
    deps.log({
      event: "pipeline_summary_failed",
      bookmarkId: job.id,
      reason: (err as Error).message,
    });
    return failed(title, "summary_failed");
  }
  const lang = summary.lang ?? page.lang?.slice(0, 2) ?? null;

  // 4. Embedding : son échec dégrade en `partial` (recherche texte seule), il
  //    ne perd pas le résumé.
  let embedding: number[] | null = null;
  const input = embeddingInput(title, summary.bullets);
  if (input) {
    try {
      embedding = await deps.embedder.embed(input, "RETRIEVAL_DOCUMENT");
    } catch (err) {
      deps.log({
        event: "pipeline_embed_failed",
        bookmarkId: job.id,
        reason: (err as Error).message,
      });
    }
  }

  const degraded = thin || summary.bullets.length === 0 || !embedding;
  return {
    status: degraded ? "partial" : "ready",
    title,
    summary: { bullets: summary.bullets, lang },
    keywords: summary.keywords,
    category: summary.category,
    imageUrl: page.imageUrl,
    embedding,
    failureReason: null,
  };
}

/** Même budget de texte que le scraper : le prompt ne distingue pas l'origine. */
function providedPage(url: string, page: ProvidedPage): PageContent {
  const text = page.text.length > MAX_CHARS ? `${page.text.slice(0, MAX_CHARS)}…` : page.text;
  return { ...page, text, finalUrl: url, siteName: null };
}

/**
 * Texte quasi nul, ni description ni image : la page n'a pas été rendue. Un
 * titre seul (« Instagram », « Dribbble - … ») ne vaut rien à résumer.
 */
export function isShell(page: PageContent): boolean {
  return page.text.trim().length < SHELL_TEXT_CHARS && !page.description?.trim() && !page.imageUrl;
}

function failed(title: string | null, reason: string): PipelineResult {
  return {
    status: "failed",
    title,
    summary: null,
    keywords: [],
    category: "other",
    imageUrl: null,
    embedding: null,
    failureReason: reason,
  };
}
