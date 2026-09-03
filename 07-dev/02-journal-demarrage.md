# Journal de démarrage — app Flutter

> **But :** tracer les décisions prises au démarrage du code, et tout écart assumé vis-à-vis des documents. · **Statut :** vivant · **Màj :** 2026-09-04

Étape 2 de la roadmap (« Core Flutter ») démarrée avant l'étape 1 (« Infra cloud »), qui exige des comptes Neon / Clerk / Cloudflare non provisionnables sans accès. L'app tourne donc sur données mock ; aucun écran ne dépend de `MockData` autrement que par les providers, le branchement API est un remplacement de providers.

## 1. Décisions verrouillées (levées de ⚠️)

| Point | Décision | Raison |
|---|---|---|
| State management | **Riverpod** (`flutter_riverpod` 2.6) | Proposition des coding standards ; testable sans widget, `ProviderContainer` utilisé dans les tests unitaires. |
| Navigation | **go_router** + `StatefulShellRoute.indexedStack` | Implémente directement l'UX Bible règle 10 : chaque onglet garde sa pile, son scroll et sa requête. |
| Typographie | **Inter embarqué** (`assets/fonts/`, 4 graisses, 1,3 Mo) | `google_fonts` télécharge la police au runtime : appel réseau tiers à chaque cold start, contraire au budget « cold start < 2 s » et au principe 5. |
| Icônes | **`lucide_icons_flutter` 3.1.17** | Écart assumé : les coding standards citent `lucide_flutter` (4 ★, ~18k dl/30 j). Le paquet retenu fait 196 ★, 159k dl/30 j, 160/160 pts pub, à jour du 21/08/2026. |
| Modèles | Classes immuables écrites à la main | Écart temporaire : `freezed` sera introduit avec le contrat d'API (sérialisation JSON), pas pour 5 modèles mock sans JSON. |

## 2. Couleur — la Home est la seule référence

La palette n'est pas inventée : elle est **échantillonnée au pixel** sur les maquettes (décodeur PNG ad hoc, pas d'estimation à l'œil).

| Token | Valeur | Source |
|---|---|---|
| `primary` | `#4A35E8` | Home — nav active, « See all », puces |
| `surface` / `card` | `#FAFAFD` / `#FFFFFF` | Home + Parcours |
| `navSurface` | `#EEEBFD` | Home — barre d'onglets |
| `badgeInk` | `#171717` | Home — pastilles d'icônes |
| `lime` | `#EDF9CC` / `#C3E91C` | Home (hero) + Parcours (point) |
| `blue` | `#DAF3FD` / `#72D7F3` | idem |
| `lavender` | `#EDE8FC` / `#8C58D6` | idem |
| `yellow` | `#FDF7D3` / `#FDDB71` | idem |
| `pink` | `#FEE7E2` / `#F87F85` | idem |

Le `#4A35E8` mesuré confirme à 3 % près le `#4F46E5` du Design System : **`02-ux/02-design-system.md` §Couleurs peut passer de « palette proposée, à valider » à validée**, en substituant les valeurs mesurées.

Les cinq familles sont attribuées par **emplacement explicite** : une catégorie porte `accent`, un cluster aussi, et un lymark hérite `accentSlot` de sa catégorie. Le hachage (`accentFor`) ne sert plus que de repli pour un lymark sans catégorie. Raison : une couleur hachée changerait si l'identifiant changeait, et ne serait pas garantie identique entre appareils — c'est donc au serveur de porter cet emplacement. Les emplacements des données de démo reproduisent la Home (IA vert, Design bleu, Development lavande, Business jaune, Product rose).

Les thèmes des autres maquettes (olive/crème du Détail, menthe/carmin du Digest) **ne sont pas repris** : la Home est la référence unique.

Le mode sombre est **dérivé**, pas mesuré — aucune maquette sombre n'existe. À revoir quand il y en aura une.

## 3. Écarts assumés vis-à-vis des maquettes

1. **Digest** — la maquette montre une série de 7 jours, « Great job! 🔥 », un pourcentage de progression et des « trending topics ». L'UX Bible §Ton interdit explicitement la gamification et les badges, et la règle 6 limite le digest à un rappel par jour. L'écran suit donc le **wireframe 06**, pas le PNG.
2. **Profil** — même raison : le « 7 Day streak » est remplacé par « With Lymarks » (ancienneté), factuel.
3. **Icônes de marque** — Lucide a retiré ses icônes de marque (licence). Pas de logo React / Medium / Vercel / HuggingFace : chaque source reçoit une icône sémantique (`squarePlay` pour YouTube, `briefcase` pour LinkedIn…). Si les logos sont indispensables au rendu final, il faudra une seconde bibliothèque (`simple-icons`) — **question ouverte**.
4. **Aperçu de source (fiche détail)** — aplat dégradé teinté de l'accent au lieu de l'image OG. Aucune image distante n'est chargée dans les listes : cela protège le budget de scroll 60 FPS et évite toute requête tierce depuis l'app.
5. **Barre d'onglets** — visible uniquement sur Home / Search / Digest. Les maquettes la montrent aussi sur Détail, Parcours et Réglages ; les wireframes 03, 04, 07 et le §9 « Navigation globale » disent l'inverse. Le comportement suit les wireframes (source de vérité comportementale), la couleur suit la Home.
6. **`Ecran/Home.png` est un doublon exact** de `Ecran/Profil moderne aux accents pastel.png` (même MD5). Il n'existe donc **aucune maquette d'onboarding** : l'écran 01 est construit à partir du seul wireframe.

## 4. Vérification et contraintes de test découvertes

`flutter analyze` (very_good_analysis, strict) : **0 issue**. `flutter test` : **23 tests verts** — 8 de comportement, 15 rendus de référence.

### Le rendu se vérifie par golden tests, pas par navigateur

Le build web se compile (`flutter build web --release`, exit 0) mais **ne se rend pas en Chromium headless** : Flutter monte `flt-glass-pane` en 0×0 et ne crée aucun `<canvas>`. Aucune erreur console, la page est simplement blanche. Piste écartée, non résolue.

À la place, `test/golden_test.dart` rend les 7 écrans en PNG via le moteur Flutter lui-même (`flutter test --update-goldens`), sans device ni navigateur. Les images sont versionnées dans `app/test/goldens/` : preuve visuelle **et** garde-fou anti-régression.

Deux pièges rencontrés, tous deux documentés dans le code :

1. **`pumpAndSettle` ne termine jamais** dès qu'un lymark `processing` est à l'écran : le shimmer boucle indéfiniment (Design System : 1,2 s en boucle). Les tests pompent un nombre fixe de frames.
2. **Les polices ne sont pas chargées par défaut** dans `flutter test` : sans `FontLoader` explicite, chaque glyphe est un pavé plein et les goldens ne valident que la mise en page. `_loadFonts()` charge Inter et Lucide.

Troisième piège mineur : les listes étant paresseuses, la surface de test par défaut (800×600) ne construit aucune carte. Les tests fixent 420×1400.

À reporter dans `08-qualite/01-test-strategy.md`.

### Deux défauts trouvés par les goldens, et corrigés

- **Débordement horizontal** (`RenderFlex overflowed by 141 pixels`) sur l'écran Search : le `Spacer(flex:1)` et le libellé de mode se partageaient l'espace à parts égales, affamant le libellé. Corrigé (`Expanded` sur le libellé, textes tronquables). Ce défaut était invisible sans rendu — il justifie à lui seul les goldens.
- **Dégradés ternes en mode sombre** : les fonds de hero mélangeaient du blanc, ce qui vire au gris sur fond sombre et efface l'identité de couleur. Remplacé par `LyPalette.lift()`, qui renforce la teinte au lieu d'ajouter du blanc — correct dans les deux thèmes.

## 5. Poids embarqué — mesure

`lucide_icons_flutter` déclare **7 familles de police** dans son pubspec ; Flutter embarque toutes les polices d'une dépendance, sans opt-out possible.

| Police | Poids | Utilisée |
|---|---|---|
| `lucide.ttf` | 736 Ko | oui |
| `LucideVariable-w100…w600` (6 fichiers) | 2,5 Mo | **non** |
| Inter 400/500/600/700 | 1,3 Mo | oui |

Soit **2,5 Mo de poids mort** sur un budget d'app installée de 40 Mo (`08-qualite/02-performance-budget.md`). Ce n'est pas un dépassement, donc rien n'est fait maintenant — le jeu d'icônes bouge encore. À revoir avant soumission aux stores : vendoriser `lucide.ttf` seul, ou sous-ensembler la police aux ~57 glyphes réellement utilisés (~10 Ko).

## 6. Environnement

Flutter 3.41.9 · Dart 3.11.5 · Node 22.22 · **pas de SDK Android sur cette machine** — vérification sur Chrome et Windows en attendant. `flutter doctor` : tout est vert sauf la chaîne Android.

## 7. Questions ouvertes créées par les écrans

Elles ne bloquent pas le code actuel mais devront être tranchées :

1. **Clustering automatique** — le Category Path affiche des clusters (« AI Agents », « RAG »…). Le wireframe 03 le signale déjà (« Point à formaliser ») : rien dans le PRD ni le Knowledge Vault Spec ne définit comment un cluster naît, se recalcule, ou accueille un nouveau lymark. L'écran fonctionne sur des clusters mock.
2. **Digest Free ou Pro** — le PRD le classe P1/Pro, le wireframe 06 laisse la question ouverte. L'app affiche un bandeau d'upsell en Free ; à confirmer.
3. **« Open original »** — navigateur in-app (Custom Tabs / SFSafariViewController) ou externe. Le bouton existe, l'action est un stub.
4. **Logos de marque** — voir §3.3.
