# Performance Budget — Lymarks

> **But :** chiffres à tenir, mesurés, bloquants. · **Statut :** stable · **Màj :** 2026-08-07

| Métrique | Budget | Mesure |
|---|---|---|
| Capture : tap Partager → fermeture share sheet | **< 2 s** | Chrono manuel + trace, device milieu de gamme |
| Réponse `POST /bookmarks` (201) | < 300 ms P95 | Analytics Workers |
| Pipeline complet (processing → ready) | < 15 s P95 | Timestamps DB |
| Recherche plein texte | < 500 ms P95 | ressenti in-app |
| Recherche sémantique (embedding + pgvector) | < 800 ms P95 | idem |
| Framerate UI (scroll liste 200 cartes) | 60 FPS min, 0 jank visible | DevTools Flutter |
| Cold start app | < 2 s | device milieu de gamme |
| Taille app installée | < 40 MB | store listing |
| Notification digest | fenêtre ±15 min de l'heure choisie | logs cron |

Dépassement d'un budget = bug de priorité égale à un bug fonctionnel (règle Core Principles).
