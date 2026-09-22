# Lymarks, la mascotte — fiche et prompts de génération

> **But :** produire de nouvelles poses sans que le personnage dérive. · **Statut :** vivant · **Màj :** 2026-09-22

La mascotte s'appelle **Lymarks**, comme l'app. Elle est le seul personnage du
produit : pas d'illustration humaine, pas de second animal. Rendu de
référence : `app/branding/mascot.png` (détouré, fond transparent réel).

## 1. Ce qui ne change jamais

Un générateur d'images ne « se souvient » pas d'un personnage : il le
re-invente à chaque appel. La cohérence vient de trois leviers, dans cet
ordre d'efficacité :

1. **Joindre le rendu de référence en image d'entrée** (image-to-image, ou
   « reference image » / « style reference » selon l'outil). C'est ce qui
   tient le personnage. Si ton outil le permet, ne t'en prive jamais.
2. **Répéter mot pour mot le bloc PERSONNAGE ci-dessous**, sans le reformuler.
3. **Garder la même caméra et la même lumière** (bloc TECHNIQUE).

### Bloc PERSONNAGE (à coller tel quel, en tête de chaque prompt)

```
A small round chibi creature named Lymarks. Single spherical body, no neck,
glossy soft 3D render. Body has a smooth gradient from cyan-blue on the lower
left to violet-purple on the upper right. Three small rounded bumps form a tuft
on top of the head. Two very large round eyes with white sclera, big dark navy
irises with a lighter blue ring, one small white specular highlight in the upper
left of each pupil. Thin short dark arched eyebrows. Small open smiling mouth,
dark inside, tiny pink tongue. Soft pink blush ovals on both cheeks. Two very
small rounded arm stubs on the sides, no fingers. Two short rounded stubby legs,
no feet detail. Pixar-style character, soft matte-glossy finish, subtle
subsurface scattering.
```

> **Garde le violet d'origine, ne demande pas de bleu.** L'app affiche la
> mascotte en bleu, mais cette teinte est obtenue par une rotation de −35° que
> j'applique après coup. En partant toujours du même violet, toutes les poses
> retombent exactement sur la même couleur finale. Demander du bleu au
> générateur produirait un bleu différent à chaque fois.

### Bloc TECHNIQUE (à coller à la fin de chaque prompt)

```
Full body, centered, straight-on eye-level camera, character fills about 80% of
the frame height. Soft studio key light from the upper left, gentle rim light,
no cast shadow on the background. Flat solid chroma green background (#00FF00),
perfectly uniform, no gradient, no floor, no shadow. Square 1:1, at least
1024x1024. No text, no logo, no watermark, no border, no checkerboard pattern.
```

⚠️ **Le damier gris et blanc n'est pas de la transparence.** C'est ainsi que
les sites d'images *affichent* un fond transparent ; si tu télécharges cet
aperçu, le damier devient de vrais pixels (c'était le cas du premier fichier).
Demande un fond vert uni : je le découpe proprement, et c'est sans ambiguïté.

## 2. Les poses, et l'écran que chacune sert

Prompt complet = **PERSONNAGE** + **POSE** + **TECHNIQUE**.

### Priorité 1 — des états qui existent déjà dans l'app

| Fichier attendu | Écran | Bloc POSE à insérer |
|---|---|---|
| `mascot-puzzled.png` | Carte en échec, « Couldn't process this link. » | `Pose: head tilted to one side, one arm stub raised in a small shrug, eyebrows asymmetrical (one up, one down), mouth a small wavy line, eyes looking slightly up and sideways. Puzzled but not sad.` |
| `mascot-offline.png` | Bandeau « Offline — showing your last synced lymarks. » | `Pose: sitting down, eyes half closed and calm, holding one end of a small unplugged cable in an arm stub, the other end loose. Patient, waiting, not distressed.` |
| `mascot-empty.png` | « Nothing here yet. » (catégorie, cluster) | `Pose: standing, both arm stubs open wide in a welcoming gesture, wide bright eyes, big open smile, leaning very slightly forward. Inviting, encouraging.` |
| `mascot-searching.png` | « Nothing surfaced yet. » (recherche) | `Pose: leaning forward, one arm stub raised flat above the eyes like a visor, eyes wide and looking to the side, mouth small and focused. Actively scanning for something.` |

### Priorité 2 — pour les écrans à venir

| Fichier attendu | Écran | Bloc POSE à insérer |
|---|---|---|
| `mascot-reading.png` | Carte `processing`, en attente du résumé | `Pose: looking down at a small blank floating card held in front of it with both arm stubs, eyes lowered and focused, mouth closed in a small concentrated line.` |
| `mascot-sleeping.png` | Digest vide, « Nothing to revisit yet. » | `Pose: curled up asleep, eyes closed as two calm downward arcs, mouth a tiny closed smile, body slightly squashed and relaxed.` |
| `mascot-celebrating.png` | Pro débloqué, première capture réussie | `Pose: both arm stubs thrown up in the air, mouth wide open in a joyful laugh, eyes as happy closed upward arcs, body stretched slightly upward mid-jump.` |
| `mascot-waving.png` | Connexion, « Sign in to sync your memory. » | `Pose: standing, one arm stub raised and open in a friendly wave, head tilted slightly toward the raised arm, warm smile, eyes looking straight at the viewer.` |

### Ce qui n'a **pas** besoin d'un rendu

La pose « la mascotte dépasse derrière une carte » (deuxième écran de
l'onboarding) s'obtient en posant le rendu de face **derrière** la carte dans
la composition. Inutile de la générer.

## 3. Ce que je fais des fichiers

Dépose-les dans `app/branding/poses/`, nommés comme ci-dessus. Je m'occupe de :

1. **Détourage** du fond vert, avec un contour propre (même traitement que le
   rendu d'origine : `scratchpad/decheck.js`, remplissage depuis les bords).
2. **Rotation de teinte de −35°**, la même pour toutes : c'est elle qui garantit
   que deux poses ont exactement le même bleu.
3. **Recadrage et mise à l'échelle** sur la hauteur d'affichage réelle, puis
   encodage PNG filtré (une pose pèse ~380 Ko en 780 px, ~120 Ko en 420 px).
4. **Déclaration en asset** et branchement sur l'état concerné.

Ne retouche rien toi-même : si une pose part d'un fichier traité autrement, sa
couleur ne tombera pas sur celle des autres.

## 4. Règles d'emploi dans l'app

- **Elle ne bloque jamais une tâche.** Aucune mascotte dans la feuille de
  partage : la capture doit rester sous deux secondes (UX Bible règle 11).
- **Une seule mascotte à l'écran**, jamais deux poses en même temps.
- **Elle accompagne le vide et l'échec, pas le succès courant.** Une carte qui
  se résume normalement n'a pas besoin d'elle ; c'est quand il n'y a rien à
  montrer, ou que quelque chose a raté, qu'un personnage vaut mieux qu'une
  icône grise.
- **Elle ne commente jamais une erreur de l'utilisateur.** Un lien illisible
  est un échec de Lymarks, pas du lecteur : la pose est perplexe, jamais
  réprobatrice.
- **Taille** : 120 à 180 px de haut dans un état vide, 200 à 260 px dans
  l'onboarding. Au-delà, elle écrase le texte qu'elle est censée servir.
