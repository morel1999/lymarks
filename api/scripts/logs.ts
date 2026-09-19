/* eslint-disable no-console -- outil en ligne de commande */
// Journaux du Worker en prod (Workers Observability), sans tableau de bord.
//
//   npx tsx scripts/logs.ts [motif] [minutes]
//   npx tsx scripts/logs.ts revenuecat_webhook 30
//
// Lit CLOUDFLARE_API_TOKEN et CLOUDFLARE_ACCOUNT_ID dans `.dev.vars` (jamais
// affichés). Un événement par ligne : heure, puis le message ou le JSON
// structuré tel que `log()` l'a émis. Le motif filtre sur le texte de la
// ligne, côté serveur.

import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const vars = Object.fromEntries(
  readFileSync(resolve(import.meta.dirname, "..", ".dev.vars"), "utf8")
    .split(/\r?\n/)
    .filter((l) => l && !l.startsWith("#") && l.includes("="))
    .map((l) => {
      const i = l.indexOf("=");
      return [
        l.slice(0, i).trim(),
        l
          .slice(i + 1)
          .trim()
          .replace(/^["']|["']$/g, ""),
      ];
    }),
);
const token = vars["CLOUDFLARE_API_TOKEN"];
const account = vars["CLOUDFLARE_ACCOUNT_ID"];
if (!token || !account)
  throw new Error("CLOUDFLARE_API_TOKEN / CLOUDFLARE_ACCOUNT_ID absents de .dev.vars");

const pattern = process.argv[2] ?? "";
const minutes = Number(process.argv[3] ?? "30");
const now = Date.now();

const filters: unknown[] = [
  { key: "$metadata.service", operation: "eq", value: "lymarks-api", type: "string" },
];
if (pattern)
  filters.push({ key: "$metadata.message", operation: "includes", value: pattern, type: "string" });

const res = await fetch(
  `https://api.cloudflare.com/client/v4/accounts/${account}/workers/observability/telemetry/query`,
  {
    method: "POST",
    headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
    body: JSON.stringify({
      queryId: "lymarks-logs",
      timeframe: { from: now - minutes * 60_000, to: now },
      parameters: { datasets: ["cloudflare-workers"], filters, limit: 100 },
      view: "events",
    }),
  },
);
if (!res.ok) throw new Error(`HTTP ${res.status}: ${(await res.text()).slice(0, 300)}`);

interface Event {
  timestamp: number;
  $metadata?: { message?: string; level?: string; type?: string };
  $workers?: { outcome?: string; event?: { response?: { status?: number } } };
  source?: unknown;
}
const body = (await res.json()) as { result?: { events?: { events?: Event[] } } };
const events = body.result?.events?.events ?? [];
for (const e of [...events].sort((a, b) => a.timestamp - b.timestamp)) {
  const time = new Date(e.timestamp).toISOString().slice(11, 19);
  const message = e.$metadata?.message ?? "";
  // Une requête (`cf-worker-event`) : statut et issue ; un `log()` : ses champs.
  const status = e.$workers?.event?.response?.status;
  const tail =
    status !== undefined
      ? `→ ${status} ${e.$workers?.outcome ?? ""}`
      : typeof e.source === "object" && e.source && JSON.stringify(e.source) !== "{}"
        ? JSON.stringify(e.source)
        : "";
  console.log(`${time} ${e.$metadata?.level ?? ""} ${message} ${tail}`.trimEnd());
}
if (events.length === 0)
  console.log(`(aucun événement sur ${minutes} min${pattern ? ` pour « ${pattern} »` : ""})`);
