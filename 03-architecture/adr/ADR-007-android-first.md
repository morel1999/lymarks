# ADR-007 — Android first, iOS in V1.1
**Status:** accepted · 2026-09-17
**Context:** the development machine runs Windows; no Mac, no iOS device. Yet an iOS build requires Xcode, therefore macOS, with no local workaround. The store deadline is 30/09/2026 (13 days). The Risk Register assumed a "real device from D3" (R3) without that device existing.
**Decision:** V1.0 targets **Android only** (Google Play). iOS moves to **V1.1**, with a Mac (second-hand or cloud rental) to provision beforehand.
**Alternatives:** second-hand Mac Mini right away (cost, delivery delay, still need to learn Xcode and App Groups in 13 days); hourly Mac cloud (MacinCloud, Codemagic — feasible but each share-extension iteration goes through a remote build, incompatible with "tackled from D3 on a real device"); deliver both by pushing the deadline (the Shipaton is dated).
**Consequences:**
- PRD: F5 drops "Apple Sign-In mandatory" in V1.0 (Google + email sufficient on Play); F7 stays P0 because Google Play has required it since 2024 for any app with account creation; the "iOS 16+" constraint becomes V1.1.
- Roadmap and Release Plan: step 2 = **Android** share (`receive_sharing_intent`, Intent `ACTION_SEND`); GO criteria reduced to Play only, 2 Android devices.
- Store Compliance: Apple section frozen, to be revisited in V1.1.
- Risk Register: R3 reformulated for Android; new R10 (no way to build iOS).
- What V1.1 will need to catch up on: Apple Sign-In, App Groups for the extension, Privacy Nutrition Labels, IAP Apple via RevenueCat.
- What does not change: the backend, the AI pipeline, the design system, all shared Flutter code.
