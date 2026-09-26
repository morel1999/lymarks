# UX Bible — Lymarks

> **Purpose:** non-negotiable experience rules, valid for years. · **Status:** stable · **Updated:** 2026-08-07

## Hard rules
1. **Capture never blocks.** The share sheet closes on tap of Save (<2 s tap→close). No spinner waiting for the AI pipeline, ever.
2. **The user never leaves their environment.** Capture happens in the native share sheet; automatic return to the source app. The Lymarks app is never opened during a capture.
3. **Zero decisions forced at capture.** No folder, no required tag, no category. The note is optional. One single primary button.
4. **Processing is visible but not noisy.** In the app, a lymark in progress = an animated skeleton card that fills itself. No "your summary is ready" notification.
5. **Search is a single field.** No required filters, no syntax. Results <500 ms (full-text) / <800 ms (semantic).
6. **The digest respects attention.** 1 notification/day maximum, never two. Opt-out in 1 gesture from the notification. No marketing notifications.
7. **Every destructive action is reversible.** Lymark deletion = 5-second undo (snackbar). Exception: account deletion (explicit double confirmation).
8. **Animations <150 ms** for micro-interactions; 200–250 ms max for list transitions. Never an animation that makes the user wait.
9. **Never a full page for a simple action.** Notes, tags, digest snooze: bottom sheets. Full pages are reserved for reading a lymark and settings.
10. **Always return to the exact same place.** Scroll position, search query and tab are restored after navigation or app kill.
11. **The paywall never interrupts a capture.** The Free limit signals itself *after* the save (the 31st link is captured then held), never in the share sheet. ⚠️ TBD: "held" queue vs soft block — proposal: capture accepted + in-app banner.
12. **Empty is a designed state.** Empty list = mini capture tutorial (3 illustrated steps), not a blank screen.

## Tone and language
Sober interface, concrete vocabulary ("Saved", "1 forgotten link surfaced"). No gamification, no badges, no guilt-tripping ("you have 47 unread links" is forbidden).
