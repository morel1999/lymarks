"""Transforme les rendus 3D de l'onboarding en assets de l'app.

    python tools/onboarding/build.py

Entrée  : app/branding/onboarding/scene-<nom>.{png,jpg} — les rendus bruts,
          mascotte violette et décor tel que sorti du générateur.
Sortie  : app/assets/brand/onboarding-<nom>.webp — remis à la teinte de
          l'app, recadrés, à la largeur réelle d'un écran.

Les deux scènes ne sortent pas du même moule et ne subissent pas le même
traitement :

  **capture** vient d'une image d'un GIF de 10 s. Palette de 256 couleurs :
  son dégradé sombre est reconstitué par un tramage de points, qui scintille
  sur un écran OLED. Un flou léger le fond, *avant* l'agrandissement — après,
  les points seraient figés dans des pixels plus gros et plus rien ne les
  enlèverait — et un masque de netteté récupère les contours. 540 px de large
  au départ, donc agrandie.

  **find** est un JPEG de 1536 px, deux cent mille couleurs : rien à
  détramer, et elle est *réduite* plutôt qu'agrandie. En revanche elle est
  carrée quand un écran ne l'est pas, et elle se passe dans une pièce au
  soleil couchant quand l'autre scène flotte dans le noir. Elle est donc
  recadrée, et son décor **éteint** : saturation et lumière tombent hors du
  sujet. On ne lui tourne pas la teinte — un coucher de soleil poussé vers le
  bleu vire au vert.

Commun aux deux : la mascotte sort violette du générateur (243° et 258°)
quand celle de l'app est à 220°. Comme pour les poses, la cible n'est pas une
constante mais une mesure sur `mascot.png` — deux rendus du même prompt ne
donnent jamais exactement le même violet.

Pourquoi Python ici, quand `tools/mascot/build.js` est en Node : le WebP
divise le poids par quinze face au PNG, et aucun encodeur WebP n'existe sans
dépendance en Node. Pillow en a un.
"""

import colorsys
import os

from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "app", "branding", "onboarding")
OUT = os.path.join(ROOT, "app", "assets", "brand")
#: La mascotte déjà dans l'app : c'est elle qui donne la teinte de référence.
REFERENCE = os.path.join(OUT, "mascot.png")

#: Largeur de sortie : 393 dp à 3x, la largeur réelle de l'écran. La scène
#: s'y pose donc pixel pour pixel, et le téléphone n'a rien à rééchantillonner.
OUT_WIDTH = 1179

#: Part de l'écart de teinte réellement corrigée. À 1, tous les pixels du
#: corps tomberaient sur la même teinte et la mascotte s'aplatirait : c'est
#: la variation de teinte qui donne le volume.
HUE_KEEP = 0.85
#: Le bleu de l'app respire plus que le violet du générateur.
SAT_LIFT, LUM_LIFT = 0.30, 0.09
#: La fenêtre de violet à corriger. En dehors : le néon vert du lien, les
#: étincelles jaunes et le ciel rose, qui ne doivent pas bouger.
VIOLET = (226, 295)
#: Raideur du fondu au bord de chaque zone. Plus il est raide, plus la
#: correction est pleine au centre — à 3, les deux tiers extérieurs de
#: l'ellipse n'étaient corrigés qu'en partie et la mascotte restait violette
#: de treize degrés.
FALLOFF = 6.0

SCENES = {
    "capture": {
        "file": "scene-capture.png",
        # La mascotte dans l'image source, en parts de l'image. Une liste :
        # chaque zone porte son ellipse, et une seule boîte englobante
        # laisserait les extrémités — mains, pieds — hors de la correction.
        "mascot": [(0.352, 0.172, 0.750, 0.458)],
        # Le carré du logo tiers sur la carte du haut.
        "logo": (0.100, 0.195, 0.217, 0.261),
        "detrame": True,
    },
    "find": {
        "file": "scene-find.jpg",
        "mascot": [
            (0.32, 0.03, 0.68, 0.37),  # la tête
            (0.11, 0.41, 0.25, 0.61),  # la main gauche
            (0.75, 0.41, 0.89, 0.61),  # la main droite
            (0.31, 0.79, 0.69, 0.96),  # les pieds
        ],
        "logo": None,
        "detrame": False,
        # Carrée : on retire les bords latéraux, là où la pièce n'apporte
        # plus rien, pour approcher une proportion de téléphone.
        "crop": (0.11, 0.0, 0.89, 1.0),
        # Le sujet — mascotte et tablette — autour duquel le décor s'éteint.
        "subject": (0.50, 0.52, 0.46, 0.50),
        # Ce qu'il reste de couleur au loin, et la vitesse de l'extinction.
        "dim": (0.16, 2.6),
    },
}


def dominant_body(img, frac=None):
    """La couleur de corps dominante d'une zone, et sa teinte en degrés.

    Plus sûre qu'une moyenne sur une boîte : une boîte autour d'une tête
    ronde contient forcément du fond dans ses coins, et ce fond — rose vif
    dans la scène `find` — tirait la mesure de dix degrés.
    """
    px = img.crop(frac) if frac else img
    quant = px.convert("RGB").quantize(colors=24, method=Image.MEDIANCUT)
    palette = quant.getpalette()
    for _, index in sorted(quant.getcolors(), reverse=True):
        rgb = tuple(palette[index * 3 : index * 3 + 3])
        h, l, s = colorsys.rgb_to_hls(*[c / 255 for c in rgb])
        if s > 0.35 and 0.40 < l < 0.75:
            return rgb, h * 360
    return (0, 0, 0), 0.0


def box(img, frac):
    """Une boîte donnée en parts de l'image, ramenée en pixels."""
    x1, y1, x2, y2 = frac
    return (
        int(img.width * x1),
        int(img.height * y1),
        int(img.width * x2),
        int(img.height * y2),
    )


def retint(img, frac, target):
    """Ramène le violet du corps vers le bleu de l'app."""
    out = img.copy()
    px = out.load()
    x1, y1, x2, y2 = box(img, frac)
    cx, cy, rx, ry = (x1 + x2) / 2, (y1 + y2) / 2, (x2 - x1) / 2, (y2 - y1) / 2
    lo, hi = VIOLET
    for y in range(y1, y2):
        for x in range(x1, x2):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d > 1:
                continue
            # Fondu elliptique : sans lui, la zone corrigée aurait un bord.
            w = min(1.0, (1 - d) * FALLOFF)
            r, g, b = px[x, y]
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            if s < 0.20 or not (lo <= h * 360 <= hi):
                continue
            h2 = (h - (h - target) * HUE_KEEP * w) % 1.0
            s2 = min(1.0, s * (1 + SAT_LIFT * w))
            l2 = min(1.0, l * (1 + LUM_LIFT * w))
            r2, g2, b2 = colorsys.hls_to_rgb(h2, l2, s2)
            px[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255))
    return out


def delogo(img, frac, target):
    """Le carré rouge devient bleu : la teinte tourne, le relief reste."""
    out = img.copy()
    px = out.load()
    x1, y1, x2, y2 = box(img, frac)
    for y in range(y1, y2):
        for x in range(x1, x2):
            r, g, b = px[x, y]
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            if s < 0.25:
                continue  # le glyphe blanc reste blanc
            deg = h * 360
            if deg < 40 or deg > 320:  # le rouge, et lui seul
                r2, g2, b2 = colorsys.hls_to_rgb(target, l * 0.95, min(1.0, s * 0.9))
                px[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255))
    return out


def dim_decor(img, subject, keep, fade):
    """Éteint le décor : hors du sujet, la couleur et la lumière tombent.

    Pas de rotation de teinte ici. Pousser un coucher de soleil vers le bleu
    le fait virer au vert ; le priver de son intensité le range derrière le
    sujet sans le dénaturer.
    """
    out = img.copy()
    px = out.load()
    cx, cy, rx, ry = subject
    cx, cy = cx * img.width, cy * img.height
    rx, ry = rx * img.width, ry * img.height
    for y in range(img.height):
        for x in range(img.width):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d <= 1:
                continue
            w = min(1.0, (d - 1) * fade)  # 0 au bord du sujet, 1 au loin
            r, g, b = px[x, y]
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            r2, g2, b2 = colorsys.hls_to_rgb(
                h, l * (1 - 0.55 * w), s * (1 - (1 - keep) * w)
            )
            px[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255))
    return out


def detrame(img, width):
    """Fond le tramage, puis agrandit."""
    height = round(img.height * width / img.width)
    return (
        img.filter(ImageFilter.GaussianBlur(0.9))
        .resize((width, height), Image.LANCZOS)
        .filter(ImageFilter.UnsharpMask(2.5, 90, 3))
    )


def main():
    reference = Image.open(REFERENCE).convert("RGBA")
    flat = Image.new("RGB", reference.size, (6, 10, 18))
    flat.paste(reference, mask=reference.split()[3])
    rgb, target = dominant_body(flat)
    print(f"référence : rgb{rgb}, teinte {target:.1f} deg")

    for name, cfg in SCENES.items():
        img = Image.open(os.path.join(SRC, cfg["file"])).convert("RGB")
        # La première zone est le corps : c'est elle qu'on mesure.
        measured = box(img, cfg["mascot"][0])
        _, before = dominant_body(img, measured)

        for zone in cfg["mascot"]:
            img = retint(img, zone, target / 360)
        if cfg["logo"]:
            img = delogo(img, cfg["logo"], target / 360)
        rgb, after = dominant_body(img, measured)

        if cfg.get("subject"):
            img = dim_decor(img, cfg["subject"], *cfg["dim"])
        if cfg.get("crop"):
            img = img.crop(box(img, cfg["crop"]))

        if cfg["detrame"]:
            img = detrame(img, OUT_WIDTH)
        else:
            img = img.resize(
                (OUT_WIDTH, round(img.height * OUT_WIDTH / img.width)),
                Image.LANCZOS,
            )

        path = os.path.join(OUT, f"onboarding-{name}.webp")
        img.save(path, "WEBP", quality=90, method=6)
        print(
            f"{name:8s} : mascotte {before:.1f} -> {after:.1f} deg rgb{rgb}  ·  "
            f"{img.width}x{img.height}, {os.path.getsize(path) / 1024:.0f} Ko"
        )


if __name__ == "__main__":
    main()
