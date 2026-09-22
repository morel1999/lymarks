import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';

/// Lymarks, la mascotte de l'app.
///
/// Un seul rendu, `assets/brand/mascot.png` : toutes les mises en scène
/// viennent de la composition autour d'elle, jamais d'un second fichier.
/// Elle flotte doucement — le mouvement est porté par [wave], une phase
/// continue en tours (0 → 1 → 2…) fournie par l'écran, pour qu'un seul
/// ticker anime toute la page.
class Mascot extends StatelessWidget {
  const Mascot({
    required this.height,
    required this.wave,
    this.phase = 0,
    this.drift = 10,
    this.tilt = 0.02,
    this.glow = true,
    super.key,
  });

  static const String asset = 'assets/brand/mascot.png';

  /// Hauteur du rendu, glow exclu.
  final double height;

  /// Phase d'animation partagée, en tours.
  final double wave;

  /// Décalage de phase : deux éléments ne respirent pas ensemble.
  final double phase;

  /// Amplitude verticale du flottement, en pixels.
  final double drift;

  /// Amplitude de l'inclinaison, en radians.
  final double tilt;

  /// Halo derrière la mascotte. Coupé quand elle passe derrière une carte :
  /// le halo trahirait le masque.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final t = (wave + phase) * 2 * math.pi;
    final dy = math.sin(t) * drift;
    final angle = math.sin(t * 0.7) * tilt;

    return SizedBox(
      height: height,
      width: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow)
            // Le halo respire à contretemps du flottement : la lueur gonfle
            // quand la mascotte redescend.
            Transform.scale(
              scale: 1 + math.sin(t + math.pi) * 0.06,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ly.primary.withValues(alpha: 0.38),
                      ly.gradientBottom.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: angle,
              child: Image.asset(asset, height: height),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de lien capturé, telle qu'elle apparaît dans l'app : vignette de
/// source, titre, domaine. Sert de décor animé dans l'onboarding.
class OnboardingLinkCard extends StatelessWidget {
  const OnboardingLinkCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.domain,
    required this.width,
    super.key,
  });

  final LyAccent accent;
  final IconData icon;
  final String title;
  final String domain;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ly.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ly.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.fill,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: accent.onFill),
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
                  style: context.texts.labelMedium?.copyWith(
                    color: ly.textPrimary,
                  ),
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
        ],
      ),
    );
  }
}

/// Pastille de catégorie colorée, en éventail derrière la mascotte.
class OnboardingCategoryCard extends StatelessWidget {
  const OnboardingCategoryCard({
    required this.accent,
    required this.icon,
    required this.label,
    required this.count,
    required this.width,
    super.key,
  });

  final LyAccent accent;
  final IconData icon;
  final String label;
  final int count;
  final double width;

  @override
  Widget build(BuildContext context) {
    // `onFill` est l'encre du fond pale ; ici la carte est remplie de
    // `strong`, une couleur vive : il lui faut l'encre profonde du theme.
    final ink = context.ly.gradientTop;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.strong,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accent.strong.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelMedium?.copyWith(color: ink),
            ),
          ),
          Text(
            '$count',
            style: context.texts.labelSmall?.copyWith(
              color: ink.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
