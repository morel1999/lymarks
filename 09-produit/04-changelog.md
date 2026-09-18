# Changelog — Lymarks

Format : [Keep a Changelog](https://keepachangelog.com/fr/) · versions sémantiques. **Statut :** vivant.

## [Unreleased]
### Added
- **App branchée sur l'API** : connexion Clerk (Google + e-mail, ADR-010), garde d'authentification, captures envoyées à `POST /bookmarks` avec file hors-ligne, liste et cartes rafraîchies pendant le traitement, recherche serveur, profil et plan réels, déconnexion et suppression de compte. Mode démo sans clé pour les tests. 37 tests + 15 rendus — 2026-09-18.
- **API Hono sur Workers** (`api/`) : capture avec anti-doublon et limites serveur, pipeline scraper → Groq → Gemini avec anti-SSRF et validation de format, recherche texte/hybride, profil, export, suppression de compte, webhook RevenueCat. 104 tests dont les suites sécurité M1/M2/M5/M6/M7. Migration 001, CI de déploiement, scan de secrets. **Déployée le 18/09** sur `lymarks-api.lymarks.workers.dev` (Neon eu-central-1, migration 001 appliquée, `/health` vert depuis un runner GitHub) — 2026-09-18.
- **Capture via le menu de partage Android** (F1) : activité translucide dédiée, feuille minimale, file locale hors-ligne, anti-doublon d'URL. Canal natif sans dépendance (ADR-008). **Validée sur device physique depuis Chrome** — 2026-09-18.
- App Flutter : design system (palette mesurée sur la Home), les 7 écrans sur données de démo, mode sombre, 23 tests dont 15 rendus de référence — 2026-09-04.
- Chaîne Android et build en CI (GitHub Actions) : analyse stricte, tests, APK release par architecture — 2026-09-17.
- **Premier APK installé et lancé sur un Android physique** (release arm64, 18,6 Mo) — 2026-09-17.
- Ensemble documentaire initial (docs/) — 2026-08-07.

### Changed
- Accès aux données en SQL brut, Drizzle écarté (ADR-009) — 2026-09-18.
- Périmètre V1.0 réduit à Android ; iOS reporté en V1.1 (ADR-007) — 2026-09-17.
