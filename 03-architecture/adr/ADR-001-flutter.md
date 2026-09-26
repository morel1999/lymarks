# ADR-001 — Flutter for mobile
**Status:** accepted · 2026-08-07
**Context:** iOS+Android app to deliver in 14 days by a solo dev; smooth UI (60–120 FPS) and share-menu integration required.
**Decision:** Flutter (Dart), with `receive_sharing_intent` for the share extension.
**Alternatives:** React Native (more fragmented share-extension ecosystem), native dual (impossible solo/14d), KMP (UI maturity).
**Consequences:** single codebase; vigilance on the native part of the iOS share extension (App Groups); app size to watch (budget <40 MB).
