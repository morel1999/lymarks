import 'package:flutter/material.dart';

/// Une famille d'accent : un fond doux, une teinte saturée, un texte lisible.
///
/// Les cinq familles constituent la couleur du produit. Elles ne sont pas
/// décoratives : chaque catégorie, cluster et tuile colorée pioche dedans de
/// façon déterministe (voir [LyPalette.accentFor]) pour qu'un même sujet garde
/// la même couleur d'un écran à l'autre.
@immutable
class LyAccent {
  const LyAccent({
    required this.fill,
    required this.strong,
    required this.onFill,
  });

  /// Interpolation entre deux familles, pour l'animation de thème.
  factory LyAccent.lerp(LyAccent a, LyAccent b, double t) => LyAccent(
        fill: Color.lerp(a.fill, b.fill, t)!,
        strong: Color.lerp(a.strong, b.strong, t)!,
        onFill: Color.lerp(a.onFill, b.onFill, t)!,
      );

  /// Fond des grandes surfaces (cartes catégorie, tuiles, hero).
  final Color fill;

  /// Teinte saturée : points de parcours, barres, indicateurs, bordures.
  final Color strong;

  /// Texte et icônes posés sur [fill].
  final Color onFill;
}

/// Tokens de couleur Lymarks.
///
/// Toutes les valeurs `light` sont **échantillonnées sur les maquettes de
/// référence**, pas inventées :
///   * base, navigation, primaire -> `Ecran/Accueil de curation des
///     connaissances IA.png` ;
///   * accents saturés (`strong`) -> `Ecran/Parcours IA pastel sur mobile.png`.
///
/// Les valeurs `dark` en sont dérivées (fonds profonds teintés, accents
/// éclaircis) car aucune maquette sombre n'existe à ce jour.
///
/// Voir `02-ux/02-design-system.md`.
@immutable
class LyPalette extends ThemeExtension<LyPalette> {
  const LyPalette({
    required this.surface,
    required this.card,
    required this.cardBorder,
    required this.navSurface,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.chipFill,
    required this.chipText,
    required this.badgeInk,
    required this.onBadgeInk,
    required this.success,
    required this.warning,
    required this.danger,
    required this.skeleton,
    required this.skeletonHighlight,
    required this.lime,
    required this.lavender,
    required this.blue,
    required this.yellow,
    required this.pink,
  });

  /// Palette claire : l'écran Home est la source de vérité.
  static const LyPalette light = LyPalette(
    surface: Color(0xFFFAFAFD),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFEDEDF2),
    navSurface: Color(0xFFEEEBFD),
    primary: Color(0xFF4A35E8),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFEDE9FE),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    chipFill: Color(0xFFF4F4F5),
    chipText: Color(0xFF3F3F46),
    badgeInk: Color(0xFF171717),
    onBadgeInk: Color(0xFFFFFFFF),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    skeleton: Color(0xFFF1F1F5),
    skeletonHighlight: Color(0xFFFAFAFC),
    lime: LyAccent(
      fill: Color(0xFFEDF9CC),
      strong: Color(0xFFC3E91C),
      onFill: Color(0xFF2F3D06),
    ),
    lavender: LyAccent(
      fill: Color(0xFFEDE8FC),
      strong: Color(0xFF8C58D6),
      onFill: Color(0xFF2B1B4D),
    ),
    blue: LyAccent(
      fill: Color(0xFFDAF3FD),
      strong: Color(0xFF72D7F3),
      onFill: Color(0xFF0B3A4A),
    ),
    yellow: LyAccent(
      fill: Color(0xFFFDF7D3),
      strong: Color(0xFFFDDB71),
      onFill: Color(0xFF3E3005),
    ),
    pink: LyAccent(
      fill: Color(0xFFFEE7E2),
      strong: Color(0xFFF87F85),
      onFill: Color(0xFF4A1416),
    ),
  );

  /// Palette sombre, dérivée de [light] (Design System : dark natif V1.0).
  static const LyPalette dark = LyPalette(
    surface: Color(0xFF0C0C11),
    card: Color(0xFF16161E),
    cardBorder: Color(0xFF24242F),
    navSurface: Color(0xFF1D1935),
    primary: Color(0xFFA694FF),
    onPrimary: Color(0xFF130B33),
    primarySoft: Color(0xFF241D46),
    textPrimary: Color(0xFFF4F4F6),
    textSecondary: Color(0xFF9CA3AF),
    textTertiary: Color(0xFF6B7280),
    chipFill: Color(0xFF23232D),
    chipText: Color(0xFFD4D4D8),
    badgeInk: Color(0xFFF4F4F6),
    onBadgeInk: Color(0xFF16161E),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    skeleton: Color(0xFF1E1E28),
    skeletonHighlight: Color(0xFF2A2A36),
    lime: LyAccent(
      fill: Color(0xFF232E0B),
      strong: Color(0xFFC3E91C),
      onFill: Color(0xFFE4F9B9),
    ),
    lavender: LyAccent(
      fill: Color(0xFF241B3D),
      strong: Color(0xFFB18BEA),
      onFill: Color(0xFFDCD2FA),
    ),
    blue: LyAccent(
      fill: Color(0xFF0E2C38),
      strong: Color(0xFF72D7F3),
      onFill: Color(0xFFC7EDFB),
    ),
    yellow: LyAccent(
      fill: Color(0xFF31280A),
      strong: Color(0xFFFDDB71),
      onFill: Color(0xFFFBECB8),
    ),
    pink: LyAccent(
      fill: Color(0xFF361A1C),
      strong: Color(0xFFF87F85),
      onFill: Color(0xFFFBD4D3),
    ),
  );

  final Color surface;
  final Color card;
  final Color cardBorder;
  final Color navSurface;

  final Color primary;
  final Color onPrimary;
  final Color primarySoft;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color chipFill;
  final Color chipText;

  /// Pastille sombre des icônes (les cercles noirs des maquettes).
  final Color badgeInk;
  final Color onBadgeInk;

  final Color success;
  final Color warning;
  final Color danger;

  final Color skeleton;
  final Color skeletonHighlight;

  final LyAccent lime;
  final LyAccent lavender;
  final LyAccent blue;
  final LyAccent yellow;
  final LyAccent pink;

  /// Les cinq familles, dans leur ordre d'apparition sur la Home.
  List<LyAccent> get accents => [lime, blue, lavender, yellow, pink];

  /// Variante plus lumineuse d'un fond d'accent, valable en clair comme en
  /// sombre. On renforce la teinte au lieu d'y mélanger du blanc : sur fond
  /// sombre, le blanc vire au gris terne et efface l'identité de couleur.
  Color lift(LyAccent accent, [double amount = 0.22]) =>
      Color.alphaBlend(accent.strong.withValues(alpha: amount), accent.fill);

  /// Accent d'un lymark : son emplacement hérité s'il en a un, sinon une
  /// teinte dérivée de son domaine.
  LyAccent accentOr(int? slot, String fallbackKey) =>
      slot != null ? accentAt(slot) : accentFor(fallbackKey);

  /// Accent par emplacement explicite. À préférer dès que la donnée porte
  /// son propre emplacement (catégories, clusters).
  LyAccent accentAt(int index) => accents[index.abs() % accents.length];

  /// Accent dérivé d'une clé, pour ce qui n'a pas d'emplacement propre
  /// (vignette de source d'un lymark). Stable entre deux lancements.
  LyAccent accentFor(String key) {
    if (key.isEmpty) return accents.first;
    var hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return accents[hash % accents.length];
  }

  @override
  LyPalette copyWith({
    Color? surface,
    Color? card,
    Color? cardBorder,
    Color? navSurface,
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? chipFill,
    Color? chipText,
    Color? badgeInk,
    Color? onBadgeInk,
    Color? success,
    Color? warning,
    Color? danger,
    Color? skeleton,
    Color? skeletonHighlight,
    LyAccent? lime,
    LyAccent? lavender,
    LyAccent? blue,
    LyAccent? yellow,
    LyAccent? pink,
  }) {
    return LyPalette(
      surface: surface ?? this.surface,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      navSurface: navSurface ?? this.navSurface,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      chipFill: chipFill ?? this.chipFill,
      chipText: chipText ?? this.chipText,
      badgeInk: badgeInk ?? this.badgeInk,
      onBadgeInk: onBadgeInk ?? this.onBadgeInk,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      skeleton: skeleton ?? this.skeleton,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      lime: lime ?? this.lime,
      lavender: lavender ?? this.lavender,
      blue: blue ?? this.blue,
      yellow: yellow ?? this.yellow,
      pink: pink ?? this.pink,
    );
  }

  @override
  LyPalette lerp(ThemeExtension<LyPalette>? other, double t) {
    if (other is! LyPalette) return this;
    return LyPalette(
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      navSurface: Color.lerp(navSurface, other.navSurface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      chipFill: Color.lerp(chipFill, other.chipFill, t)!,
      chipText: Color.lerp(chipText, other.chipText, t)!,
      badgeInk: Color.lerp(badgeInk, other.badgeInk, t)!,
      onBadgeInk: Color.lerp(onBadgeInk, other.onBadgeInk, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      skeleton: Color.lerp(skeleton, other.skeleton, t)!,
      skeletonHighlight:
          Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
      lime: LyAccent.lerp(lime, other.lime, t),
      lavender: LyAccent.lerp(lavender, other.lavender, t),
      blue: LyAccent.lerp(blue, other.blue, t),
      yellow: LyAccent.lerp(yellow, other.yellow, t),
      pink: LyAccent.lerp(pink, other.pink, t),
    );
  }
}

/// Accès court aux tokens depuis un widget : `context.ly.primary`.
extension LyPaletteX on BuildContext {
  LyPalette get ly => Theme.of(this).extension<LyPalette>()!;
  TextTheme get texts => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
