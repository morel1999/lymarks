# Lymarks — Documentation projet

*Turn forgotten links into accessible active memory.* App mobile Flutter de bookmarks intelligents : capture <2 s, résumé IA en 3 puces, recherche sémantique, Daily Digest. Objectif : stores avant le **30/09/2026** (Shipaton).

## Index
| Dossier | Document | Rôle | Statut |
|---|---|---|---|
| 01-vision | product-vision · **prd** · roadmap | Pourquoi, quoi, quand | stable · vivant · vivant |
| 02-ux | ux-bible · design-system | Règles d'expérience et d'UI | stable · vivant |
| 03-architecture | sad (+modules +stack) · adr/ (7) | Comment c'est construit, et pourquoi | vivants |
| 04-securite | security-architecture · threat-model · privacy-spec | Défense et données personnelles | vivants |
| 05-data | knowledge-vault-spec · database-schema | Mémoire de connaissances et SQL | vivants |
| 06-ia | ai-architecture (+ prompts) | Modèles, orchestration, coûts | vivant |
| 07-dev | coding-standards (+ dépendances) | Conventions et registre des libs | vivant |
| 08-qualite | test-strategy · performance-budget | Ce qui bloque une release | vivants |
| 09-produit | release-plan · monetization-spec · store-compliance · changelog · risk-register | Sortie, revenus, risques | vivants |
| 10-principes | core-principles | Les règles qui ne changent pas | stable |

## Ordre de lecture conseillé
1. `01-vision/02-prd.md` — tout part de là. 2. `03-architecture/01-sad.md`. 3. `04-securite/02-threat-model.md`. 4. Le reste selon l'étape du sprint.

## Décisions récentes
- **2026-09-17 — Android seul en V1.0, iOS en V1.1** (ADR-007). Pas de Mac disponible ; deadline stores 30/09.

## Points ouverts (⚠️ à décider)
Recensés dans les documents : navigateur in-app, transcripts YouTube, fallback Gemini Flash, prix Pro et essai gratuit, Drizzle, Riverpod, FCM seul, export Free (RGPD), politique excédent au downgrade, notif discrète.
