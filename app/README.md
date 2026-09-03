# Lymarks — app Flutter

Les 7 écrans du produit, sur données de démonstration. Le backend (Hono sur
Cloudflare Workers) arrive à l'étape suivante ; aucun écran ne connaît
`MockData`, tout passe par les providers de `lib/shared/data/providers.dart`.

## Lancer

```bash
flutter pub get
flutter run -d chrome     # ou -d windows
```

Pas de SDK Android sur la machine de développement actuelle : `flutter doctor`
le signale, et seule la chaîne Android est en défaut.

## Vérifier

```bash
flutter analyze            # very_good_analysis, strict : doit rendre 0 issue
flutter test               # 8 tests de comportement + 15 rendus de référence
flutter test --update-goldens   # après un changement visuel volontaire
```

Les rendus de référence sont dans `test/goldens/`. Ils sont versionnés : ce
sont à la fois la preuve visuelle de ce que rend l'app et le garde-fou contre
les régressions. Un `flutter test` qui échoue sur un golden signale soit une
régression, soit un changement voulu à régénérer.

Deux pièges à connaître :

- **`pumpAndSettle` ne termine jamais** dès qu'un lymark `processing` est à
  l'écran : son shimmer boucle indéfiniment. Les tests pompent un nombre fixe
  de frames (`_settle`).
- Les listes sont paresseuses : sur la surface de test par défaut (800×600)
  les cartes ne sont pas construites. Les tests fixent 420×1400.

## Structure

```
lib/
├── core/
│   ├── theme/      tokens de couleur, échelle typo, espacements, ThemeData
│   ├── router/     go_router, 3 onglets persistants
│   └── utils/      table d'icônes Lucide, formatage temporel
├── shared/
│   ├── models/     Lymark, KnowledgeCategory, UserProfile
│   ├── data/       données de démo + providers Riverpod
│   └── widgets/    BookmarkCard, DigestCard, SearchField, PaywallSheet…
└── features/       onboarding · home · category · detail · search · digest ·
                    settings
```

Feature-first, conformément à `../07-dev/01-coding-standards.md` §1.

## Couleur

La palette est **échantillonnée au pixel** sur `../Ecran/Accueil de curation
des connaissances IA.png` (base) et `../Ecran/Parcours IA pastel sur
mobile.png` (accents saturés). Valeurs et méthode :
`../07-dev/02-journal-demarrage.md` §2.

Cinq familles d'accent portent la couleur du produit. Une catégorie, un
cluster et un lymark portent chacun un **emplacement explicite**
(`accent` / `accentSlot`) plutôt qu'une couleur hachée : la couleur d'un sujet
doit rester la même d'un appareil à l'autre, donc le serveur la portera.

## Écarts assumés

Ils sont tous consignés dans `../07-dev/02-journal-demarrage.md` §3 : maquette
Digest écartée (gamification interdite par l'UX Bible), absence d'icônes de
marque dans Lucide, aperçu de source sans image distante, barre d'onglets
limitée aux trois écrans principaux.
