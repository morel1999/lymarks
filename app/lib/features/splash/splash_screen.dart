import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/widgets/mascot.dart';

/// Ouverture de l'app.
///
/// Elle ne remplace pas l'écran de lancement du système : elle **continue**
/// le dessin que la fenêtre porte déjà. `launch_background.xml` pose le même
/// bleu nuit et la même mascotte — même pose, 148dp, remontée de 28dp pour
/// laisser la place au nom. Quand Flutter prend la main, la mascotte est
/// déjà là et ne bouge pas : rien ne clignote, rien ne saute, seul le nom
/// paraît sous elle.
///
/// C'est pour ça que la mascotte n'est pas animée ici. Une entrée en
/// fondu ou en échelle serait un mouvement de trop : elle passerait pour un
/// raté d'affichage, puisque l'utilisateur la regardait déjà.
///
/// La durée vient d'un provider, que les tests ramènent à zéro — sans quoi
/// chaque test paierait l'attente avant d'atteindre son écran.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Le bleu nuit de la marque. En dur : cet écran ne suit pas le thème, il
  /// suit l'icône, et l'icône ne change pas avec le mode sombre.
  static const Color navy = Color(0xFF0D1F3C);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter =
      AnimationController(
        vsync: this,
        duration: ref.read(splashDurationProvider),
      )..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        // Après la frame : une durée nulle (les tests) termine l'animation
        // dès `initState`, et le routeur ne peut pas naviguer pendant la
        // construction de l'arbre.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(LyRoute.onboarding);
        });
      });

  /// Le nom paraît sous la mascotte, dans le premier quart ; ce qui suit
  /// est une pause, le temps de le lire.
  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0, 0.25, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_enter.forward());
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashScreen.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ni opacité ni échelle : elle est déjà à l'écran, posée par la
            // fenêtre. Les 148dp et la pose sont ceux de
            // `launch_background.xml`, et la gouttière ci-dessous entre dans
            // le calcul des 28dp dont le dessin natif la remonte.
            const MascotFigure(
              pose: MascotPose.waving,
              height: 148,
              glow: false,
            ),
            const SizedBox(height: LySpace.xl),
            AnimatedBuilder(
              animation: _wordmark,
              builder: (context, child) => Opacity(
                opacity: _wordmark.value,
                child: Transform.translate(
                  offset: Offset(0, (1 - _wordmark.value) * 8),
                  child: child,
                ),
              ),
              child: const Text(
                'Lymarks',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
