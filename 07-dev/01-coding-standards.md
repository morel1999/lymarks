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
- `strict: true` (+ `exactOptionalPropertyTypes`, `noUncheckedIndexedAccess`), ESLint + Prettier. Validation d'entrée systématique par **Zod** sur chaque route.
- Une route = un fichier ; services purs (scraper, summarizer, embedder) sans dépendance à Hono → testables unitairement.
- Aucune requête SQL hors de `src/db/` ; toute requête reçoit `userId` en paramètre explicite.

## 4. Commits, branches, CI
- Conventional Commits (`feat:`, `fix:`, `sec:`, `docs:`). Branche `main` protégée, déploiement uniquement via CI.
- CI (GitHub Actions) : `android.yml` (analyse, tests, APK), `api.yml` (typecheck, lint, tests, puis migrations + `wrangler deploy` + secrets Workers sur master si les GitHub Secrets existent), `secrets-scan.yml` (GitLeaks sur tout l'historique).
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
| `@neondatabase/serverless` | DB (pilote HTTP, SQL brut) | Compatible Workers, zéro ORM (ADR-009) | Faible |
| `jose` | Vérification JWT Clerk (JWKS) | Standard, tourne sur Workers | Faible |
Règle : versions épinglées, lockfiles committés, revue des mises à jour **après** le Shipaton (aucun upgrade non indispensable pendant le sprint).
