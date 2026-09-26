# Risk Register — Lymarks

> **Purpose:** risks, probability (P), impact (I), mitigation. Scale 1–3. · **Status:** living · **Updated:** 2026-09-19

| ID | Risk | Cat. | P | I | Mitigation |
|---|---|---|---|---|---|
| R1 | ~~Store rejection → miss 30/09 deadline~~ — **closed 2026-09-19**: no store submission for the Shipaton; replaced by the Next Gen submission criteria (public repo + demo video + Devpost) | — | — | — | Closed |
| R2 | 14-day sprint unsustainable solo | Planning | 2 | 3 | Strict minimal P0, freeze at D11, P1 slippable to V1.1 (digest included) |
| R3 | Android share sheet finicky (Intent `ACTION_SEND`, text without URL, multi-URL) | Technical | 2 | 2 | Tackled from the start, physical device on USB, Plan B = custom native channel. iOS version (App Groups, extension memory) deferred to V1.1 |
| R4 | Poor extraction (X, JS pages, paywalls) | Technical | 3 | 2 | `partial` status accepted, OG metadata fallback, improvement in V1.1 |
| R5 | AI costs spiral with Free users | Financial | 1 | 2 | 30-lymark limit, rate limiting, url_hash cache, budget alerts at D1 |
| R6 | Scraping vs ToS of platforms (X, LinkedIn) | Legal | 2 | 2 | Simple fetch without auth bypass, identified User-Agent, robots.txt respect ⚠️ to decide, post-launch reassessment |
| R7 | Groq outage during sprint/launch | Technical | 1 | 2 | Gemini Flash fallback (AI Arch §1), clean `failed` status + retry |
| R8 | Bus factor = 1 (solo) | Organisation | 3 | 2 | This documentation; reproducible CI; secrets in a personal vault |
| R9 | API key leak | Security | 1 | 3 | Workers Secrets, GitLeaks CI, immediate rotation documented |
| R10 | No way to build iOS (no Mac, no device) → half the market absent at launch | Product | 3 | 2 | **Decision made (ADR-007): Android only in V1.0, iOS in V1.1.** Provision a Mac (second-hand or cloud) before opening V1.1; promise nothing about iOS on the store listing or website |
| R11 | Dev machine at **3.8 GB RAM** (measured 17/09: 0.4 GB free, 2.5 GB in swap). First Gradle build killed for lack of memory after 18 min | Organisation | 3 | 3 | **Android build in CI** (GitHub Actions, `.github/workflows/android.yml`) as the primary path; locally: Gradle at 1 GB without daemon, Kotlin in-process, VS Code and browser closed. No emulator, no Android Studio, no recursive scan |
| R12 | **`workers.dev` filtered by some ISPs** — observed 18/09: Türk Telekom "Güvenli İnternet" redirects HTTP to its block page and breaks TLS; dev machine cannot reach the API | Technical | 3 | 3 | Serve the API on a custom domain via a Cloudflare route (`api.<domain>`) before submission; in the meantime, prod tests from CI (`probe.yml`) |

Review: at the end of each sprint step (D2, D6, D10, D14).
