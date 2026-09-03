# Coding Standards & Dépendances — Lymarks

> **But :** conventions solo + dev assisté par IA, et registre des dépendances. · **Statut :** vivant · **Màj :** 2026-08-07

## 1. Structure du repo (monorepo)
```
lymarks/
├── app/        # Flutter
│   └── lib/{features,core,shared}/   # feature-first : capture/, library/, search/, digest/, paywall/
├── api/        # Hono + Workers
│   └── src/{routes,services,prompts,db}/
└── docs/       # ce dossier
```

## 2. Dart / Flutter
- Lint : `very_good_analysis` (strict). State management ⚠️ à décider — **proposition : Riverpod** (testable, simple à générer par IA).
- Modèles immuables (`freezed`), pas de logique dans les widgets, appels API isolés dans `core/api/`.
- Tout texte UI passe par l'i18n dès le départ (`flutter_localizations`, FR+EN).

## 3. TypeScript / API
- `strict: true`, ESLint + Prettier. Validation d'entrée systématique par **Zod** sur chaque route.
- Une route = un fichier ; services purs (scraper, summarizer, embedder) sans dépendance à Hono → testables unitairement.
- Aucune requête SQL hors de `src/db/` ; toute requête reçoit `userId` en paramètre explicite.

## 4. Commits, branches, CI
- Conventional Commits (`feat:`, `fix:`, `sec:`, `docs:`). Branche `main` protégée, déploiement uniquement via CI.
- CI (GitHub Actions) : lint → tests → scan secrets (GitLeaks) → deploy `wrangler` / build Flutter.
- Code généré par IA : relu ligne à ligne avant commit — le commit vaut approbation humaine.

## 5. Registre des dépendances
| Paquet | Rôle | Pourquoi lui | Risque / alternative |
|---|---|---|---|
| `receive_sharing_intent` | Share extension | Standard de fait Flutter | Maintenance variable → alternative : canal natif maison |
| `purchases_flutter` | RevenueCat | SDK officiel | Faible |
| `flutter_secure_storage` | Tokens | Keychain/Keystore | Faible |
| `freezed`, `riverpod` (⚠️) | Modèles / état | Écosystème mûr | Faible |
| `hono` | Framework API | Minimal, edge-first | Faible |
| `zod` | Validation | Standard TS | Faible |
| `drizzle-orm` + `@neondatabase/serverless` (⚠️) | DB | Compatible Workers | Alternative : SQL brut + `postgres.js` |
Règle : versions épinglées, lockfiles committés, revue des mises à jour **après** le Shipaton (aucun upgrade non indispensable pendant le sprint).
