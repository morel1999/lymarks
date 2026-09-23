import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/theme/app_theme.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/features/onboarding/mascot.dart';

/// Onboarding — deux écrans, pas un tutoriel (wireframe 01).
///
/// L'utilisateur doit comprendre deux choses : capturer un lien ne coûte
/// qu'un geste, et le retrouver ne demande pas de s'en souvenir.
///
/// **Toujours en sombre**, quel que soit le thème du téléphone : c'est le
/// seul moment cinématique de l'app, celui où la mascotte et le bleu nuit
/// portent l'identité. Le reste de l'app suit le système.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pages = PageController();
  int _index = 0;

  /// Un seul ticker pour toute la page : chaque élément décale sa phase
  /// plutôt que d'entretenir son propre contrôleur.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    _pages.dispose();
    super.dispose();
  }

  /// Déjà connecté (retour dans l'app, mode démo) : droit à la Home ; sinon
  /// la connexion, dont le routeur ressort vers la Home une fois la session
  /// ouverte.
  void _finish() => context.go(
    ref.read(authSessionProvider).isSignedIn ? LyRoute.home : LyRoute.signIn,
  );

  void _next() {
    if (_index == 0) {
      unawaited(
        _pages.animateToPage(
          1,
          duration: LyMotion.list,
          curve: LyMotion.listCurve,
        ),
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Thème sombre imposé : `context.ly` sous cet écran rend la palette
    // nocturne, y compris si le téléphone est en clair.
    return Theme(
      data: LyTheme.dark(),
      child: Builder(builder: _buildDark),
    );
  }

  Widget _buildDark(BuildContext context) {
    final ly = context.ly;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: ly.surface,
      ),
      child: Scaffold(
        backgroundColor: ly.surface,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _wave,
                builder: (_, _) => CustomPaint(
                  painter: _NightBackdrop(palette: ly, wave: _wave.value),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _header(context),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (i) => setState(() => _index = i),
                      children: [
                        _CaptureSlide(wave: _wave, active: _index == 0),
                        _FindSlide(wave: _wave, active: _index == 1),
                      ],
                    ),
                  ),
                  _footer(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final ly = context.ly;
    return Padding(
      padding: const EdgeInsets.fromLTRB(LySpace.xl, LySpace.l, LySpace.l, 0),
      child: Row(
        children: [
          Text('Lymarks', style: context.texts.titleLarge),
          const Spacer(),
          TextButton(
            onPressed: _finish,
            child: Text(
              'Skip',
              style: context.texts.labelMedium?.copyWith(
                color: ly.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final ly = context.ly;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LySpace.xl,
        0,
        LySpace.xl,
        LySpace.xl,
      ),
      child: Column(
        children: [
          FilledButton(
            onPressed: _next,
            // « Next » puis « Get started » : le premier bouton fait
            // tourner une page, le second entre dans l'app. Nommer les deux
            // par une promesse — « Get started », « Start saving » —
            // laissait croire que le premier ouvrait déjà l'app.
            child: Text(_index == 0 ? 'Next' : 'Get started'),
          ),
          const SizedBox(height: LySpace.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 2; i++)
                AnimatedContainer(
                  duration: LyMotion.micro,
                  margin: const EdgeInsets.symmetric(horizontal: LySpace.xs),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? ly.primary : ly.cardBorder,
                    borderRadius: LyRadius.pillR,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fond de nuit : le dégradé d'identité, plus deux lueurs qui dérivent.
///
/// Peint plutôt qu'empilé en widgets : deux `RadialGradient` dans un
/// `CustomPaint` coûtent une passe, là où deux `Container` flous en
/// coûteraient trois.
class _NightBackdrop extends CustomPainter {
  const _NightBackdrop({required this.palette, required this.wave});

  final LyPalette palette;
  final double wave;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.gradientTop, palette.surface],
        ).createShader(rect),
    );

    final t = wave * 2 * math.pi;
    _stars(canvas, size);
    _glow(
      canvas,
      size,
      center: Offset(
        size.width * (0.24 + math.sin(t) * 0.05),
        size.height * (0.26 + math.cos(t) * 0.03),
      ),
      radius: size.width * 0.62,
      color: palette.gradientBottom.withValues(alpha: 0.42),
    );
    _glow(
      canvas,
      size,
      center: Offset(
        size.width * (0.82 + math.cos(t * 0.8) * 0.05),
        size.height * (0.4 + math.sin(t * 0.8) * 0.04),
      ),
      radius: size.width * 0.5,
      color: palette.primary.withValues(alpha: 0.16),
    );
  }

  /// Le ciel : des éclats à quatre branches concaves, la forme qu'on dessine
  /// pour dire « nuit », et une poussière d'étoiles derrière. Chacun a sa
  /// phase, sinon le ciel clignerait d'un seul œil.
  ///
  /// Positions relatives, tenues dans le haut de l'écran : sous le titre,
  /// une étoile passerait pour une coquille de rendu.
  static const List<(double, double, double, double)> _sky = [
    // x, y (relatifs), rayon en px, phase du scintillement (en tours)
    (0.13, 0.07, 7, 0),
    (0.87, 0.12, 5.5, 0.34),
    (0.70, 0.04, 3.5, 0.66),
    (0.24, 0.24, 3, 0.48),
    (0.94, 0.33, 4.5, 0.12),
    (0.05, 0.37, 2.5, 0.82),
    (0.52, 0.02, 2.5, 0.22),
    (0.36, 0.16, 2, 0.58),
    (0.78, 0.26, 2, 0.92),
  ];

  /// Poussière : de simples points, trop petits pour porter une forme.
  static const List<(double, double, double)> _dust = [
    (0.30, 0.05, 0.15),
    (0.44, 0.12, 0.55),
    (0.62, 0.18, 0.3),
    (0.17, 0.19, 0.75),
    (0.83, 0.07, 0.45),
    (0.09, 0.28, 0.9),
    (0.68, 0.34, 0.62),
    (0.41, 0.30, 0.08),
  ];

  void _stars(Canvas canvas, Size size) {
    final ink = palette.chromeSoft;

    for (final (fx, fy, phase) in _dust) {
      final twinkle = _twinkle(phase, 1.6);
      canvas.drawCircle(
        Offset(size.width * fx, size.height * fy),
        1.1,
        Paint()..color = ink.withValues(alpha: 0.10 + twinkle * 0.35),
      );
    }

    for (final (fx, fy, radius, phase) in _sky) {
      final twinkle = _twinkle(phase, 2);
      final center = Offset(size.width * fx, size.height * fy);
      final scale = 0.55 + twinkle * 0.45;

      canvas
        // Halo : c'est lui qui fait « brillant » ; l'éclat seul serait plat.
        ..drawCircle(
          center,
          radius * 2.6 * scale,
          Paint()
            ..color = ink.withValues(alpha: 0.05 + twinkle * 0.16)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 1.1),
        )
        ..save()
        ..translate(center.dx, center.dy)
        ..drawPath(
          _spark(radius * scale),
          Paint()..color = ink.withValues(alpha: 0.45 + twinkle * 0.55),
        )
        ..restore();
    }
  }

  /// Scintillement dans [0, 1], [cycles] battements par tour de [wave].
  double _twinkle(double phase, double cycles) =>
      0.5 + 0.5 * math.sin((wave * cycles + phase) * 2 * math.pi);

  /// Éclat à quatre branches : quatre courbes dont les points de contrôle,
  /// ramenés près du centre, creusent les côtés. Plus le contrôle est bas,
  /// plus les branches sont fines.
  static Path _spark(double r) {
    final c = r * 0.22;
    return Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(c, -c, r, 0)
      ..quadraticBezierTo(c, c, 0, r)
      ..quadraticBezierTo(-c, c, -r, 0)
      ..quadraticBezierTo(-c, -c, 0, -r)
      ..close();
  }

  void _glow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_NightBackdrop old) =>
      old.wave != wave || old.palette != palette;
}

/// Socle commun aux deux diapositives : une illustration qui se réduit sur
/// les écrans courts, un titre, un sous-titre.
class _Slide extends StatefulWidget {
  const _Slide({
    required this.active,
    required this.illustration,
    required this.title,
    required this.body,
  });

  /// La diapositive visible. `PageView` construit aussi la voisine : sans ce
  /// drapeau, son entrée serait jouée hors champ et déjà finie à l'arrivée.
  final bool active;

  /// Reçoit l'avancement de l'entrée (0 → 1) pour décaler ses éléments.
  final Widget Function(BuildContext context, Animation<double> enter)
  illustration;
  final String title;
  final String body;

  @override
  State<_Slide> createState() => _SlideState();
}

class _SlideState extends State<_Slide> with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) unawaited(_enter.forward());
  }

  @override
  void didUpdateWidget(_Slide old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) unawaited(_enter.forward(from: 0));
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LySpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dessinée à taille fixe puis réduite : la composition ne se
          // recalcule pas d'un écran à l'autre, elle se met à l'échelle.
          // `Expanded` lui donne toute la place restante et `scaleDown` la
          // rétrécit sur un écran court sans jamais l'agrandir au-delà de sa
          // taille de dessin — c'est ce qui evite un débordement.
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: _designWidth,
                  height: _designHeight,
                  child: widget.illustration(context, _enter),
                ),
              ),
            ),
          ),
          const SizedBox(height: LySpace.xl),
          Text(widget.title, style: context.texts.displayLarge),
          const SizedBox(height: LySpace.l),
          Text(
            widget.body,
            style: context.texts.bodyLarge?.copyWith(color: ly.textSecondary),
          ),
          const SizedBox(height: LySpace.xxl),
        ],
      ),
    );
  }
}

/// Toile de référence des deux illustrations.
const double _designWidth = 320;
const double _designHeight = 300;

/// Entrée d'un élément : il monte et apparaît, avec un retard propre.
class _Enter extends StatelessWidget {
  const _Enter({
    required this.enter,
    required this.delay,
    required this.child,
    this.from = const Offset(0, 24),
  });

  final Animation<double> enter;

  /// Part de l'animation déjà écoulée avant que cet élément ne bouge.
  final double delay;
  final Offset from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: enter,
      curve: Interval(delay, math.min(1, delay + 0.6), curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (_, inner) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: from * (1 - curved.value),
          child: inner,
        ),
      ),
      child: child,
    );
  }
}

/// 01A — Capturer : les liens viennent à la mascotte.
class _CaptureSlide extends StatelessWidget {
  const _CaptureSlide({required this.wave, required this.active});

  final Animation<double> wave;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return _Slide(
      active: active,
      title: 'Capture what\nyou discover.',
      body: 'One tap from any app.\nLymarks reads the page for you.',
      illustration: (context, enter) {
        final ly = context.ly;
        return AnimatedBuilder(
          animation: wave,
          builder: (context, _) => Stack(
            children: [
              // La mascotte tient la droite de la toile : les cartes
              // arrivent par la gauche et passent devant son corps, jamais
              // devant son visage — c'est lui qui porte l'écran.
              Positioned(
                left: 136,
                top: 34,
                child: Mascot(height: 182, wave: wave.value),
              ),
              Positioned(
                left: 0,
                top: 6,
                child: _Float(
                  wave: wave.value,
                  phase: 0.1,
                  child: _Enter(
                    enter: enter,
                    delay: 0.15,
                    child: OnboardingLinkCard(
                      accent: ly.pink,
                      icon: LyIcons.openExternal,
                      title: 'Awesome video',
                      domain: 'youtube.com',
                      width: 176,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 92,
                child: _Float(
                  wave: wave.value,
                  phase: 0.45,
                  child: _Enter(
                    enter: enter,
                    delay: 0.3,
                    child: OnboardingLinkCard(
                      accent: ly.blue,
                      icon: LyIcons.bookmark,
                      title: 'Design ideas',
                      domain: 'pinterest.com',
                      width: 158,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                bottom: 10,
                child: _Float(
                  wave: wave.value,
                  phase: 0.75,
                  child: _Enter(
                    enter: enter,
                    delay: 0.45,
                    child: OnboardingLinkCard(
                      accent: ly.lime,
                      icon: LyIcons.note,
                      title: 'Interesting article',
                      domain: 'medium.com',
                      width: 178,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 01B — Retrouver : la recherche devant, les catégories autour, la mascotte
/// qui dépasse derrière.
class _FindSlide extends StatelessWidget {
  const _FindSlide({required this.wave, required this.active});

  final Animation<double> wave;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return _Slide(
      active: active,
      title: 'Find it when\nyou need it.',
      body:
          'Summaries, categories, and a search\nthat understands what you '
          'meant.',
      illustration: (context, enter) {
        final ly = context.ly;
        return AnimatedBuilder(
          animation: wave,
          builder: (context, _) => Stack(
            children: [
              // La mascotte passe derrière la carte : le halo est coupé, il
              // trahirait le fait qu'elle est simplement posée dessous.
              Positioned(
                left: 92,
                top: 26,
                child: Mascot(
                  height: 150,
                  wave: wave.value,
                  glow: false,
                  drift: 6,
                ),
              ),
              Positioned(
                left: 0,
                top: 4,
                child: _Float(
                  wave: wave.value,
                  phase: 0.3,
                  child: _Enter(
                    enter: enter,
                    delay: 0.1,
                    from: const Offset(-18, 0),
                    child: OnboardingCategoryCard(
                      accent: ly.lime,
                      icon: LyIcons.sparkle,
                      label: 'AI',
                      count: 24,
                      width: 108,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 52,
                child: _Float(
                  wave: wave.value,
                  phase: 0.65,
                  child: _Enter(
                    enter: enter,
                    delay: 0.2,
                    from: const Offset(18, 0),
                    child: OnboardingCategoryCard(
                      accent: ly.yellow,
                      icon: LyIcons.collection,
                      label: 'Design',
                      count: 12,
                      width: 112,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 0,
                child: _Enter(
                  enter: enter,
                  delay: 0.35,
                  child: const _SearchPreview(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// La barre de recherche et deux résultats, tels qu'ils sortent de l'app.
class _SearchPreview extends StatelessWidget {
  const _SearchPreview();

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ly.card,
        borderRadius: LyRadius.cardR,
        border: Border.all(color: ly.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ly.chipFill,
              borderRadius: LyRadius.pillR,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'that post about money',
                    style: context.texts.labelMedium?.copyWith(
                      color: ly.textSecondary,
                    ),
                  ),
                ),
                Icon(LyIcons.search, size: 15, color: ly.primary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _ResultRow(
            accent: ly.blue,
            icon: LyIcons.bookmark,
            title: 'Design inspiration',
            domain: 'pinterest.com',
          ),
          const SizedBox(height: 8),
          _ResultRow(
            accent: ly.steel,
            icon: LyIcons.note,
            title: 'AI tools list',
            domain: 'notion.so',
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.accent,
    required this.icon,
    required this.title,
    required this.domain,
  });

  final LyAccent accent;
  final IconData icon;
  final String title;
  final String domain;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accent.fill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: accent.onFill),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelMedium,
              ),
              Text(
                domain,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelSmall?.copyWith(
                  color: ly.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Icon(LyIcons.forward, size: 14, color: ly.textTertiary),
      ],
    );
  }
}

/// Flottement lent d'un élément de décor, désynchronisé par [phase].
class _Float extends StatelessWidget {
  const _Float({
    required this.wave,
    required this.phase,
    required this.child,
  });

  /// Amplitude du flottement des cartes : plus courte que celle de la
  /// mascotte, le décor ne doit pas lui voler la vedette.
  static const double amplitude = 6;

  final double wave;
  final double phase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dy = math.sin((wave + phase) * 2 * math.pi) * amplitude;
    return Transform.translate(offset: Offset(0, dy), child: child);
  }
}
