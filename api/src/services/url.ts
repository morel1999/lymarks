// Normalisation d'URL, empreinte et détection de la source.
//
// L'empreinte `url_hash` porte l'anti-doublon et l'idempotence (Database
// Schema, contrainte UNIQUE (user_id, url_hash)) ainsi que le cache de résumés
// entre utilisateurs (AI Architecture §2). Deux partages du « même » lien
// doivent donc produire la même empreinte : on retire ce qui ne change pas la
// page (fragment, paramètres de tracking, hôte mobile, ordre des paramètres).

import type { BookmarkSource } from "../db/types.js";

const TRACKING_PARAMS = new Set([
  "fbclid",
  "gclid",
  "dclid",
  "msclkid",
  "twclid",
  "igshid",
  "mc_cid",
  "mc_eid",
  "ref_src",
  "ref_url",
  "_ga",
  "_gl",
]);

/** Paramètres de partage propres à un hôte, sans effet sur le contenu. */
const HOST_PARAMS: Record<string, Set<string>> = {
  "x.com": new Set(["s", "t"]),
  "www.youtube.com": new Set(["si", "feature", "pp"]),
};

function canonicalHost(host: string): string {
  const h = host.toLowerCase().replace(/\.$/, "");
  if (
    h === "twitter.com" ||
    h === "www.twitter.com" ||
    h === "mobile.twitter.com" ||
    h === "www.x.com"
  ) {
    return "x.com";
  }
  if (h === "m.youtube.com" || h === "youtube.com" || h === "music.youtube.com") {
    return "www.youtube.com";
  }
  if (h.endsWith(".linkedin.com")) return "www.linkedin.com";
  return h;
}

/**
 * Retourne l'URL canonique, ou `null` si ce n'est pas une URL http(s) valide.
 * Ne fait aucune vérification de sécurité (voir ssrf.ts pour cela).
 */
export function normalizeUrl(input: string): string | null {
  let url: URL;
  try {
    url = new URL(input.trim());
  } catch {
    return null;
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") return null;
  if (url.username || url.password) return null;

  const host = canonicalHost(url.hostname);
  let pathname = url.pathname;
  const params = new URLSearchParams();

  // youtu.be/ID → www.youtube.com/watch?v=ID : même vidéo, même empreinte.
  let finalHost = host;
  if (host === "youtu.be") {
    const id = pathname.replace(/^\/+/, "").split("/")[0];
    if (!id) return null;
    finalHost = "www.youtube.com";
    pathname = "/watch";
    params.set("v", id);
  }

  const dropped = HOST_PARAMS[finalHost];
  const entries = [...url.searchParams.entries()].filter(([key]) => {
    const k = key.toLowerCase();
    if (k.startsWith("utm_")) return false;
    if (TRACKING_PARAMS.has(k)) return false;
    if (dropped?.has(k)) return false;
    return true;
  });
  entries.sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
  for (const [k, v] of entries) params.append(k, v);

  // Slash final retiré sauf sur la racine ; double slash compacté.
  pathname = pathname.replace(/\/{2,}/g, "/");
  if (pathname.length > 1 && pathname.endsWith("/")) pathname = pathname.slice(0, -1);

  const port =
    url.port &&
    !(
      (url.protocol === "https:" && url.port === "443") ||
      (url.protocol === "http:" && url.port === "80")
    )
      ? `:${url.port}`
      : "";
  const query = params.toString();
  return `${url.protocol}//${finalHost}${port}${pathname}${query ? `?${query}` : ""}`;
}

/** sha256 hexadécimal d'une URL déjà normalisée. */
export async function urlHash(normalized: string): Promise<string> {
  const bytes = new TextEncoder().encode(normalized);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** Domaine affiché par l'app (sans `www.`). */
export function domainOf(url: string): string {
  try {
    return new URL(url).hostname.replace(/^www\./, "");
  } catch {
    return url;
  }
}

export function detectSource(url: string): BookmarkSource {
  let host: string;
  try {
    host = new URL(url).hostname.toLowerCase();
  } catch {
    return "web";
  }
  if (
    host === "x.com" ||
    host.endsWith(".x.com") ||
    host === "twitter.com" ||
    host.endsWith(".twitter.com")
  ) {
    return "x";
  }
  if (host === "youtu.be" || host === "youtube.com" || host.endsWith(".youtube.com"))
    return "youtube";
  if (host === "linkedin.com" || host.endsWith(".linkedin.com")) return "linkedin";
  return "web";
}
