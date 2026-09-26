# Store Compliance Spec — Lymarks

> **Purpose:** pass Apple/Google reviews on the first attempt. Risk #1 for the store-launch deadline. · **Status:** living · **Updated:** 2026-09-17

> **V1.0 = Google Play only** (ADR-007). The Apple section is frozen until V1.1.

> ⚠️ **Post-Shipaton — future work.** This checklist applies to the store launch (V1.0 on Google Play, V1.1 on the App Store), not to the current Shipaton Next Gen submission, which requires no developer account.

## Apple App Store — V1.1
- [ ] **IAP only** for Pro (RevenueCat ✔), no external purchase link.
- [ ] **Sign in with Apple** offered (Google present → mandatory).
- [ ] **In-app account deletion** accessible in ≤2 taps from settings (guideline 5.1.1(v)).
- [ ] **Privacy Nutrition Labels** compliant with the Privacy Spec (identifiers, user content; no third-party tracking).
- [ ] Share extension: lightweight, no misleading UI, App Group correctly configured.
- [ ] Guideline 4.2 (minimum value): the app alone must demonstrate the full loop in review → provide a **pre-filled demo account** in review notes.
- [ ] Notifications permission requested **in context** (digest activation), never at first launch.

## Google Play — V1.0
- [ ] **Data Safety form** aligned with the Privacy Spec.
- [ ] **In-app account deletion** + web deletion URL declared in the console (required since 2024 for any app with account creation).
- [ ] Play Billing via RevenueCat ✔; App Signing by Google Play.
- [ ] Demo account in review notes; current API level required by Play.
- [ ] Privacy policy hosted (public URL) ⚠️ to create before D13 (generated from the Privacy Spec).

## Classic rejection causes anticipated
Crash on first launch (E2E checklist), paywall without restore (✔ planned), account deletion absent (✔ P0-F7), metadata mentioning other platforms, notification permission unjustified (✔ in context).

- [ ] **Clerk production**: allowlist `lymarks://oauth/oauth_google` on the prod instance (`clerk api /redirect_urls --instance prod`) and switch the app to `pk_live_…` — otherwise Google OAuth fails in production (ADR-010).
- [ ] **Release key**: create a release key (upload key) outside the repo, configure it as a CI secret (`ANDROID_KEYSTORE_B64`, passwords) and sign the release with it — current builds use `app/android/app/debug.keystore`, versioned, with no security value.
