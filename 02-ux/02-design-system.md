# Design System — Lymarks

> **But :** règles UI, tokens et composants Flutter. · **Statut :** vivant · **Màj :** 2026-08-07

Base : **Material 3** (Flutter), personnalisé par les tokens ci-dessous. Dark mode natif dès la V1.0 (suit le système).

## Tokens

### Couleurs (⚠️ palette proposée, à valider)
| Token | Light | Dark | Usage |
|---|---|---|---|
| `primary` | #4F46E5 (indigo) | #818CF8 | Actions, liens actifs |
| `surface` | #FAFAFA | #121212 | Fonds |
| `surfaceCard` | #FFFFFF | #1E1E1E | Cartes lymark |
| `accent` | #F59E0B (ambre) | #FBBF24 | Digest, re-surfaçage |
| `success` / `error` | #10B981 / #EF4444 | idem | États pipeline |
| `textPrimary` / `textSecondary` | #111827 / #6B7280 | #F3F4F6 / #9CA3AF | Textes |

### Espacement & rayons
Grille 4 pt : `xs 4 · s 8 · m 12 · l 16 · xl 24 · xxl 32`. Rayons : cartes 16, bottom sheets 24 (haut), boutons 12. Marges d'écran : 16.

### Typographie
`Inter` (ou système si poids d'app critique). Échelle : display 28/bold (onboarding), title 20/semibold, body 15/regular, caption 12/medium. Hauteur de ligne 1.4. Les 3 puces de résumé : body, puces `•` couleur `primary`.

### Animations
Standard 120 ms `easeOut` (tap, hover) ; listes 200 ms `easeInOutCubic` ; squelette `processing` : shimmer 1,2 s en boucle. Aucune animation >250 ms.

## Composants
- **BookmarkCard** : favicon+domaine, titre (2 lignes max), 3 puces, note perso en italique si présente, rangée de tags (chips 12), menu ⋯ (ouvrir, copier, supprimer). Variantes : `processing` (shimmer), `partial` (badge « résumé limité »), `failed` (bouton réessayer).
- **DigestCard** : fond teinté `accent` 8 %, mention « Refait surface · sauvegardé il y a N jours », actions Lire / Reporter / Archiver.
- **SearchField** : sticky en haut, icône ✨ quand la requête part en sémantique (Pro).
- **PaywallSheet** : bottom sheet RevenueCat, 3 arguments, prix mensuel/annuel, « Restaurer mes achats » toujours visible.
- **ShareSheetView (extension)** : la plus légère possible — titre de page détecté, champ note 1 ligne extensible, bouton Enregistrer pleine largeur. Aucune image, aucune liste.

## Iconographie
Lucide (via `lucide_flutter`) taille 20/24, trait 1,75. Pas d'emojis dans l'UI système (autorisés dans les notes utilisateur).
