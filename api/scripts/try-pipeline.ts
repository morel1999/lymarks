/* eslint-disable no-console -- outil en ligne de commande */
// Essai réel du pipeline (scrape → résumé → embedding) sur une URL, avec les
// clés de `.dev.vars`. Usage : `npx tsx scripts/try-pipeline.ts <url>`.
// Ne touche pas à la base ; n'affiche jamais une clé.

import { readFileSync } from "node:fs";
import { GeminiEmbedder, embeddingInput } from "../src/services/embedder.js";
import { scrape } from "../src/services/scraper.js";
import { dohResolver } from "../src/services/ssrf.js";
import { ChatSummarizer, geminiChatProvider, groqProvider } from "../src/services/summarizer.js";

const vars = Object.fromEntries(
  readFileSync(new URL("../.dev.vars", import.meta.url), "utf8")
    .split(/\r?\n/)
    .filter((l) => /^[A-Z_]+=/.test(l))
    .map((l) => {
      const i = l.indexOf("=");
      return [
        l.slice(0, i),
        l
          .slice(i + 1)
          .replace(/^"|"$/g, "")
          .trim(),
      ];
    }),
);
const toml = readFileSync(new URL("../wrangler.toml", import.meta.url), "utf8");
const model = (key: string): string =>
  toml.match(new RegExp(`^${key} = "([^"]+)"`, "m"))?.[1] ?? "";

const url = process.argv[2];
if (!url) throw new Error("URL manquante");

const t0 = Date.now();
const page = await scrape(url, { resolve: dohResolver(), timeoutMs: 10_000 });
console.log(
  `scrape ${Date.now() - t0} ms : titre=${JSON.stringify(page.title)} texte=${page.text.length} car.`,
);

const only = process.argv[3]; // "groq" | "gemini" | vide = chaîne complète
const providers = [
  groqProvider(vars.GROQ_API_KEY!, model("GROQ_MODEL")),
  geminiChatProvider(vars.GEMINI_API_KEY!, model("GEMINI_SUMMARY_MODEL")),
].filter((p) => !only || p.name === only);
const summarizer = new ChatSummarizer({
  providers,
  retryDelayMs: 500,
  log: (e) => console.log("  log", JSON.stringify(e)),
});
const t1 = Date.now();
const summary = await summarizer.summarize({ title: page.title, content: page.text });
console.log(`résumé ${Date.now() - t1} ms :`, JSON.stringify(summary, null, 1));

const embedder = new GeminiEmbedder({
  apiKey: vars.GEMINI_API_KEY!,
  model: model("GEMINI_EMBEDDING_MODEL"),
});
const t2 = Date.now();
const vec = await embedder.embed(embeddingInput(page.title, summary.bullets), "RETRIEVAL_DOCUMENT");
const norm = Math.sqrt(vec.reduce((a, x) => a + x * x, 0));
console.log(`embedding ${Date.now() - t2} ms : ${vec.length} dims, norme ${norm.toFixed(4)}`);
