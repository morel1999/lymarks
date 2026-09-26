# Release Plan — Lymarks V1.0

> **Purpose:** milestones, freeze, go/no-go criteria, submission. · **Status:** living · **Updated:** 2026-09-17

> **V1.0 = Google Play only** (ADR-007).

> **Reorientation — 2026-09-19: store submission dropped for this deadline.** The sprint targets the **Next Gen** category of the Shipaton (demo video + open-source repository, no developer account required), whose third criterion out of four is thoughtful use of RevenueCat. The "Play submission" milestones and the review buffer below are therefore obsolete; what replaces them: public repository, README, LICENSE, two-minute video, and Devpost page before 30/09. The rest of this document still describes the store path, which will become relevant again for a real release.

## Milestones (14-day sprint — see Roadmap)
- **D1–D2** infra · **D3–D6** app+share · **D7–D10** AI+search · **D11** 🔒 **feature freeze** · **D11–D13** paywall, polish, manual E2E checklist, store assets · **D14** Google Play submission.
- Between submission and **30/09/2026**: review buffer (48 h to several days) + 1 absorbable rejection cycle (Risk R1).

## GO criteria for submission *(future: store launch)*
1. Manual E2E checklist 100% green on 2 physical Android devices (one recent, one Android 10).
2. CI gates green (Test Strategy); "capture <2 s" and "search <800 ms" performance budgets met.
3. Sandbox purchase + restore OK on Play Billing; account deletion functional.
4. Data Safety form filled in accordance with the Privacy Spec; Google Play Store Compliance checklist green.

## Versioning rules
`MAJOR.MINOR.PATCH` + auto build number. Every store submission = git tag + changelog entry. Post-launch hotfix: branch from the tag, patch only.
