# Design System — Lymarks

> **But :** règles UI, tokens et composants Flutter. · **Statut :** vivant · **Màj :** 2026-09-22

Base : **Material 3** (Flutter), personnalisé par les tokens ci-dessous. Dark mode natif dès la V1.0 (suit le système).

## Tokens

### Couleurs — bleu nuit et chrome

Identité arrêtée le **22/09/2026**, en remplacement du violet d'origine. La
source de vérité est `app/lib/core/theme/app_colors.dart` (`LyPalette`) ; le
tableau ci-dessous en est le reflet, pas l'inverse.

| Token | Light | Dark | Usage |
|---|---|---|---|
| `primary` | #1A3E72 | #7FA9E8 | Actions, liens actifs, puces de résumé |
| `onPrimary` / `primarySoft` | #FFFFFF / #E4ECF9 | #06152A / #132339 | Texte sur primaire, fonds doux |
| `gradientTop` → `gradientBottom` | #0D1F3C → #23508F | #08142A → #1B4275 | `primaryGradient`, diagonale |
| `chrome` / `chromeSoft` / `chromeDeep` | #94A3B8 / #E8EDF4 / #56637A | #8593A8 / #D6DEEA / #414D60 | `chromeGradient` |
| `surface` / `card` / `cardBorder` | #F6F8FC / #FFFFFF / #E3E9F2 | #060A12 / #0E1520 / #1C2634 | Fonds |
| `navSurface` | #E9EFF9 | #0F1A2E | Barre de navigation |
| `success` / `warning` / `danger` | #0E9E76 / #E39A0B / #E04A4A | #2CC79C / #F0B429 / #F0716E | États pipeline |
| `textPrimary` / `textSecondary` | #0A101C / #5B6678 | #EDF1F8 / #94A1B4 | Textes |

**Où le dégradé a le droit d'être** : seulement sur les surfaces qui portent
l'identité — en-tête du profil aujourd'hui. Une carte de contenu ne prend
jamais le dégradé : elle appartient à sa catégorie, donc à son accent.

**Dose de chrome** : filets, bordures d'exception et **pastilles Pro**
(paywall, en-tête du profil). Jamais un fond plein, jamais un texte. Le métal
signale ce qui est payant ; l'utiliser ailleurs viderait le signal.

**Accents de catégorie** (5 familles, `fill` / `strong` / `onFill`, tirées au
sort de façon déterministe par `accentFor`) : `lime`, `blue` (cyan pâle),
`steel`, `yellow`, `pink`. `steel` (#E5E9F0 / #64748B) remplace la famille
`lavender` violette — c'est l'acier du thème.

### Espacement & rayons
Grille 4 pt : `xs 4 · s 8 · m 12 · l 16 · xl 24 · xxl 32`. Rayons : cartes 16, bottom sheets 24 (haut), boutons 12. Marges d'écran : 16.

### Typographie
`Inter`, en **version variable** : un fichier (876 Ko) au lieu de quatre statiques (1,3 Mo), portant deux axes.

- `wght` 100→900, continu. Les valeurs employées restent celles de l'échelle ci-dessous, mais une graisse supplémentaire ne coûte plus un fichier.
- `opsz` 14→32, la **taille optique**, calée sur la taille du texte : les grandes tailles se resserrent et gagnent en contraste, les petites s'ouvrent et s'espacent. Un titre de 34 et une date de 12 ne sont plus le même dessin agrandi ou réduit.

Échelle : display 28/bold (onboarding), title 20/semibold, body 15/regular, caption 12/**regular**. Hauteur de ligne **1,5 pour le corps** (le texte long respire ; c'est l'air entre les lignes qu'on perçoit avant le dessin des lettres), 1,2 à 1,3 pour les titres et les libellés. Les 3 puces de résumé : body, puces `•` couleur `primary`.

La caption est en regular et non en medium : ces lignes — domaine, date, chips — accompagnent, elles ne réclament pas. Le gris secondaire portait déjà le retrait, la graisse le contredisait.

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
