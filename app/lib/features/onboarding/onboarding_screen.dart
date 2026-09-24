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
import 'package:lymarks/features/onboarding/scene.dart';

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
    with TickerProviderStateMixin {
  final PageController _pages = PageController();
  int _index = 0;

  /// Un seul ticker pour toute la page : chaque élément décale sa phase
  /// plutôt que d'entretenir son propre contrôleur.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  /// L'arrivée de la scène en relief : un mouvement d'avant, une seule fois.
  /// Séparé de [_wave], qui boucle, et des entrées de diapositive, qui se
  /// rejouent à chaque passage.
  late final AnimationController _sceneEnter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  /// Avancement du glissement entre les deux écrans, de 0 à 1. Sert à la
  /// parallaxe et au fondu de la scène ; `_index` ne suffirait pas, il
  /// saute d'un cran quand la page est déjà arrivée.
  double get _away {
    if (!_pages.hasClients) return _index.toDouble();
    return (_pages.page ?? _index.toDouble()).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _sceneEnter.dispose();
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
            // Les deux rendus en relief, l'un derrière l'autre. Le premier
            // s'efface en glissant pendant que le second arrive : le ciel
            // peint reste dessous, et c'est lui qu'on voit à mi-course et
            // sur les bords, là où aucun rendu ne porte.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_wave, _sceneEnter, _pages]),
                builder: (_, _) {
                  final away = _away;
                  // Les deux fondus se croisent sur le ciel peint et non
                  // l'un sur l'autre : en se chevauchant à parts égales,
                  // deux mascottes se superposaient au milieu du geste. Le
                  // premier rendu est parti avant que le second n'arrive.
                  final leaving = (1 - away / 0.55).clamp(0.0, 1.0);
                  final coming = ((away - 0.45) / 0.55).clamp(0.0, 1.0);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      OnboardingScene(
                        kind: OnboardingSceneKind.capture,
                        enter: _sceneEnter.value,
                        visible: leaving,
                        slide: -away * 0.22,
                        wave: _wave.value,
                      ),
                      OnboardingScene(
                        kind: OnboardingSceneKind.find,
                        // Son arrivée est le geste lui-même : elle grandit
                        // et se révèle au rythme du doigt, plutôt que de
                        // jouer une animation minutée une fois posée.
                        enter: coming,
                        visible: coming,
                        slide: (1 - away) * 0.22,
                        wave: _wave.value,
                      ),
                    ],
                  );
                },
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
                        _CaptureSlide(active: _index == 0),
                        _FindSlide(active: _index == 1),
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

/// Socle commun aux deux diapositives : la place que prend le rendu, puis
/// un titre et un sous-titre qui montent a l'arrivee.
class _Slide extends StatefulWidget {
  const _Slide({
    required this.active,
    required this.title,
    required this.body,
  });

  /// La diapositive visible. `PageView` construit aussi la voisine : sans ce
  /// drapeau, son entree serait jouee hors champ et deja finie a l'arrivee.
  final bool active;
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
          // La place du rendu, qui occupe le cadre derriere la page. Vide
          // ici, mais reservee : c'est elle qui fait tomber les deux titres
          // a la meme hauteur, sans quoi le texte sauterait pendant le
          // glissement.
          const Spacer(),
          const SizedBox(height: LySpace.xl),
          _Enter(
            enter: _enter,
            delay: 0,
            child: Text(widget.title, style: context.texts.displayLarge),
          ),
          const SizedBox(height: LySpace.l),
          _Enter(
            enter: _enter,
            delay: 0.2,
            child: Text(
              widget.body,
              style: context.texts.bodyLarge?.copyWith(
                color: ly.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: LySpace.xxl),
        ],
      ),
    );
  }
}

/// Entree d'un element : il monte et apparait, avec un retard propre.
class _Enter extends StatelessWidget {
  const _Enter({
    required this.enter,
    required this.delay,
    required this.child,
  });

  /// D'ou l'element vient. Fixe : les deux textes montent, et rien d'autre
  /// ne se sert de cette entree depuis que les illustrations dessinees ont
  /// cede la place aux rendus.
  static const Offset _from = Offset(0, 24);

  final Animation<double> enter;

  /// Part de l'animation deja ecoulee avant que cet element ne bouge.
  final double delay;
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
          offset: _from * (1 - curved.value),
          child: inner,
        ),
      ),
      child: child,
    );
  }
}

/// 01A — Capturer : les liens gravitent autour de la mascotte.
///
/// Sans illustration propre, comme sa voisine : le rendu en relief occupe
/// deja tout le cadre, derriere la page.
class _CaptureSlide extends StatelessWidget {
  const _CaptureSlide({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return _Slide(
      active: active,
      title: 'Capture what\nyou discover.',
      body: 'One tap from any app.\nLymarks reads the page for you.',
    );
  }
}

/// 01B — Retrouver : la mascotte presente la recherche.
class _FindSlide extends StatelessWidget {
  const _FindSlide({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return _Slide(
      active: active,
      title: 'Find it when\nyou need it.',
      body:
          'Summaries, categories, and a search\nthat understands what you '
          'meant.',
    );
  }
}
