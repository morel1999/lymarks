// Scraper : fetch protégé + extraction du texte utile (SAD Flux 1, étape 3).
//
// Pas de DOM ni de Readability : un extracteur à base d'expressions régulières
// suffit pour un résumé en 3 puces et tient dans le budget CPU d'un Worker.
// Le texte extrait n'est jamais conservé en base (Privacy §1), seulement
// transmis au résumeur.

import { assertPublicUrl, UnsafeUrlError, type Resolver } from "./ssrf.js";
import { detectSource } from "./url.js";

export interface ScrapeOptions {
  fetch?: typeof fetch;
  resolve: Resolver;
  timeoutMs?: number;
  maxBytes?: number;
  maxRedirects?: number;
  userAgent?: string;
}

export interface PageContent {
  finalUrl: string;
  title: string | null;
  description: string | null;
  siteName: string | null;
  lang: string | null;
  /** Texte principal, déjà tronqué (voir MAX_CHARS). */
  text: string;
}

export class ScrapeError extends Error {
  constructor(
    public readonly reason: string,
    message: string,
  ) {
    super(message);
    this.name = "ScrapeError";
  }
}

/** ~8 000 tokens (AI Architecture §4). */
export const MAX_CHARS = 30_000;
const DEFAULT_TIMEOUT_MS = 10_000;
const DEFAULT_MAX_BYTES = 2 * 1024 * 1024;
const DEFAULT_MAX_REDIRECTS = 3;
const USER_AGENT = "LymarksBot/1.0 (+https://lymarks.app/bot)";
const ALLOWED_TYPES = ["text/html", "application/xhtml+xml"];

/**
 * Fetch avec anti-SSRF (re-vérifié à chaque redirection), timeout, plafond de
 * taille et filtre de content-type. Retourne le HTML décodé.
 */
export async function safeFetch(
  url: string,
  opts: ScrapeOptions,
): Promise<{ finalUrl: string; html: string }> {
  const fetchFn = opts.fetch ?? fetch;
  const maxRedirects = opts.maxRedirects ?? DEFAULT_MAX_REDIRECTS;
  const maxBytes = opts.maxBytes ?? DEFAULT_MAX_BYTES;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), opts.timeoutMs ?? DEFAULT_TIMEOUT_MS);

  try {
    let current = url;
    for (let hop = 0; hop <= maxRedirects; hop += 1) {
      const target = await assertPublicUrl(current, opts.resolve);
      let res: Response;
      try {
        res = await fetchFn(target.toString(), {
          redirect: "manual",
          signal: controller.signal,
          headers: {
            "user-agent": opts.userAgent ?? USER_AGENT,
            accept: "text/html,application/xhtml+xml;q=0.9,*/*;q=0.1",
            "accept-language": "fr,en;q=0.8",
          },
        });
      } catch (err) {
        if (controller.signal.aborted) throw new ScrapeError("timeout", "Délai dépassé");
        throw new ScrapeError("network", (err as Error).message);
      }

      if (res.status >= 300 && res.status < 400) {
        const location = res.headers.get("location");
        await res.body?.cancel();
        if (!location) throw new ScrapeError("redirect", "Redirection sans destination");
        if (hop === maxRedirects) throw new ScrapeError("redirect", "Trop de redirections");
        current = new URL(location, target).toString();
        continue;
      }
      if (res.status === 404 || res.status === 410) {
        await res.body?.cancel();
        throw new ScrapeError("not_found", `HTTP ${res.status}`);
      }
      if (!res.ok) {
        await res.body?.cancel();
        throw new ScrapeError("http_error", `HTTP ${res.status}`);
      }

      const contentType = (res.headers.get("content-type") ?? "").toLowerCase();
      if (!ALLOWED_TYPES.some((t) => contentType.startsWith(t))) {
        await res.body?.cancel();
        throw new ScrapeError(
          "content_type",
          `Type non pris en charge : ${contentType || "inconnu"}`,
        );
      }

      const bytes = await readCapped(res, maxBytes);
      const charset = /charset=([\w-]+)/i.exec(contentType)?.[1] ?? "utf-8";
      let html: string;
      try {
        html = new TextDecoder(charset).decode(bytes);
      } catch {
        html = new TextDecoder("utf-8").decode(bytes);
      }
      return { finalUrl: target.toString(), html };
    }
    throw new ScrapeError("redirect", "Trop de redirections");
  } catch (err) {
    if (err instanceof UnsafeUrlError) throw new ScrapeError("unsafe_url", err.message);
    throw err;
  } finally {
    clearTimeout(timer);
  }
}

/** Lit au plus `maxBytes` puis coupe : une page géante est tronquée, pas refusée. */
async function readCapped(res: Response, maxBytes: number): Promise<Uint8Array> {
  if (!res.body) return new Uint8Array();
  const reader = res.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  try {
    while (total < maxBytes) {
      const { done, value } = await reader.read();
      if (done) break;
      chunks.push(value);
      total += value.byteLength;
    }
  } finally {
    await reader.cancel().catch(() => undefined);
  }
  const out = new Uint8Array(Math.min(total, maxBytes));
  let offset = 0;
  for (const chunk of chunks) {
    const slice = chunk.subarray(0, Math.min(chunk.byteLength, out.byteLength - offset));
    out.set(slice, offset);
    offset += slice.byteLength;
    if (offset >= out.byteLength) break;
  }
  return out;
}

// ── Extraction ──────────────────────────────────────────────────────────────

const ENTITIES: Record<string, string> = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  apos: "'",
  nbsp: " ",
  laquo: "«",
  raquo: "»",
  hellip: "…",
  mdash: "—",
  ndash: "–",
  rsquo: "’",
  lsquo: "‘",
  rdquo: "”",
  ldquo: "“",
  eacute: "é",
  egrave: "è",
  agrave: "à",
  ccedil: "ç",
  ecirc: "ê",
  ocirc: "ô",
  ugrave: "ù",
};

export function decodeEntities(s: string): string {
  return s.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (m, body: string) => {
    if (body[0] === "#") {
      const code =
        body[1]?.toLowerCase() === "x" ? parseInt(body.slice(2), 16) : parseInt(body.slice(1), 10);
      return Number.isFinite(code) && code > 0 && code < 0x110000 ? String.fromCodePoint(code) : m;
    }
    return ENTITIES[body.toLowerCase()] ?? m;
  });
}

function meta(html: string, attr: "property" | "name", key: string): string | null {
  // Les deux ordres d'attributs existent dans la nature.
  const re1 = new RegExp(`<meta[^>]+${attr}=["']${key}["'][^>]*content=["']([^"']*)["']`, "i");
  const re2 = new RegExp(`<meta[^>]+content=["']([^"']*)["'][^>]*${attr}=["']${key}["']`, "i");
  const m = re1.exec(html) ?? re2.exec(html);
  const value = m?.[1] ? decodeEntities(m[1]).trim() : "";
  return value || null;
}

const BLOCK_TAG =
  /<\/?(?:p|div|li|ul|ol|h[1-6]|tr|td|th|table|section|article|main|blockquote|pre|dd|dt|dl|figcaption|figure|br|hr)\b[^>]*>/gi;

function stripTags(fragment: string): string {
  // Les balises de bloc valent un retour à la ligne, les balises en ligne
  // (a, em, span…) disparaissent sans casser le mot ou la ponctuation.
  return decodeEntities(fragment.replace(BLOCK_TAG, "\n").replace(/<[^>]+>/g, ""))
    .replace(/[ \t\r\f\v]+/g, " ")
    .replace(/ *\n */g, "\n")
    .replace(/\n{2,}/g, "\n")
    .trim();
}

const NOISE_TAGS = [
  "script",
  "style",
  "noscript",
  "svg",
  "template",
  "iframe",
  "nav",
  "header",
  "footer",
  "aside",
  "form",
];

/** Extrait titre, métadonnées et texte principal. Pure et testable. */
export function extractContent(html: string, finalUrl: string): PageContent {
  let cleaned = html;
  for (const tag of NOISE_TAGS) {
    cleaned = cleaned.replace(new RegExp(`<${tag}\\b[\\s\\S]*?<\\/${tag}>`, "gi"), " ");
  }
  cleaned = cleaned.replace(/<!--[\s\S]*?-->/g, " ");

  const rawTitle = /<title[^>]*>([\s\S]*?)<\/title>/i.exec(cleaned)?.[1];
  const ogTitle = meta(cleaned, "property", "og:title");
  const title = ogTitle ?? (rawTitle ? stripTags(rawTitle) : null);
  const description =
    meta(cleaned, "property", "og:description") ?? meta(cleaned, "name", "description");
  const siteName = meta(cleaned, "property", "og:site_name");
  const lang = /<html[^>]*\blang=["']?([a-zA-Z-]{2,8})/i.exec(html)?.[1]?.toLowerCase() ?? null;

  const main =
    /<article\b[^>]*>([\s\S]*?)<\/article>/i.exec(cleaned)?.[1] ??
    /<main\b[^>]*>([\s\S]*?)<\/main>/i.exec(cleaned)?.[1] ??
    /<body\b[^>]*>([\s\S]*?)<\/body>/i.exec(cleaned)?.[1] ??
    cleaned;
  let text = stripTags(main);
  if (text.length > MAX_CHARS) text = `${text.slice(0, MAX_CHARS)}…`;

  return { finalUrl, title: title || null, description, siteName, lang, text };
}

// ── Sources particulières ───────────────────────────────────────────────────

/**
 * X ne sert pas le contenu d'un post au HTML brut. Son endpoint oEmbed public
 * (sans clé) renvoie en revanche le texte du post : on le tente d'abord.
 */
export async function fetchXPost(
  url: string,
  fetchFn: typeof fetch,
  signal?: AbortSignal,
): Promise<PageContent | null> {
  const res = await fetchFn(
    `https://publish.twitter.com/oembed?omit_script=1&url=${encodeURIComponent(url)}`,
    {
      headers: { accept: "application/json", "user-agent": USER_AGENT },
      ...(signal ? { signal } : {}),
    },
  ).catch(() => null);
  if (!res || !res.ok) return null;
  const body = (await res.json().catch(() => null)) as {
    html?: string;
    author_name?: string;
  } | null;
  if (!body?.html) return null;
  const text = stripTags(body.html.replace(/<a[^>]*>\s*pic\.twitter\.com[^<]*<\/a>/gi, ""));
  if (!text) return null;
  const author = body.author_name ?? null;
  return {
    finalUrl: url,
    title: author ? `${author} sur X` : "Post X",
    description: null,
    siteName: "X",
    lang: null,
    text,
  };
}

/** Point d'entrée du pipeline : choisit la stratégie selon la source. */
export async function scrape(url: string, opts: ScrapeOptions): Promise<PageContent> {
  if (detectSource(url) === "x") {
    const post = await fetchXPost(url, opts.fetch ?? fetch);
    if (post) return post;
  }
  const { finalUrl, html } = await safeFetch(url, opts);
  return extractContent(html, finalUrl);
}
