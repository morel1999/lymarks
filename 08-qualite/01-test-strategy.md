# Test Strategy — Lymarks

> **Purpose:** what to test, how, and what blocks a release. · **Status:** living · **Updated:** 2026-08-07

## Pyramid
| Level | Tools | Priority scope |
|---|---|---|
| API unit tests | Vitest | Scraper (parsing, SSRF filters), Zod validation, digest scoring, search fusion |
| App unit tests | flutter_test | Models, providers, card formatting |
| API integration | Vitest + Groq/Gemini mocks + Neon test branch | Full ingestion pipeline; cases: OK / paywalled / JS-only / 404 / >8k tokens / duplicate |
| Security | Vitest (dedicated suites) | M1: SSRF URLs (private IPs, redirects) rejected · M2: "ignore instructions" page → conforming JSON anyway · M5/M6: paywall bypass and IDOR impossible |
| Manual E2E (checklist) | Real iOS + Android devices | Share from X, Safari, Chrome, YouTube, LinkedIn; sandbox purchase + restore; account deletion; offline |
| Prompts | Fixed 15-page set | Replayed on every new prompt version (AI Architecture §3) |

## CI gates (blocking)
lint = 0 errors · unit+integration tests green · GitLeaks clean · security suites M1/M2/M5/M6 green.

## What we do NOT test in V1 (accepted)
Automated UI (golden tests), load testing (the edge handles Shipaton scale easily), exotic compatibility (matrix = 2 recent + 2 older devices).
