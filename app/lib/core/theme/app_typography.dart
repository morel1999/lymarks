import 'package:flutter/material.dart';

/// Échelle typographique Lymarks.
///
/// Inter est **embarqué** (`assets/fonts/`) et non chargé au runtime : le
/// budget de cold start est de 2 s (`08-qualite/02-performance-budget.md`) et
/// aucun appel réseau tiers ne doit être nécessaire pour afficher un écran.
///
/// C'est la **version variable** : un fichier unique (876 Ko) au lieu des
/// quatre statiques (1,3 Mo), portant deux axes.
///
/// - `wght` 100→900, continu. On n'est plus enfermé dans quatre crans ; les
///   valeurs employées restent celles du Design System, mais un titre plus
///   gras ne coûte plus un fichier de plus.
/// - `opsz` 14→32, la **taille optique** : le dessin s'adapte à la taille à
///   laquelle il sera lu. Aux grandes tailles les lettres se resserrent et
///   le contraste monte ; aux petites elles s'ouvrent et s'espacent. C'est
///   ce qui fait qu'un titre de 34 et une date de 12 ne sont plus la même
///   forme agrandie ou réduite, mais deux dessins justes.
///
/// L'échelle du Design System (display 28 / title 20 / body 15 / caption 12)
/// est conservée, avec un cran `display` à 34 pour les titres d'écran, mesuré
/// sur les maquettes (« Search », « Settings », « Daily Digest »).
abstract final class LyType {
  static const String family = 'Inter';

  /// Bornes de l'axe de taille optique, lues dans la table `fvar` du
  /// fichier. Une valeur hors bornes serait ramenée par le moteur ; on la
  /// ramène ici pour que le style dise la vérité sur ce qu'il demande.
  static const double _opszMin = 14;
  static const double _opszMax = 32;

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
        // `fontWeight` reste renseigné : il sert au repli si l'asset venait
        // à manquer, et c'est lui que lisent les outils d'accessibilité.
        // `fontVariations` est ce qui pilote réellement la police variable.
        fontWeight: weight,
        fontVariations: [
          FontVariation('wght', weight.value.toDouble()),
          // La taille optique suit la taille du texte : c'est tout le
          // principe de l'axe, et ça évite d'avoir à la régler à la main
          // style par style.
          FontVariation('opsz', size.clamp(_opszMin, _opszMax)),
        ],
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
      // Corps de texte : puces de résumé, descriptions. Interligne 1,5 —
      // le texte long respire, et c'est l'air entre les lignes qu'on
      // perçoit avant le dessin des lettres.
      bodyLarge: s(15, FontWeight.w400, height: 1.5),
      bodyMedium: s(14, FontWeight.w400, height: 1.5),
      bodySmall: s(13, FontWeight.w400, height: 1.5, color: secondary),
      // Boutons et libellés.
      labelLarge: s(15, FontWeight.w600, height: 1.2),
      labelMedium: s(13, FontWeight.w500, height: 1.2),
      // Caption : domaine, « Saved 2 days ago », chips. En regular et non
      // en medium : ces lignes accompagnent, elles ne réclament pas. Le
      // gris secondaire portait déjà le retrait, la graisse le contredisait.
      labelSmall: s(12, FontWeight.w400, height: 1.25, color: secondary),
    );
  }
}
