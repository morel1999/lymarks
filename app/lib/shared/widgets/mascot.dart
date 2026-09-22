import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';

/// Les poses de Lymarks, la mascotte de l'app.
///
/// Une pose par situation, jamais deux à l'écran en même temps. Elle
/// accompagne le vide et l'échec — pas le succès courant : une carte qui se
/// résume normalement n'a pas besoin d'un personnage (`02-ux/03-mascotte.md`).
enum MascotPose {
  /// De face, souriante. Onboarding, et repli de toute pose manquante.
  idle('mascot.png'),

  /// Bras ouverts : une liste vide, une invitation à capturer.
  empty('mascot-empty.png'),

  /// Câble débranché : hors-ligne, patiente, rien n'est perdu.
  offline('mascot-offline.png'),

  /// Haussement d'épaule : Lymarks n'a pas su lire la page.
  puzzled('mascot-puzzled.png'),

  /// Penchée sur une fiche : le résumé est en cours.
  reading('mascot-reading.png'),

  /// Main en visière : la recherche n'a rien trouvé.
  searching('mascot-searching.png'),

  /// Bras levés : un palier franchi. À garder rare, sinon il ne vaut plus rien.
  celebrating('mascot-celebrating.png'),

  /// Assoupie : rien à faire remonter aujourd'hui.
  sleeping('mascot-sleeping.png'),

  /// Salut : la première rencontre, à la connexion.
  waving('mascot-waving.png');

  const MascotPose(this._file);

  final String _file;

  String get asset => 'assets/brand/$_file';
}

/// La mascotte, posée dans un écran et animée d'un flottement lent.
///
/// Elle entretient son propre ticker : contrairement à l'onboarding, où une
/// seule horloge anime toute la page, un état vide n'affiche qu'un sujet.
class MascotFigure extends StatefulWidget {
  const MascotFigure({
    required this.pose,
    this.height = 150,
    this.glow = true,
    super.key,
  });

  final MascotPose pose;

  /// 120 à 180 selon la place ; au-delà elle écrase le texte qu'elle sert.
  final double height;
  final bool glow;

  @override
  State<MascotFigure> createState() => _MascotFigureState();
}

class _MascotFigureState extends State<MascotFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return AnimatedBuilder(
      animation: _wave,
      builder: (context, child) {
        final t = _wave.value * 2 * math.pi;
        return SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.glow)
                Transform.scale(
                  scale: 1 + math.sin(t + math.pi) * 0.05,
                  child: SizedBox.square(
                    dimension: widget.height * 0.9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            ly.primary.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(0, math.sin(t) * 5),
                child: child,
              ),
            ],
          ),
        );
      },
      child: Image.asset(widget.pose.asset, height: widget.height),
    );
  }
}
