# Software Architecture Document (SAD) — Lymarks

> **But :** carte des composants, flux, et specs des modules. · **Statut :** vivant · **Màj :** 2026-08-07

## Vue d'ensemble

```
[App Flutter] ──(share intent)── [Share Extension iOS/Android]
      │                                  │
      └────────── HTTPS + JWT Clerk ─────┘
                        │
              [API Hono @ Cloudflare Workers]
                        │  (waitUntil / Queues pour l'async)
   ┌───────────┬────────┼─────────────┬──────────────┐
[Scraper]  [Summarizer] [Embedder]  [Neon Postgres] [Push]
(fetch +    (Groq        (Gemini     (+ pgvector)   (FCM/APNs)
Readability) Llama 3.3)  emb-004)
```

Auth : **Clerk** (JWT vérifié par middleware Hono via JWKS). Monétisation : **RevenueCat** (webhook → table `subscriptions`).

## Flux 1 — Ingestion d'un lymark
1. Share extension → `POST /bookmarks` `{url, note?}` (JWT).
2. L'API répond **201 immédiatement** (`status: processing`) puis continue en arrière-plan (`ctx.waitUntil`). ⚠️ À décider : passage à Cloudflare Queues si les timeouts Workers posent problème sur les grosses pages.
3. Scraper : fetch de l'URL (protections SSRF, voir Security §3) → extraction texte (Readability-like), tronqué à ~8 000 tokens.
4. Summarizer : Groq → `{bullets[3], keywords[], lang}` (JSON strict).
5. Embedder : Gemini `text-embedding-004` sur `titre + puces + note` → vector(768).
6. UPDATE du bookmark → `status: ready` (ou `partial`/`failed`).

## Flux 2 — Recherche
`GET /search?q=` → si plan Free : plein texte Postgres (`tsvector` ou `ILIKE` V1). Si Pro : embedding de la requête (Gemini) + `ORDER BY embedding <=> $1` (cosinus, index HNSW) fusionné avec le plein texte (score pondéré 0,7 sémantique / 0,3 texte ⚠️ à calibrer).

## Flux 3 — Daily Digest
Cron Trigger Workers (toutes les 30 min) → sélectionne les utilisateurs Pro dont l'heure locale = heure choisie → algorithme de re-surfaçage (voir Knowledge Vault Spec §4) → push FCM/APNs. ⚠️ À décider : FCM seul (couvre iOS via APNs) — proposé pour n'avoir qu'un canal.

## Spécifications des modules

### M1 — Share Extension (Flutter + natif)
**Responsabilités :** intercepter URL+texte partagés, saisir la note, POST, se fermer. **Interfaces :** `receive_sharing_intent` ; `POST /bookmarks`. **Événements :** `share_received`, `bookmark_submitted`, `queued_offline`. **Tests :** partage depuis X, Safari, Chrome, YouTube, LinkedIn sur devices réels iOS et Android (cases limites : texte sans URL, multi-URL).

### M2 — Ingestion Pipeline (Workers)
**Responsabilités :** orchestrer scraper→LLM→embedding→DB ; idempotence par `(user_id, url_hash)` ; retries (1 retry Groq, puis `failed`). **Interfaces :** internes ; sortie = ligne `bookmarks`. **Tests :** mocks Groq/Gemini ; pages OK / paywall / JS-only / 404 / >8k tokens ; injection de prompt dans le contenu.

### M3 — Search Engine (Workers + Neon)
**Responsabilités :** requêtes texte + vectorielles, fusion, scoping strict par `user_id`. **Tests :** rappel sur jeu de 50 bookmarks de test ; latence P95 <800 ms.

### M4 — Digest Engine (Cron Workers)
**Responsabilités :** scoring, choix du lien, envoi push, journalisation `digests`. **Tests :** jamais 2 push/jour ; respect du fuseau ; opt-out effectif.

### M5 — Paywall & Entitlements (Flutter + Workers)
**Responsabilités :** afficher le paywall RevenueCat, refléter l'entitlement `pro` côté serveur (webhook), **appliquer les limites côté serveur**. **Tests :** achat sandbox, restore, expiration, tentative de bypass (appel direct API en Free au-delà de 30).

## Annexe — Stack technique et rôles
| Couche | Techno | Rôle | Version épinglée |
|---|---|---|---|
| Mobile | Flutter (Dart 3) | UI 60–120 FPS, share extension | ⚠️ fixer à J1 |
| Auth | Clerk | Comptes, OAuth Google/Apple, JWT | SDK stable courant |
| API | Hono (TS) sur Cloudflare Workers | Latence minimale, 0 ms cold start | idem |
| DB | Neon Postgres + pgvector | Données + vecteurs, branching dev/prod | pgvector ≥0.7 |
| LLM | Groq (Llama 3.3 70B) | Résumés 3 puces, extraction mots-clés | — |
| Embeddings | Gemini `text-embedding-004` | Vecteurs 768 d | — |
| Paiement | RevenueCat (`purchases_flutter`) | Abonnements, entitlements | — |
| Push | FCM (+APNs) | Digest | ⚠️ à décider |

Justification de chaque choix : voir `adr/`.
