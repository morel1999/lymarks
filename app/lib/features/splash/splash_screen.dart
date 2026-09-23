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
/// Elle prolonge l'écran de lancement du système plutôt que de le remplacer :
/// même bleu nuit (`ly_navy`, celui de l'icône adaptative), même mascotte au
/// même endroit — celle qui salue, comme à la connexion : c'est la même
/// première rencontre. Elle naît d'un point (0,05) et grandit jusqu'à sa
/// taille : le regard a quelque chose à suivre dès la première frame, au
/// lieu d'un fond nu le temps qu'elle paraisse.
///
/// L'entrée tient dans le premier tiers, le reste est une pause : l'écran
/// s'annonce vite et se laisse regarder, au lieu de s'étirer mollement sur
/// toute la durée. La durée vient d'un provider, que les tests ramènent à
/// zéro — sans quoi chaque test paierait l'attente avant d'atteindre son
/// écran.
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

  /// La mascotte se pose, puis le nom paraît : deux temps, jamais ensemble.
  /// Les deux sont finis à un tiers du chemin ; ce qui suit est la pause.
  late final Animation<double> _mascot = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0, 0.22, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0.14, 0.34, curve: Curves.easeOut),
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
        child: AnimatedBuilder(
          animation: _enter,
          builder: (context, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: _mascot.value,
                child: Transform.scale(
                  scale: 0.05 + _mascot.value * 0.95,
                  child: child,
                ),
              ),
              const SizedBox(height: LySpace.xl),
              Opacity(
                opacity: _wordmark.value,
                child: Transform.translate(
                  offset: Offset(0, (1 - _wordmark.value) * 8),
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
              ),
            ],
          ),
          // Hors du builder : l'image est décodée une fois, pas à chaque frame.
          child: const MascotFigure(
            pose: MascotPose.waving,
            height: 148,
            glow: false,
          ),
        ),
      ),
    );
  }
}
