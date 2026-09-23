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

### Bloc PERSONNAGE

Il est **déjà inclus** dans chaque prompt de la section 2 — inutile de le
recoller. Il figure ici pour référence, et pour le jour où tu voudras une pose
qui n'est pas dans la liste.

```
A small round chibi creature named Lymarks. Single spherical body, no neck,
glossy soft 3D render. Body has a smooth gradient from cyan-blue on the lower
left to violet-purple on the upper right. Three small rounded bumps form a tuft
on top of the head. Two very large round eyes with white sclera, big dark navy
irises with a lighter blue ring, one small white specular highlight in the upper
left of each pupil. Thin short dark arched eyebrows. Soft pink blush ovals on
both cheeks. Two very small rounded arm stubs on the sides, no fingers. Two
short rounded stubby legs, no feet detail. Pixar-style character, soft
matte-glossy finish, subtle subsurface scattering.
```

La **bouche n'est pas décrite ici** : c'est la pose qui la fixe, parce que
c'est elle qui porte l'émotion. Une mascotte qui sourit pendant un échec
sonnerait faux.

> **Garde le violet d'origine, ne demande pas de bleu.** L'app affiche la
> mascotte en bleu, mais cette teinte est obtenue par une rotation de −35° que
> j'applique après coup. En partant toujours du même violet, toutes les poses
> retombent exactement sur la même couleur finale. Demander du bleu au
> générateur produirait un bleu différent à chaque fois.

### Bloc TECHNIQUE

Également déjà inclus dans chaque prompt de la section 2.

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

Chaque bloc ci-dessous est un **prompt complet** : copie-le entier, d'un seul tenant. Le personnage et le cadrage y sont déjà, tu n'as rien à assembler. Joins en plus `app/branding/mascot.png` comme image de référence si ton outil le permet.

**Six poses sont embarquées dans l'app** : perplexe, liste vide, recherche sans résultat, endormie, salut, et le rendu de face d'origine (`mascot.png`). Les trois autres — hors-ligne, en train de lire, célébration — ont été générées puis **retirées le 23/09** : aucun écran ne les affichait, et un asset qu'aucun écran n'affiche pèse dans l'APK tout en laissant croire que la fonctionnalité existe. Leurs prompts restent ci-dessous : le jour où un écran les réclame, la génération est prête.

### 1. Perplexe → `mascot-puzzled.png`

**Où :** Carte en échec — « Couldn't process this link. »  
**Pourquoi cette pose :** Le lien n'a pas pu être lu. Elle ne gronde pas : c'est Lymarks qui a échoué, pas l'utilisateur.

```
A small round chibi creature named Lymarks. Single spherical body, no neck,
glossy soft 3D render. Body has a smooth gradient from cyan-blue on the lower
left to violet-purple on the upper right. Three small rounded bumps form a tuft
on top of the head. Two very large round eyes with white sclera, big dark navy
irises with a lighter blue ring, one small white specular highlight in the upper
left of each pupil. Thin short dark arched eyebrows. Soft pink blush ovals on
both cheeks. Two very small rounded arm stubs on the sides, no fingers. Two
short rounded stubby legs, no feet detail. Pixar-style character, soft
matte-glossy finish, subtle subsurface scattering.

Pose: Head tilted to one side, one arm stub raised in a small shrug, the other
hanging down. Eyebrows asymmetrical, one raised and one lowered. Mouth closed in
a small wavy line. Eyes looking slightly up and to the side. Puzzled and
apologetic, never sad or scolding.

Full body, centered, straight-on eye-level camera, character fills about 80% of
the frame height. Soft studio key light from the upper left, gentle rim light,
no cast shadow on the background. Flat solid chroma green background (#00FF00),
perfectly uniform, no gradient, no floor, no shadow. Square 1:1, at least
1024x1024. No text, no logo, no watermark, no border, no checkerboard pattern.
```

### 2. Hors-ligne → `mascot-offline.png`

**Où :** Bandeau « Offline — showing your last synced lymarks. »  
**Pourquoi cette pose :** Le réseau est coupé mais rien n'est perdu : la pose doit rassurer, pas alarmer.

```
A small round chibi creature named Lymarks. Single spherical body, no neck,
glossy soft 3D render. Body has a smooth gradient from cyan-blue on the lower
left to violet-purple on the upper right. Three small rounded bumps form a tuft
on top of the head. Two very large round eyes with white sclera, big dark navy
irises with a lighter blue ring, one small white specular highlight in the upper
left of each pupil. Thin short dark arched eyebrows. Soft pink blush ovals on
both cheeks. Two very small rounded arm stubs on the sides, no fingers. Two
short rounded stubby legs, no feet detail. Pixar-style character, soft
matte-glossy finish, subtle subsurface scattering.

Pose: Sitting down on the ground, body relaxed. Eyes half closed and calm. One arm
stub holds one end of a small unplugged cable, the loose end resting on the
floor. Mouth a small closed smile. Patient and waiting, not distressed.

Full body, centered, straight-on eye-level camera, character fills about 80% of
the frame height. Soft studio key light from the upper left, gentle rim light,
no cast shadow on the background. Flat solid chroma green background (#00FF00),
perfectly uniform, no gradient, no floor, no shadow. Square 1:1, at least
1024x1024. No text, no logo, no watermark, no border, no checkerboard pattern.
```

### 3. Accueil d'une liste vide → `mascot-empty.png`

**Où :** « Nothing here yet. » (catégorie, cluster)  
**Pourquoi cette pose :** Rien à montrer encore : la pose invite à enregistrer un premier lien.

```
A small round chibi creature named Lymarks. Single spherical body, no neck,
glossy soft 3D render. Body has a smooth gradient from cyan-blue on the lower
left to violet-purple on the upper right. Three small rounded bumps form a tuft
on top of the head. Two very large round eyes with white sclera, big dark navy
irises with a lighter blue ring, one small white specular highlight in the upper
left of each pupil. Thin short dark arched eyebrows. Soft pink blush ovals on
both cheeks. Two very small rounded arm stubs on the sides, no fingers. Two
short rounded stubby legs, no feet detail. Pixar-style character, soft
matte-glossy finish, subtle subsurface scattering.

Pose: Standing, both arm stubs opened wide in a welcoming gesture. Wide bright eyes
looking straight at the viewer. Big open smile showing a tiny pink tongue. Body
leaning very slightly forward. Inviting and encouraging.

Full body, centered, straight-on eye-level camera, character fills about 80% of
the frame height. Soft studio key light from the upper left, gentle rim light,
no cast shadow on the background. Flat solid chroma green background (#00FF00),
perfectly uniform, no gradient, no floor, no shadow. Square 1:1, at least
1024x1024. No text, no logo, no watermark, no border, no checkerboard pattern.
```

### 4. Recherche sans résultat → `mascot-searching.png`

**Où :** « Nothing surfaced yet. » (recherche)  
**Pourquoi cette pose :** La requête n'a rien donné : elle cherche encore, elle ne renonce pas.

```
A small round chibi creature named Lymarks. Single spherical body, no neck,
glossy soft 3D render. Body has a smooth gradient from cyan-blue on the lower
left to violet-purple on the upper right. Three small rounded bumps form a tuft
on top of the head. Two very large round eyes with white sclera, big dark navy
irises with a lighter blue ring, one small white specular highlight in the upper
left of each pupil. Thin short dark arched eyebrows. Soft pink blush ovals on
both cheeks. Two very small rounded arm stubs on the sides, no fingers. Two
short rounded stubby legs, no feet detail. Pixar-style character, soft
matte-glossy finish, subtle subsurface scattering.

Pose: Leaning forward, one arm stub raised flat above the eyes like a visor, the
other resting on the side of the body. Eyes wide open and looking off to the
side. Mouth small and closed in concentration. Actively scanning for something.

Full body, centered, straight-on eye-level camera, character fills about 80% of
the frame height. Soft studio key light from the upper left, gentle rim light,
no cast shadow on the background. Flat solid chroma green background (#00FF00),
perfectly uniform, no gradient, no floor, no shadow. Square 1:1, at least
1024x1024. No text, no logo, no watermark, no border, no checkerboard pattern.
```

### 5. En train de lire → `mascot-reading.png`

**Où :** Carte `processing`, en attente du résumé  
**Pourquoi cette pose :** Le pipeline travaille. Remplace le squelette animé quand l'attente dépasse quelques secondes.

```
A small round chibi creature named Lymarks. Single spherical body, no neck,
glossy soft 3D render. Body has a smooth gradient from cyan-blue on the lower
left to violet-purple on the upper right. Three small rounded bumps form a tuft
on top of the head. Two very large round eyes with white sclera, big dark navy
irises with a lighter blue ring, one small white specular highlight in the upper
left of each pupil. Thin short dark arched eyebrows. Soft pink blush ovals on
both cheeks. Two very small rounded arm stubs on the sides, no fingers. Two
short rounded stubby legs, no feet detail. Pixar-style character, soft
matte-glossy finish, subtle subsurface scattering.

Pose: Looking down at a small blank floating card held in front of the body with
both arm stubs. Eyes lowered and focused on the card. Eyebrows slightly drawn
together. Mouth closed in a small concentrated line. Absorbed in reading.

Full body, centered, straight-on eye-level camera, character fills about 80% of
the frame height. Soft studio key light from the upper left, gentle rim light,
no cast shadow on the background. Flat solid chroma green background (#00FF00),
perfectly uniform, no gradient, no floor, no shadow. Square 1:1, at least
1024x1024. No text, no logo, no watermark, no border, no checkerboard pattern.
```

### 6. Endormie → `mascot-sleeping.png`

**Où :** Digest vide — « Nothing to revisit yet. »  
**Pourquoi cette pose :** Rien à faire remonter aujourd'hui : l'app se tait, la mascotte aussi.

```
A small round chibi creature named Lymarks. Single spherical body, no neck,
glossy soft 3D render. Body has a smooth gradient from cyan-blue on the lower
left to violet-purple on the upper right. Three small rounded bumps form a tuft
on top of the head. Two very large round eyes with white sclera, big dark navy
irises with a lighter blue ring, one small white specular highlight in the upper
left of each pupil. Thin short dark arched eyebrows. Soft pink blush ovals on
both cheeks. Two very small rounded arm stubs on the sides, no fingers. Two
short rounded stubby legs, no feet detail. Pixar-style character, soft
matte-glossy finish, subtle subsurface scattering.

Pose: Curled up asleep on the ground, body slightly squashed and relaxed, arm stubs
tucked in. Eyes closed as two calm downward arcs. Mouth a tiny closed smile. One
small sleep bubble floating near the head. Peaceful.

Full body, centered, straight-on eye-level camera, character fills about 80% of
the frame height. Soft studio key light from the upper left, gentle rim light,
no cast shadow on the background. Flat solid chroma green background (#00FF00),
perfectly uniform, no gradient, no floor, no shadow. Square 1:1, at least
1024x1024. No text, no logo, no watermark, no border, no checkerboard pattern.
```

### 7. Célébration → `mascot-celebrating.png`

**Où :** Pro débloqué, première capture réussie  
**Pourquoi cette pose :** Le seul moment où elle fête quelque chose — à garder rare pour qu'il garde sa valeur.

```
A small round chibi creature named Lymarks. Single spherical body, no neck,
glossy soft 3D render. Body has a smooth gradient from cyan-blue on the lower
left to violet-purple on the upper right. Three small rounded bumps form a tuft
on top of the head. Two very large round eyes with white sclera, big dark navy
irises with a lighter blue ring, one small white specular highlight in the upper
left of each pupil. Thin short dark arched eyebrows. Soft pink blush ovals on
both cheeks. Two very small rounded arm stubs on the sides, no fingers. Two
short rounded stubby legs, no feet detail. Pixar-style character, soft
matte-glossy finish, subtle subsurface scattering.

Pose: Both arm stubs thrown up in the air, body stretched slightly upward in
mid-jump, legs tucked up. Mouth wide open in a joyful laugh showing the pink
tongue. Eyes as happy closed upward arcs. Cheeks strongly blushed. Delighted.

Full body, centered, straight-on eye-level camera, character fills about 80% of
the frame height. Soft studio key light from the upper left, gentle rim light,
no cast shadow on the background. Flat solid chroma green background (#00FF00),
perfectly uniform, no gradient, no floor, no shadow. Square 1:1, at least
1024x1024. No text, no logo, no watermark, no border, no checkerboard pattern.
```

### 8. Salut d'accueil → `mascot-waving.png`

**Où :** Connexion — « Sign in to sync your memory. »  
**Pourquoi cette pose :** Première rencontre après l'onboarding : elle accueille, elle ne vend rien.

```
A small round chibi creature named Lymarks. Single spherical body, no neck,
glossy soft 3D render. Body has a smooth gradient from cyan-blue on the lower
left to violet-purple on the upper right. Three small rounded bumps form a tuft
on top of the head. Two very large round eyes with white sclera, big dark navy
irises with a lighter blue ring, one small white specular highlight in the upper
left of each pupil. Thin short dark arched eyebrows. Soft pink blush ovals on
both cheeks. Two very small rounded arm stubs on the sides, no fingers. Two
short rounded stubby legs, no feet detail. Pixar-style character, soft
matte-glossy finish, subtle subsurface scattering.

Pose: Standing, one arm stub raised and open in a friendly wave, the other resting
on the side of the body. Head tilted slightly toward the raised arm. Warm open
smile. Eyes looking straight at the viewer.

Full body, centered, straight-on eye-level camera, character fills about 80% of
the frame height. Soft studio key light from the upper left, gentle rim light,
no cast shadow on the background. Flat solid chroma green background (#00FF00),
perfectly uniform, no gradient, no floor, no shadow. Square 1:1, at least
1024x1024. No text, no logo, no watermark, no border, no checkerboard pattern.
```

### Ce qui n'a **pas** besoin d'un rendu

La pose « la mascotte dépasse derrière une carte » (deuxième écran de l'onboarding) s'obtient en posant le rendu de face **derrière** la carte dans la composition. Inutile de la générer.

## 3. Ce que je fais des fichiers

Dépose-les dans `app/branding/poses/`, nommés comme ci-dessus, puis lance :

```
node tools/mascot/build.js
```

Il fait quatre choses, dans cet ordre :

1. **Détourage** du fond vert. Le remplissage part des bords plutôt que de viser
   tout ce qui est vert, sinon un reflet vert **dans** le sujet deviendrait
   transparent. Le « despill » ramène ensuite le vert qui a bavé sur le contour,
   sans quoi la mascotte garde un liseré fluo.
2. **Alignement de teinte sur `mascot.png`**, et non une rotation fixe : deux
   rendus du même prompt ne sortent jamais du même violet. L'outil mesure la
   teinte dominante de chaque pose et la tourne vers celle de la référence.
3. **Remontée du bout froid du dégradé.** Ajoutée le 23/09, après que trois
   poses régénérées soient sorties avec un flanc **vert**. La rotation ne
   déplace que la moyenne : un lot plus froid que la référence descend jusqu'au
   cyan-vert et y reste. L'outil compare désormais le 2ᵉ centile de teinte de
   la pose à celui de la référence (188°) et comprime ce qui passe en dessous —
   sans couper net, pour que le dégradé garde son modelé. Le rose des joues,
   au-dessus du plancher, n'est pas touché.
4. **Recadrage et mise à l'échelle** sur 560 px de haut, la hauteur d'affichage
   réelle (120 à 180 dp sur un écran 3x), puis encodage PNG. Une pose pèse
   260 à 360 Ko.

Ne retouche rien toi-même : si une pose part d'un fichier traité autrement, sa
couleur ne tombera pas sur celle des autres.

**Vérification** : après un passage, les six poses doivent tenir dans une
poignée de degrés de teinte les unes des autres. Au 23/09 elles sont entre 220°
et 222,5°, pour une saturation de 76 à 85 % — sauf `mascot.png`, à 63 %, qui
n'est jamais passée par ce pipeline puisqu'elle en est la référence.

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
