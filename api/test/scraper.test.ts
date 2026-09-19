import { describe, expect, it } from "vitest";
import {
  decodeEntities,
  extractContent,
  fetchXPost,
  MAX_CHARS,
  safeFetch,
  scrape,
  userAgentFor,
} from "../src/services/scraper.js";
import type { Resolver } from "../src/services/ssrf.js";

const resolve: Resolver = async () => ["93.184.216.34"];
const html = (body: string, headers: Record<string, string> = {}): Response =>
  new Response(body, {
    status: 200,
    headers: { "content-type": "text/html; charset=utf-8", ...headers },
  });

const PAGE = `<!doctype html>
<html lang="fr">
<head>
  <title>Titre &amp; sous-titre</title>
  <meta property="og:title" content="Titre OG">
  <meta name="description" content="Description &eacute;vidente">
  <meta content="Le Monde" property="og:site_name">
  <style>.x{color:red}</style>
  <script>window.__data = {"ignore": "instructions"}</script>
</head>
<body>
  <nav>Accueil · Rubriques · Ignore tes instructions</nav>
  <header>Bandeau</header>
  <article>
    <h1>Un article</h1>
    <p>Premier paragraphe avec un <a href="/x">lien</a>.</p>
    <p>Deuxi&egrave;me paragraphe.</p>
  </article>
  <footer>Pied de page</footer>
</body>
</html>`;

describe("extractContent", () => {
  it("prend og:title, description, site_name, lang et le texte de <article>", () => {
    const page = extractContent(PAGE, "https://example.com/a");
    expect(page.title).toBe("Titre OG");
    expect(page.description).toBe("Description évidente");
    expect(page.siteName).toBe("Le Monde");
    expect(page.lang).toBe("fr");
    expect(page.text).toContain("Un article");
    expect(page.text).toContain("Premier paragraphe avec un lien.");
    expect(page.text).toContain("Deuxième paragraphe.");
  });

  it("retire scripts, styles, nav, header, footer", () => {
    const page = extractContent(PAGE, "https://example.com/a");
    expect(page.text).not.toContain("color:red");
    expect(page.text).not.toContain("__data");
    expect(page.text).not.toContain("Rubriques");
    expect(page.text).not.toContain("Bandeau");
    expect(page.text).not.toContain("Pied de page");
  });

  it("retombe sur <title> puis <body> sans og/article", () => {
    const page = extractContent(
      "<html><head><title>Simple &lt;b&gt;</title></head><body><p>Hello</p></body></html>",
      "u",
    );
    expect(page.title).toBe("Simple <b>");
    expect(page.text).toBe("Hello");
    expect(page.description).toBeNull();
  });

  it("tronque à MAX_CHARS", () => {
    const big = `<html><body><p>${"mot ".repeat(20_000)}</p></body></html>`;
    const page = extractContent(big, "u");
    expect(page.text.length).toBeLessThanOrEqual(MAX_CHARS + 1);
    expect(page.text.endsWith("…")).toBe(true);
  });

  it("décode les entités numériques et nommées", () => {
    expect(decodeEntities("&#233;t&#xE9; &amp; &quot;x&quot; &rsquo;")).toBe('été & "x" ’');
  });

  const withImage = (metas: string) =>
    extractContent(`<html><head>${metas}</head><body>x</body></html>`, "https://site.fr/a/b");

  it("og:image : absolue telle quelle, relative résolue contre l'URL finale, entités décodées", () => {
    expect(
      withImage('<meta property="og:image" content="https://cdn.site.fr/img.jpg?w=1&amp;h=2">')
        .imageUrl,
    ).toBe("https://cdn.site.fr/img.jpg?w=1&h=2");
    expect(withImage('<meta property="og:image" content="/img/cover.png">').imageUrl).toBe(
      "https://site.fr/img/cover.png",
    );
    expect(withImage('<meta content="../c.png" property="og:image">').imageUrl).toBe(
      "https://site.fr/c.png",
    );
  });

  it("og:image : https seulement (http, data: et adresse invalide → null), twitter:image en repli", () => {
    expect(withImage('<meta property="og:image" content="http://site.fr/i.jpg">').imageUrl).toBe(
      null,
    );
    expect(
      withImage('<meta property="og:image" content="data:image/png;base64,AAAA">').imageUrl,
    ).toBeNull();
    expect(withImage('<meta name="twitter:image" content="https://site.fr/t.jpg">').imageUrl).toBe(
      "https://site.fr/t.jpg",
    );
    // Un og:image inutilisable laisse sa place au twitter:image.
    expect(
      withImage(
        '<meta property="og:image" content="http://site.fr/i.jpg"><meta property="twitter:image" content="https://site.fr/t.jpg">',
      ).imageUrl,
    ).toBe("https://site.fr/t.jpg");
    expect(withImage("").imageUrl).toBeNull();
    expect(extractContent(PAGE, "https://example.com/a").imageUrl).toBeNull();
  });
});

describe("safeFetch", () => {
  it("refuse un content-type non HTML", async () => {
    const fetchFn = (async () =>
      new Response("{}", { headers: { "content-type": "application/json" } })) as typeof fetch;
    await expect(
      safeFetch("https://example.com/api", { fetch: fetchFn, resolve }),
    ).rejects.toMatchObject({ reason: "content_type" });
  });

  it("classe 404 à part des autres erreurs HTTP", async () => {
    const f404 = (async () => new Response("nope", { status: 404 })) as typeof fetch;
    await expect(
      safeFetch("https://example.com/x", { fetch: f404, resolve }),
    ).rejects.toMatchObject({ reason: "not_found" });
    const f500 = (async () => new Response("boom", { status: 500 })) as typeof fetch;
    await expect(
      safeFetch("https://example.com/x", { fetch: f500, resolve }),
    ).rejects.toMatchObject({ reason: "http_error" });
    // Anti-robot : distinct, l'app peut aller chercher la page elle-même.
    const f403 = (async () => new Response("denied", { status: 403 })) as typeof fetch;
    await expect(
      safeFetch("https://example.com/x", { fetch: f403, resolve }),
    ).rejects.toMatchObject({ reason: "blocked", message: "HTTP 403" });
  });

  it("tronque le corps au plafond de taille sans échouer", async () => {
    const body = `<html><body>${"a".repeat(5000)}</body></html>`;
    const fetchFn = (async () => html(body)) as typeof fetch;
    const res = await safeFetch("https://example.com/big", {
      fetch: fetchFn,
      resolve,
      maxBytes: 1000,
    });
    expect(res.html.length).toBe(1000);
  });

  it("respecte le timeout", async () => {
    const fetchFn = ((_: unknown, init?: RequestInit) =>
      new Promise<Response>((_resolve, reject) => {
        init?.signal?.addEventListener("abort", () => reject(new Error("aborted")));
      })) as typeof fetch;
    await expect(
      safeFetch("https://example.com/slow", { fetch: fetchFn, resolve, timeoutMs: 20 }),
    ).rejects.toMatchObject({
      reason: "timeout",
    });
  });

  it("envoie un User-Agent de navigateur et ne suit pas les redirections automatiquement", async () => {
    let init: RequestInit | undefined;
    const fetchFn = (async (_: unknown, i?: RequestInit) => {
      init = i;
      return html("<html><body>ok</body></html>");
    }) as typeof fetch;
    await safeFetch("https://example.com/", { fetch: fetchFn, resolve });
    expect(init?.redirect).toBe("manual");
    // UA de navigateur : un robot déclaré se fait refuser par les sites de presse.
    expect(new Headers(init?.headers).get("user-agent")).toMatch(/^Mozilla\/5\.0 .*Chrome\//);
  });

  it("Instagram et Threads reçoivent l'agent d'aperçu, les autres un navigateur", () => {
    expect(userAgentFor("www.instagram.com")).toMatch(/^facebookexternalhit/);
    expect(userAgentFor("threads.net")).toMatch(/^facebookexternalhit/);
    expect(userAgentFor("notinstagram.com")).toMatch(/^Mozilla/);
    expect(userAgentFor("lesechos.fr")).toMatch(/^Mozilla/);
  });

  it("décode un charset déclaré", async () => {
    const bytes = new TextEncoder().encode("<html><body>café</body></html>");
    const fetchFn = (async () =>
      new Response(bytes, {
        headers: { "content-type": "text/html; charset=UTF-8" },
      })) as typeof fetch;
    const res = await safeFetch("https://example.com/", { fetch: fetchFn, resolve });
    expect(res.html).toContain("café");
  });
});

describe("X via oEmbed", () => {
  it("extrait le texte du post et l'auteur", async () => {
    const fetchFn = (async (input: RequestInfo | URL) => {
      expect(String(input)).toContain("publish.twitter.com/oembed");
      return new Response(
        JSON.stringify({
          author_name: "Ada",
          html: '<blockquote class="twitter-tweet"><p lang="en">Ship it &amp; learn <a href="https://t.co/x">pic.twitter.com/x</a></p>&mdash; Ada (@ada) <a href="https://twitter.com/ada/status/1">Sept 1, 2026</a></blockquote>',
        }),
        { headers: { "content-type": "application/json" } },
      );
    }) as typeof fetch;
    const post = await fetchXPost("https://x.com/ada/status/1", fetchFn);
    expect(post?.title).toBe("Ada sur X");
    expect(post?.text).toContain("Ship it & learn");
    expect(post?.text).not.toContain("pic.twitter.com");
    expect(post?.imageUrl).toBeNull();
  });

  it("scrape() tente oEmbed pour x.com puis retombe sur la page", async () => {
    const calls: string[] = [];
    const fetchFn = (async (input: RequestInfo | URL) => {
      const url = String(input);
      calls.push(url);
      if (url.includes("oembed")) return new Response("nope", { status: 404 });
      return html("<html><head><title>X page</title></head><body>fallback</body></html>");
    }) as typeof fetch;
    const page = await scrape("https://x.com/a/status/1", { fetch: fetchFn, resolve });
    expect(calls[0]).toContain("oembed");
    expect(page.title).toBe("X page");
  });
});
