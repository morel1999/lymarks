# Test Strategy — Lymarks

> **But :** quoi tester, comment, et ce qui bloque une release. · **Statut :** vivant · **Màj :** 2026-08-07

## Pyramide
| Niveau | Outils | Périmètre prioritaire |
|---|---|---|
| Unitaires API | Vitest | Scraper (parsing, filtres SSRF), validation Zod, scoring digest, fusion recherche |
| Unitaires app | flutter_test | Modèles, providers, formatage des cartes |
| Intégration API | Vitest + mocks Groq/Gemini + branch Neon de test | Pipeline complet ingestion ; cas : page OK / paywall / JS-only / 404 / >8k tokens / doublon |
| Sécurité | Vitest (suites dédiées) | M1 : URLs SSRF (IP privées, redirections) rejetées · M2 : page « ignore instructions » → JSON conforme quand même · M5/M6 : bypass paywall et IDOR impossibles |
| E2E manuel (checklist) | Devices réels iOS + Android | Partage depuis X, Safari, Chrome, YouTube, LinkedIn ; achat sandbox + restore ; suppression de compte ; hors-ligne |
| Prompts | Jeu de 15 pages fixes | Rejoué à chaque nouvelle version de prompt (AI Architecture §3) |

## Gates CI (bloquants)
lint = 0 erreur · tests unitaires+intégration verts · GitLeaks propre · suites sécurité M1/M2/M5/M6 vertes.

## Ce qu'on ne teste PAS en V1 (assumé)
UI automatisée (golden tests), charge (l'edge encaisse largement l'échelle Shipaton), compatibilité exotique (matrice = 2 devices récents + 2 anciens).
