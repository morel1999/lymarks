# ADR-008 — Android share menu: custom native channel
**Status:** accepted · 2026-09-18
**Context:** F1 (capture via share menu) is the core of P0. The coding standards included `receive_sharing_intent`, with the caveat "variable maintenance → alternative: custom native channel", and the Risk Register R3 named that channel as Plan B. V1.0 scope is Android only (ADR-007).
**Decision:** a dedicated Kotlin `ShareActivity` (translucent, no back stack entry, no recents entry, no task affinity) hosting its own Flutter engine on the Dart entry point `shareMain`, and a two-method `MethodChannel` (`getShared`, `close`). No third-party dependency.
**Alternatives:** `receive_sharing_intent` — designed around iOS App Groups, heavy for Android alone, and it routes the share to `MainActivity`, which opens the app (contrary to UX Bible rule 2); a single activity with route detection — same app-opening problem, and the engine loads the full router and data.
**Consequences:**
- The "tap → close" path only loads the capture sheet: no router, no tabs, no demo data. `close` returns the duration measured since activity creation, logged against the <2 s budget.
- The sheet writes to a local queue (`capture_queue.json`, atomic write) that the main app drains at launch and on every foreground return — this is the PRD §3 "offline queue", even without a network and without a backend.
- URL duplicate (PRD §3): `saved_count` +1 and note replaced, no second lymark; minimal local normalisation pending the server `url_hash`.
- Product decisions made here, to confirm in the PRD: multiple URLs in one share → the first is saved and the user is notified; share without URL → explicit refusal ("No link in what you shared"), Lymarks saves links only.
- iOS (V1.1) will reuse the same Dart contract (`ShareHost`): the native extension will need to be written, but nothing on the sheet or queue side changes.
