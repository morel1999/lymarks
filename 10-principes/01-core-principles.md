# Core Principles & Engineering Manifesto — Lymarks

> **Purpose:** the rules that do not change, even when the stack does. · **Status:** stable · **Updated:** 2026-08-07

1. **Capture never blocks the user.** All intelligence runs in the background; no feature may add friction to inflow.
2. **Security takes priority over speed** when a trade-off is required — including during a 14-day sprint.
3. **Rights are verified server-side.** The client displays; the server decides. No plan limit enforced in the app only.
4. **User data belongs to the user.** Full export and complete deletion functional at all times; the personal note never leaves our perimeter (never sent to LLMs).
5. **All third-party content is untrusted by default:** URLs (SSRF), web pages (prompt injection), webhooks (signature).
6. **The digest respects attention: 1 link per day, maximum.** No engagement notifications, no guilt-tripping, ever.
7. **Value is measured by outflow.** A feature that increases saves without improving search or re-surfacing is not a priority.
8. **Numbers before adjectives.** Every performance requirement or limit is a number written in a document, not a feeling.
9. **Modular architecture, replaceable pipeline.** Groq, Gemini or Neon may change; the module interfaces (SAD) stay.
10. **Every new feature goes through a Threat Model review** before it is coded.

Dependencies may change; these principles remain the foundation of every decision.
