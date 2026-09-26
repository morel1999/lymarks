# Performance Budget — Lymarks

> **Purpose:** numbers to meet, measured, blocking. · **Status:** stable · **Updated:** 2026-08-07

| Metric | Budget | Measurement |
|---|---|---|
| Capture: tap Share → share sheet closed | **< 2 s** | Manual stopwatch + trace, mid-range device |
| `POST /bookmarks` response (201) | < 300 ms P95 | Workers analytics |
| Full pipeline (processing → ready) | < 15 s P95 | DB timestamps |
| Full-text search | < 500 ms P95 | in-app feel |
| Semantic search (embedding + pgvector) | < 800 ms P95 | same |
| UI framerate (scroll of 200-card list) | 60 FPS min, 0 visible jank | Flutter DevTools |
| App cold start | < 2 s | mid-range device |
| Installed app size | < 40 MB | store listing |
| Digest notification | ±15 min window of chosen time | cron logs |

Exceeding a budget = bug of the same priority as a functional bug (Core Principles rule).
