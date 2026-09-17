# API Lymarks

Hono sur Cloudflare Workers, Neon Postgres + pgvector, Clerk, Groq, Gemini, RevenueCat. Architecture : `../03-architecture/01-sad.md`. Décisions : `../03-architecture/adr/`.

## Prérequis
Node ≥ 22. `npm install` dans ce dossier. Aucun Docker, aucune base locale : les tests tournent sur un dépôt en mémoire, la vraie base est une branche Neon.

## Secrets
1. `cp .dev.vars.example .dev.vars` (fait) et remplir chaque ligne — le fichier dit où trouver chaque clé et son format.
2. `.dev.vars` est ignoré par git. Ne jamais coller une clé dans une conversation, un ticket ou un commit.
3. En production, les mêmes noms deviennent des Workers Secrets, poussés par la CI depuis les *GitHub Secrets* (voir Déploiement).

## Commandes
| Commande | Rôle |
|---|---|
| `npm test` | 104 tests Vitest (services purs, routes sur dépôt mémoire, suites sécurité M1/M2/M5/M6/M7) |
| `npm run typecheck` | `tsc` strict, sources + tests + scripts |
| `npm run lint` / `npm run format` | ESLint + Prettier |
| `npm run check` | Tout ce qui précède : le gate de la CI |
| `npm run migrate` | Joue `migrations/*.sql` sur `DATABASE_URL` (env ou `.dev.vars`), une fois chacune |
| `npm run dev` | `wrangler dev` : API locale sur http://localhost:8787 avec les secrets de `.dev.vars` |
| `npm run deploy` | `wrangler deploy` — réservé à la CI (Coding Standards §4) |

## Routes
Toutes sous JWT Clerk (`Authorization: Bearer <token>`) sauf `/health` et le webhook.

| Méthode | Route | Rôle |
|---|---|---|
| GET | `/health` | `{ok, version, db}` — 503 si Neon ne répond pas |
| POST | `/bookmarks` | `{url, note?, title?}` → 201 `processing` + pipeline en arrière-plan ; 200 `duplicate: true` si l'URL existe ; 403 `limit_reached` (Free ≥ 30) ; 429 (> 30/h) |
| GET | `/bookmarks?limit=&before=&archived=&status=` | Liste antéchronologique, curseur `nextCursor` |
| GET | `/bookmarks/:id` | Fiche |
| PATCH | `/bookmarks/:id` | `{note?, archived?}` |
| DELETE | `/bookmarks/:id` | Suppression (embedding et digests compris) |
| POST | `/bookmarks/:id/opened` | Horodate l'ouverture (re-surfaçage) |
| POST | `/bookmarks/:id/retry` | Relance le pipeline depuis `failed`/`partial` → 202 |
| GET | `/bookmarks/:id/similar` | Top-3 par cosinus ≥ 0,75 |
| GET | `/search?q=&mode=text\|semantic&limit=` | Texte pour tous ; `semantic` → 403 `pro_required` en Free |
| GET | `/me` | `{plan, lymarkCount, lymarkLimit, tz, digestHour, digestOptin}` |
| PATCH | `/me` | `{tz?, digestHour?, digestOptin?}` — digest réservé Pro |
| GET | `/me/export` | Export JSON complet (portabilité, tous plans) |
| DELETE | `/me` | Purge Neon → Clerk → RevenueCat ; 204 |
| POST | `/webhooks/revenuecat` | En-tête `Authorization` = `REVENUECAT_WEBHOOK_SECRET` ; idempotent |

Erreurs : `{error: <code>, message, details?}`. Forme d'un lymark : `src/routes/serialize.ts` (miroir du modèle Dart).

## Pipeline d'ingestion
`POST /bookmarks` → 201 → `ctx.waitUntil` : cache par `url_hash` → scrape (anti-SSRF, DoH, 3 redirections max, 10 s, 2 Mo, HTML seulement ; oEmbed pour X) → Groq (retry + correction de format, puis Gemini Flash) → embedding Gemini 768 d → `ready` / `partial` / `failed` + `failure_reason`. La note utilisateur n'entre jamais dans un prompt.

## Déploiement (CI, `.github/workflows/api.yml`)
Sur push de `api/**` : `npm run check`. Le job `deploy` ne tourne que sur `master` **et** si les GitHub Secrets suivants existent :

`CLOUDFLARE_API_TOKEN` (jeton « Edit Cloudflare Workers »), `CLOUDFLARE_ACCOUNT_ID`, puis les mêmes noms que `.dev.vars` : `DATABASE_URL`, `CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY`, `GROQ_API_KEY`, `GEMINI_API_KEY`, `REVENUECAT_WEBHOOK_SECRET`, `REVENUECAT_API_KEY`.

Pour les pousser depuis `.dev.vars` sans les taper : `scripts/push-secrets.ps1` (lit le fichier, appelle `gh secret set` ligne par ligne, n'affiche rien). Le job joue ensuite les migrations, déploie, puis pousse les secrets Workers.

## Structure
```
src/
  index.ts          entrée Workers : env → dépendances → app
  app.ts            assemblage Hono (pur, testable)
  deps.ts           contrat des dépendances injectées
  middleware/       auth (Clerk/jose), erreurs
  routes/           une route = un fichier ; serialize.ts = DTO
  services/         url, ssrf, scraper, summarizer, embedder, pipeline, search, plan (purs)
  prompts/          summarize.v1.ts (versionné)
  db/               types.ts = contrat Db ; neon.ts = SQL brut (seul endroit avec du SQL)
migrations/         001_initial.sql …
scripts/            migrate.ts (Node), push-secrets.ps1
test/               vitest ; helpers/memory-db.ts = même contrat Db, en mémoire
```
