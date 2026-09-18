// Pipeline d'ingestion : page OK / paywall (mince) / 404 / cache / embedding
// en panne / page fournie par le client (Test Strategy, intégration API).

import { describe, expect, it } from "vitest";
import type { Embedder } from "../src/services/embedder.js";
import { processBookmark, type PipelineDeps } from "../src/services/pipeline.js";
import { MAX_CHARS, ScrapeError, type PageContent } from "../src/services/scraper.js";
import type { Summarizer } from "../src/services/summarizer.js";
import { fakeEmbedding } from "./helpers/app.js";
import { MemoryDb } from "./helpers/memory-db.js";

const page = (over: Partial<PageContent> = {}): PageContent => ({
  finalUrl: "https://example.com/a",
  title: "Titre page",
  description: "Une description",
  siteName: null,
  lang: "fr",
  text: "Contenu ".repeat(100),
  imageUrl: "https://example.com/og.jpg",
  ...over,
});

function setup(
  opts: {
    scrape?: PipelineDeps["scrape"];
    summarize?: Summarizer["summarize"];
    embed?: Embedder["embed"];
  } = {},
) {
  const db = new MemoryDb();
  const calls = { scrape: 0, summarize: 0, embed: 0 };
  const deps: PipelineDeps = {
    db,
    scrapeOptions: { resolve: async () => ["93.184.216.34"] },
    scrape: async (url, o) => {
      calls.scrape += 1;
      return (opts.scrape ?? (async () => page()))(url, o);
    },
    summarizer: {
      summarize: async (input) => {
        calls.summarize += 1;
        return (
          opts.summarize ??
          (async () => ({
            bullets: ["Un", "Deux", "Trois"],
            keywords: ["k1", "k2"],
            lang: "fr",
            category: "development" as const,
          }))
        )(input);
      },
    },
    embedder: {
      embed: async (text, task) => {
        calls.embed += 1;
        return (opts.embed ?? (async (t: string) => fakeEmbedding(t)))(text, task);
      },
    },
    log: () => undefined,
  };
  return { db, deps, calls };
}

async function seed(
  db: MemoryDb,
  clerkId = "u1",
  url = "https://example.com/a",
  title: string | null = "Titre partagé",
) {
  const user = await db.users.create(clerkId);
  const row = await db.bookmarks.insert(user.id, {
    url,
    urlHash: `h:${url}`,
    source: "web",
    title,
    note: null,
  });
  return { user, row };
}

describe("processBookmark", () => {
  it("page OK → ready avec titre, 3 puces, mots-clés, catégorie, image, embedding", async () => {
    const { db, deps, calls } = setup();
    const { user, row } = await seed(db);
    const result = await processBookmark(deps, {
      id: row.id,
      url: row.url,
      urlHash: row.urlHash,
      title: row.title,
    });
    expect(result.status).toBe("ready");
    const saved = await db.bookmarks.get(user.id, row.id);
    expect(saved?.status).toBe("ready");
    expect(saved?.title).toBe("Titre page");
    expect(saved?.summary?.bullets).toEqual(["Un", "Deux", "Trois"]);
    expect(saved?.summary?.lang).toBe("fr");
    expect(saved?.keywords).toEqual(["k1", "k2"]);
    expect(saved?.category).toBe("development");
    expect(saved?.imageUrl).toBe("https://example.com/og.jpg");
    expect(saved?.embedding).toHaveLength(768);
    expect(calls).toEqual({ scrape: 1, summarize: 1, embed: 1 });
  });

  it("page mince (paywall, JS-only) → partial, résumé sur les métadonnées", async () => {
    let received = "";
    const { db, deps } = setup({
      scrape: async () => page({ text: "Abonnez-vous", description: "Résumé OG de l'article" }),
      summarize: async ({ content }) => {
        received = content;
        return { bullets: ["Depuis OG"], keywords: ["og"], lang: "fr", category: "other" };
      },
    });
    const { user, row } = await seed(db);
    const result = await processBookmark(deps, {
      id: row.id,
      url: row.url,
      urlHash: row.urlHash,
      title: row.title,
    });
    expect(result.status).toBe("partial");
    expect(received).toContain("Résumé OG de l'article");
    expect((await db.bookmarks.get(user.id, row.id))?.summary?.bullets).toEqual(["Depuis OG"]);
  });

  it("404 → failed avec la raison, titre du partage conservé, catégorie other", async () => {
    const { db, deps, calls } = setup({
      scrape: async () => {
        throw new ScrapeError("not_found", "HTTP 404");
      },
    });
    const { user, row } = await seed(db);
    await processBookmark(deps, {
      id: row.id,
      url: row.url,
      urlHash: row.urlHash,
      title: row.title,
    });
    const saved = await db.bookmarks.get(user.id, row.id);
    expect(saved?.status).toBe("failed");
    expect(saved?.failureReason).toBe("not_found");
    expect(saved?.title).toBe("Titre partagé");
    expect(saved?.category).toBe("other");
    expect(saved?.imageUrl).toBeNull();
    expect(calls.summarize).toBe(0);
  });

  it("résumeur à plat → failed summary_failed", async () => {
    const { db, deps } = setup({
      summarize: async () => {
        throw new Error("down");
      },
    });
    const { user, row } = await seed(db);
    await processBookmark(deps, {
      id: row.id,
      url: row.url,
      urlHash: row.urlHash,
      title: row.title,
    });
    expect((await db.bookmarks.get(user.id, row.id))?.failureReason).toBe("summary_failed");
  });

  it("embedding en panne → partial mais le résumé est gardé", async () => {
    const { db, deps } = setup({
      embed: async () => {
        throw new Error("quota");
      },
    });
    const { user, row } = await seed(db);
    await processBookmark(deps, {
      id: row.id,
      url: row.url,
      urlHash: row.urlHash,
      title: row.title,
    });
    const saved = await db.bookmarks.get(user.id, row.id);
    expect(saved?.status).toBe("partial");
    expect(saved?.summary?.bullets).toHaveLength(3);
    expect(saved?.embedding).toBeNull();
  });

  it("cache : la même page déjà résumée pour un autre utilisateur n'appelle ni scraper ni LLM", async () => {
    const { db, deps, calls } = setup();
    const a = await seed(db, "alice");
    await processBookmark(deps, {
      id: a.row.id,
      url: a.row.url,
      urlHash: a.row.urlHash,
      title: a.row.title,
    });
    const b = await seed(db, "bob", "https://example.com/a", null);
    const result = await processBookmark(deps, {
      id: b.row.id,
      url: b.row.url,
      urlHash: b.row.urlHash,
      title: null,
    });
    expect(result.status).toBe("ready");
    expect(calls).toEqual({ scrape: 1, summarize: 1, embed: 1 });
    const saved = await db.bookmarks.get(b.user.id, b.row.id);
    expect(saved?.title).toBe("Titre page");
    expect(saved?.summary?.bullets).toEqual(["Un", "Deux", "Trois"]);
    // La catégorie et l'image voyagent avec le résumé.
    expect(saved?.category).toBe("development");
    expect(saved?.imageUrl).toBe("https://example.com/og.jpg");
  });

  it("page fournie par le client : pas de scrape, ready avec catégorie et image", async () => {
    let received: { title: string | null; content: string } | null = null;
    const { db, deps, calls } = setup({
      summarize: async (input) => {
        received = input;
        return { bullets: ["A", "B", "C"], keywords: ["k"], lang: null, category: "science" };
      },
    });
    const { user, row } = await seed(db);
    const result = await processBookmark(deps, {
      id: row.id,
      url: row.url,
      urlHash: row.urlHash,
      title: row.title,
      page: {
        title: "Lu par le téléphone",
        description: null,
        text: "Texte lu côté client. ".repeat(20),
        lang: "en-GB",
        imageUrl: "https://example.com/phone.jpg",
      },
    });
    expect(calls).toEqual({ scrape: 0, summarize: 1, embed: 1 });
    expect(received).toMatchObject({ title: "Lu par le téléphone" });
    expect(result.status).toBe("ready");
    expect(await db.bookmarks.get(user.id, row.id)).toMatchObject({
      status: "ready",
      title: "Lu par le téléphone",
      category: "science",
      imageUrl: "https://example.com/phone.jpg",
      summary: { bullets: ["A", "B", "C"], lang: "en" },
    });
  });

  it("page fournie : le cache inter-utilisateurs passe avant, le texte est tronqué au budget du scraper", async () => {
    let received = "";
    const { db, deps, calls } = setup({
      summarize: async ({ content }) => {
        received = content;
        return { bullets: ["A"], keywords: [], lang: "fr", category: "other" };
      },
    });
    const { row } = await seed(db);
    const provided = { title: null, description: null, lang: null, imageUrl: null };
    await processBookmark(deps, {
      id: row.id,
      url: row.url,
      urlHash: row.urlHash,
      title: row.title,
      page: { ...provided, text: "x".repeat(40_000) },
    });
    expect(received.length).toBe(MAX_CHARS + 1);
    expect(received.endsWith("…")).toBe(true);

    // Résumé déjà en base pour cette URL : la page fournie n'est même pas lue.
    const other = await seed(db, "bob", "https://example.com/a", null);
    await processBookmark(deps, {
      id: other.row.id,
      url: other.row.url,
      urlHash: other.row.urlHash,
      title: null,
      page: { ...provided, text: "autre texte" },
    });
    expect(calls.summarize).toBe(1);
  });
});
