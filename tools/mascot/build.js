// Transforme les poses brutes de la mascotte en assets de l'app.
//
//   node tools/mascot/build.js
//
// Entrée  : app/branding/poses/*.png — rendus du générateur, fond vert uni,
//           mascotte violette (voir 02-ux/03-mascotte.md).
// Sortie  : app/assets/brand/mascot-<pose>.png — détourés, retintés au bleu
//           de l'app, recadrés, à la hauteur d'affichage réelle.
//
// Trois traitements, dans cet ordre :
//   1. incrustation : le vert devient transparent, et le vert qui a bavé sur
//      les contours est retiré (« despill ») ;
//   2. teinte : chaque pose est tournée vers la teinte de la référence, au
//      lieu d'une rotation fixe — deux rendus du même prompt ne sortent
//      jamais exactement du même violet ;
//   3. cadrage : recadré sur le sujet, mis à l'échelle.

const fs = require("node:fs");
const path = require("node:path");
const { decode, encode } = require("./png.js");

const ROOT = path.resolve(__dirname, "..", "..");
const SRC = path.join(ROOT, "app", "branding", "poses");
const OUT = path.join(ROOT, "app", "assets", "brand");
/** La mascotte déjà dans l'app : c'est elle qui donne la teinte de référence. */
const REFERENCE = path.join(OUT, "mascot.png");

/** Hauteur des poses dans l'app : 120 à 180 dp, soit 540 px sur un écran 3x. */
const TARGET_HEIGHT = 560;
/** Marge autour du sujet, en part de sa hauteur. */
const MARGIN = 0.02;

// ---------------------------------------------------------------- couleurs

function rgbToHsl(r, g, b) {
  r /= 255;
  g /= 255;
  b /= 255;
  const mx = Math.max(r, g, b);
  const mn = Math.min(r, g, b);
  const l = (mx + mn) / 2;
  const d = mx - mn;
  if (d === 0) return [0, 0, l];
  const s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
  let h;
  if (mx === r) h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
  else if (mx === g) h = ((b - r) / d + 2) / 6;
  else h = ((r - g) / d + 4) / 6;
  return [h, s, l];
}

function hslToRgb(h, s, l) {
  if (s === 0) {
    const v = Math.round(l * 255);
    return [v, v, v];
  }
  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  const conv = (t) => {
    t = (t + 1) % 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  };
  return [
    Math.round(conv(h + 1 / 3) * 255),
    Math.round(conv(h) * 255),
    Math.round(conv(h - 1 / 3) * 255),
  ];
}

/**
 * Teinte dominante du sujet, en tours.
 *
 * Moyenne **circulaire** : une teinte est un angle, et la moyenne
 * arithmétique de 0,98 et 0,02 donnerait 0,5 — le vert, à l'opposé du rouge
 * qu'on voulait. Chaque pixel pèse sa saturation : un gris n'a pas de teinte
 * à défendre.
 */
function dominantHue({ w, h, px }) {
  let x = 0;
  let y = 0;
  for (let i = 0; i < w * h * 4; i += 4) {
    if (px[i + 3] < 250) continue;
    const [hue, sat] = rgbToHsl(px[i], px[i + 1], px[i + 2]);
    if (sat < 0.18) continue;
    const a = hue * 2 * Math.PI;
    x += Math.cos(a) * sat;
    y += Math.sin(a) * sat;
  }
  return ((Math.atan2(y, x) / (2 * Math.PI)) + 1) % 1;
}

/** Tourne la teinte de chaque pixel opaque de [delta] tours. */
function rotateHue(px, delta) {
  if (Math.abs(delta) < 1e-4) return;
  for (let i = 0; i < px.length; i += 4) {
    if (px[i + 3] === 0) continue;
    const [hue, sat, lum] = rgbToHsl(px[i], px[i + 1], px[i + 2]);
    if (sat === 0) continue;
    const [r, g, b] = hslToRgb((hue + delta + 1) % 1, sat, lum);
    px[i] = r;
    px[i + 1] = g;
    px[i + 2] = b;
  }
}

// ------------------------------------------------------------ incrustation

/** Vrai quand le vert domine franchement : c'est le fond, pas le sujet. */
function isGreen(px, i) {
  const r = px[i];
  const g = px[i + 1];
  const b = px[i + 2];
  return g > 90 && g > r * 1.35 && g > b * 1.35;
}

/**
 * Détoure le fond vert.
 *
 * Le remplissage part des bords plutôt que de teinter tout ce qui est vert :
 * un reflet vert **dans** le sujet resterait ainsi opaque. Sur le contour,
 * l'alpha suit la distance au vert pur, et le « despill » ramène le vert qui
 * a bavé (antialiasing du rendu, puis compression JPEG) au niveau des deux
 * autres canaux.
 */
function key({ w, h, px }) {
  // Certains rendus arrivent déjà détourés, avec un vrai canal alpha : les
  // incruster reviendrait à chercher un vert absent, puis à rendre le fond
  // opaque. On teste les quatre coins — un fond vert y est opaque, un fond
  // transparent ne l'est pas.
  const corners = [0, (w - 1) * 4, (h - 1) * w * 4, (w * h - 1) * 4];
  if (corners.every((i) => px[i + 3] < 8)) {
    return { w, h, px: Buffer.from(px) };
  }

  const bg = new Uint8Array(w * h);
  for (let i = 0, k = 0; k < w * h; k++, i += 4) {
    bg[k] = isGreen(px, i) ? 1 : 0;
  }

  const outside = new Uint8Array(w * h);
  const stack = [];
  for (let x = 0; x < w; x++) stack.push(x, 0, x, h - 1);
  for (let y = 0; y < h; y++) stack.push(0, y, w - 1, y);
  while (stack.length) {
    const y = stack.pop();
    const x = stack.pop();
    if (x < 0 || y < 0 || x >= w || y >= h) continue;
    const k = y * w + x;
    if (outside[k] || !bg[k]) continue;
    outside[k] = 1;
    stack.push(x + 1, y, x - 1, y, x, y + 1, x, y - 1);
  }

  const out = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const k = y * w + x;
      const i = k * 4;
      if (outside[k]) continue;

      let touchesBg = false;
      if (x > 0 && outside[k - 1]) touchesBg = true;
      if (x + 1 < w && outside[k + 1]) touchesBg = true;
      if (y > 0 && outside[k - w]) touchesBg = true;
      if (y + 1 < h && outside[k + w]) touchesBg = true;

      let [r, g, b] = [px[i], px[i + 1], px[i + 2]];
      // Despill : le vert ne dépasse jamais le plus fort des deux autres
      // canaux. Sans cela le sujet garde un liseré fluo.
      const cap = Math.max(r, b);
      const spill = Math.max(0, g - cap);
      if (spill > 0) g = cap + spill * 0.25;

      let alpha = 255;
      if (touchesBg) {
        // Plus le pixel est encore vert, moins il appartient au sujet.
        alpha = Math.max(0, Math.min(255, Math.round(255 - spill * 3)));
      }
      out[i] = r;
      out[i + 1] = g;
      out[i + 2] = b;
      out[i + 3] = alpha;
    }
  }
  return { w, h, px: out };
}

// ----------------------------------------------------------------- cadrage

function bounds({ w, h, px }) {
  let minX = w;
  let maxX = 0;
  let minY = h;
  let maxY = 0;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      if (px[(y * w + x) * 4 + 3] > 24) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  return { minX, maxX, minY, maxY };
}

/** Recadre sur le sujet et met à l'échelle (bilinéaire, alpha prémultiplié). */
function fit(img, box, height) {
  const { w, h, px } = img;
  const bw = box.maxX - box.minX + 1;
  const bh = box.maxY - box.minY + 1;
  const margin = Math.round(bh * MARGIN);
  const scale = height / (bh + margin * 2);
  const outW = Math.round((bw + margin * 2) * scale);
  const outH = height;
  const out = Buffer.alloc(outW * outH * 4);

  for (let y = 0; y < outH; y++) {
    for (let x = 0; x < outW; x++) {
      const sx = box.minX - margin + x / scale;
      const sy = box.minY - margin + y / scale;
      const x0 = Math.floor(sx);
      const y0 = Math.floor(sy);
      const fx = sx - x0;
      const fy = sy - y0;
      let r = 0;
      let g = 0;
      let b = 0;
      let a = 0;
      for (let dy = 0; dy < 2; dy++) {
        for (let dx = 0; dx < 2; dx++) {
          const px0 = Math.max(0, Math.min(w - 1, x0 + dx));
          const py0 = Math.max(0, Math.min(h - 1, y0 + dy));
          const weight = (dx ? fx : 1 - fx) * (dy ? fy : 1 - fy);
          const i = (py0 * w + px0) * 4;
          const alpha = px[i + 3] / 255;
          r += px[i] * alpha * weight;
          g += px[i + 1] * alpha * weight;
          b += px[i + 2] * alpha * weight;
          a += px[i + 3] * weight;
        }
      }
      const i = (y * outW + x) * 4;
      if (a <= 0) continue;
      const alpha = a / 255;
      out[i] = Math.round(r / alpha);
      out[i + 1] = Math.round(g / alpha);
      out[i + 2] = Math.round(b / alpha);
      out[i + 3] = Math.round(a);
    }
  }
  return { w: outW, h: outH, px: out };
}

// -------------------------------------------------------------------- main

const target = dominantHue(decode(fs.readFileSync(REFERENCE)));
console.log(`teinte de référence : ${(target * 360).toFixed(1)}°`);

const files = fs
  .readdirSync(SRC)
  .filter((f) => f.endsWith(".png") && f !== "mascot.png");

for (const file of files) {
  const raw = fs.readFileSync(path.join(SRC, file));
  if (raw.readUInt32BE(0) !== 0x89504e47) {
    console.log(`${file} : ignoré, ce n'est pas un PNG (extension trompeuse)`);
    continue;
  }
  const cut = key(decode(raw));
  const hue = dominantHue(cut);
  let delta = target - hue;
  // Toujours par le plus court chemin sur le cercle des teintes.
  if (delta > 0.5) delta -= 1;
  if (delta < -0.5) delta += 1;
  rotateHue(cut.px, delta);

  const out = fit(cut, bounds(cut), TARGET_HEIGHT);
  const dest = path.join(OUT, file);
  fs.writeFileSync(dest, encode(out));
  console.log(
    `${file} : ${(hue * 360).toFixed(1)}° → rotation ${(delta * 360).toFixed(1)}°` +
      `, ${out.w}x${out.h}, ${Math.round(fs.statSync(dest).size / 1024)} Ko`,
  );
}
