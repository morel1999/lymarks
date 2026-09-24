import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';

/// Les deux rendus 3D de l'onboarding.
///
/// Chacun fait 1179 px de large, soit exactement la largeur d'un écran à 3x :
/// ils s'y posent pixel pour pixel, et le téléphone n'a rien à
/// rééchantillonner. Le recadrage, la remise à la teinte de l'app et le
/// détramage ont été faits une fois pour toutes par
/// `tools/onboarding/build.py`, avec des filtres que l'appareil n'aurait pas
/// le temps d'appliquer.
enum OnboardingSceneKind {
  /// Capturer : la mascotte dans le noir, trois liens qui gravitent, un
  /// ruban de lumière. Pleine page, débordant par le haut.
  capture(
    asset: 'assets/brand/onboarding-capture.webp',
    top: -0.012,
    fadeTop: 0,
    fadeBottom: 0.22,
    sides: 0,
    neon: Offset(0.845, 0.262),
    sweep: true,
  ),

  /// Retrouver : la mascotte présente la recherche sur une tablette. Le
  /// rendu d'origine est carré et situé dans une pièce ; il est recadré, son
  /// décor éteint, et ses quatre bords se fondent dans le ciel peint — sans
  /// quoi on verrait le mur coupé net.
  find(
    asset: 'assets/brand/onboarding-find.webp',
    top: 0.073,
    fadeTop: 0.10,
    fadeBottom: 0.20,
    sides: 0.14,
    neon: null,
    sweep: false,
  )
  ;

  const OnboardingSceneKind({
    required this.asset,
    required this.top,
    required this.fadeTop,
    required this.fadeBottom,
    required this.sides,
    required this.neon,
    required this.sweep,
  });

  /// L'asset, exposé pour que les rendus de référence le décodent avant la
  /// capture — `Image.asset` est asynchrone, et l'horloge d'un test est
  /// simulée (voir `_precacheImages` dans `golden_test.dart`).
  final String asset;

  /// Hauteur du bord haut de la scène, en parts de la hauteur d'écran.
  final double top;

  /// Parts de la scène fondues à ses bords, pour qu'elle se raccorde au ciel.
  final double fadeTop;
  final double fadeBottom;
  final double sides;

  /// L'anneau de néon que la mascotte tient, en parts de la scène. Le seul
  /// repère relevé à l'œil de tout le fichier : il tombe sur une zone déjà
  /// lumineuse, où un halo décalé de quelques pixels ne se verrait pas.
  final Offset? neon;

  /// Une bande de lumière traverse la scène. Voir [_ScenePainter._sweep].
  final bool sweep;
}

/// Un rendu 3D, et ce qui le fait vivre.
///
/// L'image est **fixe**. Tout ce qui bouge est peint par-dessus, et rien
/// n'est tracé à l'aveugle sur des coordonnées relevées à l'œil : la lumière
/// qui court sur le ruban est **l'image elle-même**, redessinée en mode
/// additif à travers une bande mobile. Seuls les pixels déjà clairs
/// s'allument ; le ciel sombre reste sombre, puisque 0 + 0 = 0. Impossible
/// de la désaligner.
class OnboardingScene extends StatefulWidget {
  const OnboardingScene({
    required this.kind,
    required this.enter,
    required this.visible,
    required this.slide,
    required this.wave,
    super.key,
  });

  final OnboardingSceneKind kind;

  /// Arrivée, de 0 à 1 : porte le mouvement d'avant.
  final double enter;

  /// Présence à l'écran, de 0 à 1 : porte l'opacité.
  final double visible;

  /// Décalage horizontal, en parts de la largeur. Les deux scènes glissent
  /// moins vite que le texte qui les quitte.
  final double slide;

  /// Phase continue partagée par toute la page, en tours.
  final double wave;

  @override
  State<OnboardingScene> createState() => _OnboardingSceneState();
}

class _OnboardingSceneState extends State<OnboardingScene> {
  ui.Image? _image;
  ImageStream? _stream;

  /// L'image déjà décodée — c'est le cas sous les rendus de référence, qui
  /// la précachent — arrive **pendant** `didChangeDependencies`, donc au
  /// milieu d'une passe de construction : `setState` y lèverait. On pose
  /// alors la valeur, que la construction qui suit lira de toute façon.
  late final ImageStreamListener _listener = ImageStreamListener((info, sync) {
    if (!mounted) return;
    if (sync) {
      _image = info.image;
    } else {
      setState(() => _image = info.image);
    }
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Le painter a besoin d'une `ui.Image` et non d'un widget : le mélange
    // additif passe par `saveLayer`, qu'aucun widget n'expose.
    final stream = AssetImage(
      widget.kind.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    // L'image appartient au cache de Flutter : on ne la libère pas ici.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null || widget.visible <= 0.004) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ScenePainter(
          image: image,
          kind: widget.kind,
          enter: widget.enter,
          visible: widget.visible,
          slide: widget.slide,
          wave: widget.wave,
          palette: context.ly,
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter({
    required this.image,
    required this.kind,
    required this.enter,
    required this.visible,
    required this.slide,
    required this.wave,
    required this.palette,
  });

  final ui.Image image;
  final OnboardingSceneKind kind;
  final double enter;
  final double visible;
  final double slide;
  final double wave;
  final LyPalette palette;

  /// Le vert d'eau du néon, prélevé sur le rendu.
  static const Color _neonInk = Color(0xFF86E7DC);

  @override
  void paint(Canvas canvas, Size size) {
    // L'opacité monte plus vite que le mouvement : à mi-course, une scène
    // encore à demi transparente laisse voir le ciel peint au travers et
    // tout vire au laiteux. Elle devient opaque tôt, et c'est le mouvement
    // d'avant qui continue seul.
    final appear = Curves.easeOutQuart.transform(enter.clamp(0.0, 1.0));
    final opacity = appear * visible.clamp(0.0, 1.0);
    if (opacity <= 0.004) return;

    // Cadrée sur la largeur. En `cover`, un écran plus allongé que le rendu
    // lui mangerait un cinquième de sa largeur — donc le sujet par les bords.
    final width = size.width;
    final height = width * image.height / image.width;
    final dst = Rect.fromLTWH(0, size.height * kind.top, width, height);

    final t = wave * 2 * math.pi;
    final push = Curves.easeOutCubic.transform(enter.clamp(0.0, 1.0));
    // La respiration empêche la caméra de se figer tout à fait.
    final scale = (1 + 0.06 * (1 - push)) * (1 + 0.006 * math.sin(t * 0.5));
    final drift = math.sin(t * 0.5 + 1.1) * 5;

    canvas
      ..saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      )
      ..save()
      ..translate(slide * width, drift)
      ..translate(dst.center.dx, dst.center.dy)
      ..scale(scale)
      ..translate(-dst.center.dx, -dst.center.dy)
      // Couche propre à l'image : c'est son alpha qu'on éteindra aux bords.
      // Poser un aplat de la couleur du fond par-dessus laisserait une
      // couture, parce que le ciel peint n'est pas uni à cette hauteur.
      ..saveLayer(dst, Paint())
      ..drawImageRect(image, _src, dst, _quality);

    _sweep(canvas, dst);
    _neon(canvas, dst);
    _fadeEdges(canvas, dst);

    canvas
      ..restore()
      ..restore();
    // Le voile, lui, ne suit pas la caméra : il protège la lisibilité du
    // titre, qui ne bouge pas.
    _veil(canvas, size, dst.bottom);
    canvas.restore();
  }

  Rect get _src =>
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  Paint get _quality => Paint()..filterQuality = FilterQuality.medium;

  /// La bande de lumière qui traverse le ruban.
  void _sweep(Canvas canvas, Rect dst) {
    // Pendant un glissement, deux scènes sont à l'écran et chacune ouvre
    // déjà ses couches : la lueur, qu'on ne regarde pas à ce moment-là, ne
    // vaut pas la passe de rendu qu'elle coûte.
    if (!kind.sweep || visible < 0.999) return;

    /// Part du cycle pendant laquelle la bande est à l'écran. Le reste du
    /// temps, la scène est au repos : une lueur qui balaie sans arrêt
    /// cesserait d'être un événement.
    const pass = 0.42;
    const half = 0.22;

    final phase = wave % 1;
    if (phase > pass) return;
    final centre = (phase / pass) * (1 + half * 2) - half;

    canvas
      ..saveLayer(dst, Paint()..blendMode = BlendMode.plus)
      ..drawImageRect(
        image,
        _src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Colors.white.withValues(alpha: 0.5),
      )
      ..drawRect(
        dst,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: const [
              Colors.transparent,
              Colors.white,
              Colors.transparent,
            ],
            stops: [
              (centre - half).clamp(0.0, 1.0),
              centre.clamp(0.0, 1.0),
              (centre + half).clamp(0.0, 1.0),
            ],
          ).createShader(dst),
      )
      ..restore();
  }

  /// Le néon respire, à son propre rythme.
  void _neon(Canvas canvas, Rect dst) {
    final at = kind.neon;
    if (at == null) return;

    final centre = Offset(
      dst.left + dst.width * at.dx,
      dst.top + dst.height * at.dy,
    );
    final radius = dst.width * 0.17;
    final pulse = 0.5 + 0.5 * math.sin(wave * 2 * math.pi * 1.5);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            _neonInk.withValues(alpha: 0.06 + 0.08 * pulse),
            _neonInk.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  /// Éteint l'alpha de la scène à ses bords, pour qu'elle se fonde dans le
  /// ciel peint au lieu d'y être posée comme une photographie.
  void _fadeEdges(Canvas canvas, Rect dst) {
    canvas.drawRect(
      dst,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, kind.fadeTop, 1 - kind.fadeBottom, 1],
        ).createShader(dst),
    );
    if (kind.sides <= 0) return;
    canvas.drawRect(
      dst,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = LinearGradient(
          colors: const [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, kind.sides, 1 - kind.sides, 1],
        ).createShader(dst),
    );
  }

  /// Assombrit ce que le titre recouvre.
  ///
  /// Accroché au bas de la scène et non au bas de l'écran : sur un écran
  /// court, le rendu monte jusque sous le titre et c'est là qu'il faut
  /// protéger la lecture ; sur un écran long il s'arrête bien avant, et le
  /// voile n'a presque rien à faire.
  void _veil(Canvas canvas, Size size, double bottom) {
    final rect = Rect.fromLTRB(0, bottom * 0.45, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.surface.withValues(alpha: 0),
            palette.surface.withValues(alpha: 0.72),
            palette.surface.withValues(alpha: 0.92),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.image != image ||
      old.kind != kind ||
      old.enter != enter ||
      old.visible != visible ||
      old.slide != slide ||
      old.wave != wave ||
      old.palette != palette;
}
