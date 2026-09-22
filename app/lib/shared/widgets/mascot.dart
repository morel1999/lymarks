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
  waving('mascot-waving.png')
  ;

  const MascotPose(this._file);

  final String _file;

  String get asset => 'assets/brand/$_file';
}

/// La mascotte, posée dans un écran.
///
/// **Immobile.** Elle apparaît là où l'utilisateur vient de buter — une liste
/// vide, une page illisible, une recherche sans résultat — et un personnage
/// qui flotte pendant qu'on lit un message d'échec attire l'œil au lieu de
/// l'accompagner. Seul l'onboarding l'anime, parce que c'est le seul endroit
/// où elle est le sujet : `features/onboarding/mascot.dart` a son propre
/// widget, mené par l'horloge unique de la page.
///
/// Sans ticker, un rendu de référence capture toujours la même image ; avec,
/// il figeait la frame atteinte après huit `pump`.
class MascotFigure extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ly = context.ly;

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow)
            SizedBox.square(
              dimension: height * 0.9,
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
          Image.asset(pose.asset, height: height),
        ],
      ),
    );
  }
}
