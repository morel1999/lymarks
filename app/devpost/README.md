# Captures de soumission Devpost

Rendues par l'app elle-même, à la dimension exacte exigée par le règlement
du Shipaton : **1179 × 2556 pixels, sans cadre d'appareil**. C'est 393 × 852
points à 3×, soit un vrai format de téléphone — et non les 420 × 1400 des
rendus de référence, une hauteur qu'aucun appareil n'a, choisie là-bas pour
qu'un écran entier tienne dans une seule image.

Aucun redimensionnement, aucun cadre à détourer, et elles se refont d'une
commande si le design bouge :

```
flutter test --tags golden test/devpost_test.dart --update-goldens
```

| Fichier | Ce qu'il montre |
|---|---|
| `01-home.png` | Le hub : catégories, puis les lymarks résumés en trois puces |
| `02-lymark.png` | Une fiche : résumé, note personnelle, voisins, « Open original » |
| `03-category-path.png` | Le chemin d'une catégorie |
| `04-locked.png` | Au-delà de la limite Free : le lien est gardé, pas perdu |
| `05-paywall.png` | Le paywall servi par les offres RevenueCat |

Le jeu de données est celui du mode démo, cartes en cours de traitement
retirées : un squelette de chargement ne montre rien à un jury.
