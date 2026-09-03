import 'package:flutter/widgets.dart';

/// Grille 4 pt du Design System (`02-ux/02-design-system.md`).
abstract final class LySpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Marge horizontale d'écran.
  static const double screen = 16;

  /// Hauteur réservée à la barre de navigation flottante.
  static const double navBarInset = 96;
}

/// Rayons du Design System.
abstract final class LyRadius {
  static const double button = 12;
  static const double card = 16;
  static const double tile = 14;
  static const double hero = 24;
  static const double sheet = 24;
  static const double pill = 999;

  static const BorderRadius cardR = BorderRadius.all(Radius.circular(card));
  static const BorderRadius heroR = BorderRadius.all(Radius.circular(hero));
  static const BorderRadius tileR = BorderRadius.all(Radius.circular(tile));
  static const BorderRadius pillR = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetR = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Durées et courbes. UX Bible règle 8 : rien au-dessus de 250 ms.
abstract final class LyMotion {
  /// Micro-interactions : tap, pression, bascule.
  static const Duration micro = Duration(milliseconds: 120);

  /// Transitions de liste et de page.
  static const Duration list = Duration(milliseconds: 200);

  /// Bottom sheets (plafond absolu du Design System).
  static const Duration sheet = Duration(milliseconds: 250);

  /// Boucle du shimmer de l'état `processing`.
  static const Duration shimmer = Duration(milliseconds: 1200);

  static const Curve microCurve = Curves.easeOut;
  static const Curve listCurve = Curves.easeInOutCubic;
}

/// Tailles d'icônes Lucide (Design System : 20/24, trait 1,75).
abstract final class LyIconSize {
  static const double small = 16;
  static const double regular = 20;
  static const double large = 24;

  /// Épaisseur de trait Lucide.
  static const double stroke = 1.75;
}
