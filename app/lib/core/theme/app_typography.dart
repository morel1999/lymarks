import 'package:flutter/material.dart';

/// Échelle typographique Lymarks.
///
/// Inter est **embarqué** (`assets/fonts/`) et non chargé au runtime : le
/// budget de cold start est de 2 s (`08-qualite/02-performance-budget.md`) et
/// aucun appel réseau tiers ne doit être nécessaire pour afficher un écran.
///
/// L'échelle du Design System (display 28 / title 20 / body 15 / caption 12)
/// est conservée, avec un cran `display` à 34 pour les titres d'écran, mesuré
/// sur les maquettes (« Search », « Settings », « Daily Digest »).
abstract final class LyType {
  static const String family = 'Inter';

  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle s(
      double size,
      FontWeight weight, {
      double height = 1.4,
      double spacing = 0,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
        color: color ?? primary,
      );
    }

    return TextTheme(
      // Titres d'écran : « Search », « Daily Digest », « Settings ».
      displayLarge: s(34, FontWeight.w700, height: 1.12, spacing: -0.8),
      // Titres d'onboarding.
      displayMedium: s(28, FontWeight.w700, height: 1.18, spacing: -0.6),
      displaySmall: s(24, FontWeight.w700, height: 1.2, spacing: -0.4),
      // Titres de section : « All Lymarks », « Remember this ».
      headlineSmall: s(20, FontWeight.w700, height: 1.25, spacing: -0.3),
      // Titre d'une carte lymark.
      titleLarge: s(18, FontWeight.w700, height: 1.28, spacing: -0.2),
      titleMedium: s(16, FontWeight.w600, height: 1.3),
      titleSmall: s(15, FontWeight.w600, height: 1.3),
      // Corps de texte : puces de résumé, descriptions.
      bodyLarge: s(15, FontWeight.w400, height: 1.45),
      bodyMedium: s(14, FontWeight.w400, height: 1.45),
      bodySmall: s(13, FontWeight.w400, color: secondary),
      // Boutons et libellés.
      labelLarge: s(15, FontWeight.w600, height: 1.2),
      labelMedium: s(13, FontWeight.w500, height: 1.2),
      // Caption : domaine, « Saved 2 days ago », chips.
      labelSmall: s(12, FontWeight.w500, height: 1.25, color: secondary),
    );
  }
}
