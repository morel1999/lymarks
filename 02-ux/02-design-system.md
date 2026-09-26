# Design System — Lymarks

> **Purpose:** UI rules, tokens and Flutter components. · **Status:** living · **Updated:** 2026-09-22

Base: **Material 3** (Flutter), customised by the tokens below. Native dark mode from V1.0 (follows the system).

## Tokens

### Colours — midnight blue and chrome

Identity finalised on **22/09/2026**, replacing the original purple. The source of truth is `app/lib/core/theme/app_colors.dart` (`LyPalette`); the table below reflects it, not the other way around.

| Token | Light | Dark | Usage |
|---|---|---|---|
| `primary` | #1A3E72 | #7FA9E8 | Actions, active links, summary bullets |
| `onPrimary` / `primarySoft` | #FFFFFF / #E4ECF9 | #06152A / #132339 | Text on primary, soft backgrounds |
| `gradientTop` → `gradientBottom` | #0D1F3C → #23508F | #08142A → #1B4275 | `primaryGradient`, diagonal |
| `chrome` / `chromeSoft` / `chromeDeep` | #94A3B8 / #E8EDF4 / #56637A | #8593A8 / #D6DEEA / #414D60 | `chromeGradient` |
| `surface` / `card` / `cardBorder` | #F6F8FC / #FFFFFF / #E3E9F2 | #060A12 / #0E1520 / #1C2634 | Backgrounds |
| `navSurface` | #E9EFF9 | #0F1A2E | Navigation bar |
| `success` / `warning` / `danger` | #0E9E76 / #E39A0B / #E04A4A | #2CC79C / #F0B429 / #F0716E | Pipeline states |
| `textPrimary` / `textSecondary` | #0A101C / #5B6678 | #EDF1F8 / #94A1B4 | Text |

**Where the gradient is allowed:** only on surfaces that carry the identity — the profile header today. A content card never takes the gradient: it belongs to its category, therefore to its accent.

**Chrome dose:** dividers, exception borders, and **Pro badges** (paywall, profile header). Never a solid background, never a text colour. Metal signals what is paid; using it elsewhere would void the signal.

**Category accents** (5 families, `fill` / `strong` / `onFill`, drawn deterministically by `accentFor`): `lime`, `blue` (pale cyan), `steel`, `yellow`, `pink`. `steel` (#E5E9F0 / #64748B) replaces the purple `lavender` family — it is the theme's steel.

### Spacing & radii
4 pt grid: `xs 4 · s 8 · m 12 · l 16 · xl 24 · xxl 32`. Radii: cards 16, bottom sheets 24 (top), buttons 12. Screen margins: 16.

### Typography
`Inter`, **variable version**: one file (876 KB) instead of four static weights (1.3 MB), carrying two axes.

- `wght` 100→900, continuous. Used values stay on the scale below, but an extra weight no longer costs a file.
- `opsz` 14→32, **optical size**, locked to text size: large sizes tighten and gain contrast, small sizes open up and space out. A 34px title and a 12px date are no longer the same drawing scaled up or down.

Scale: display 28/bold (onboarding), title 20/semibold, body 15/regular, caption 12/**regular**. Line height **1.5 for body** (long text breathes; the air between lines is perceived before the letter shapes), 1.2–1.3 for headings and labels. The 3 summary bullets: body, `•` bullets in `primary`.

Caption is regular not medium: these lines — domain, date, chips — accompany, they do not demand. The secondary grey already carried the visual step back; adding weight would contradict it.

### Animations
Standard 120 ms `easeOut` (tap, hover); lists 200 ms `easeInOutCubic`; `processing` skeleton: shimmer 1.2 s loop. No animation >250 ms.

## Components
- **BookmarkCard**: favicon+domain, title (2 lines max), 3 bullets, personal note in italics if present, tag row (12px chips), ⋯ menu (open, copy, delete). Variants: `processing` (shimmer), `partial` (badge "limited summary"), `failed` (retry button).
- **DigestCard**: `accent` 8% tinted background, "Resurfaced · saved N days ago" label, Read / Snooze / Archive actions.
- **SearchField**: sticky at top, ✨ icon when the query goes semantic (Pro).
- **PaywallSheet**: RevenueCat bottom sheet, 3 arguments, monthly/annual price, "Restore purchases" always visible.
- **ShareSheetView (extension)**: as light as possible — detected page title, 1-line extensible note field, full-width Save button. No images, no list.

## Iconography
Lucide (via `lucide_flutter`) size 20/24, stroke 1.75. No emojis in the system UI (allowed in user notes).
