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
/// **Identité : bleu nuit en dégradé, chrome en touche** (décidée le 22/09,
/// en remplacement du violet d'origine). Le primaire est un bleu profond ;
/// les grandes surfaces d'appel (bouton de capture, en-tête du paywall,
/// hero du détail) portent le dégradé [primaryGradient] plutôt qu'un aplat ;
/// le chrome ([chrome], [chromeSoft], [chromeDeep], [chromeGradient]) sert de
/// filet métallique — bordures d'exception, badge Pro, séparateurs — jamais
/// de fond plein : « un peu de chrome », pas une carrosserie.
///
/// Les accents pastel des catégories (lime, blue, steel, yellow, pink) sont
/// repris des maquettes `Ecran/Parcours IA pastel sur mobile.png` ; seule la
/// famille violette a été remplacée par [steel], l'acier du même thème.
///
/// Les valeurs `dark` sont dérivées de `light` (fonds profonds teintés de
/// bleu, accents éclaircis) : le sombre est natif dès la V1.0.
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
    required this.gradientTop,
    required this.gradientBottom,
    required this.chrome,
    required this.chromeSoft,
    required this.chromeDeep,
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
    required this.steel,
    required this.blue,
    required this.yellow,
    required this.pink,
  });

  /// Palette claire : blancs refroidis au bleu, primaire bleu nuit.
  static const LyPalette light = LyPalette(
    surface: Color(0xFFF6F8FC),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE3E9F2),
    navSurface: Color(0xFFE9EFF9),
    primary: Color(0xFF1A3E72),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE4ECF9),
    gradientTop: Color(0xFF0D1F3C),
    gradientBottom: Color(0xFF23508F),
    chrome: Color(0xFF94A3B8),
    chromeSoft: Color(0xFFE8EDF4),
    chromeDeep: Color(0xFF56637A),
    textPrimary: Color(0xFF0A101C),
    textSecondary: Color(0xFF5B6678),
    textTertiary: Color(0xFF8E98A9),
    chipFill: Color(0xFFF1F4FA),
    chipText: Color(0xFF394355),
    badgeInk: Color(0xFF111826),
    onBadgeInk: Color(0xFFFFFFFF),
    success: Color(0xFF0E9E76),
    warning: Color(0xFFE39A0B),
    danger: Color(0xFFE04A4A),
    skeleton: Color(0xFFEDF1F8),
    skeletonHighlight: Color(0xFFF9FBFE),
    lime: LyAccent(
      fill: Color(0xFFEDF9CC),
      strong: Color(0xFFC3E91C),
      onFill: Color(0xFF2F3D06),
    ),
    steel: LyAccent(
      fill: Color(0xFFE5E9F0),
      strong: Color(0xFF64748B),
      onFill: Color(0xFF1E293B),
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
  /// Les noirs sont teintés de bleu nuit, jamais neutres.
  static const LyPalette dark = LyPalette(
    surface: Color(0xFF060A12),
    card: Color(0xFF0E1520),
    cardBorder: Color(0xFF1C2634),
    navSurface: Color(0xFF0F1A2E),
    primary: Color(0xFF7FA9E8),
    onPrimary: Color(0xFF06152A),
    primarySoft: Color(0xFF132339),
    gradientTop: Color(0xFF08142A),
    gradientBottom: Color(0xFF1B4275),
    chrome: Color(0xFF8593A8),
    chromeSoft: Color(0xFFD6DEEA),
    chromeDeep: Color(0xFF414D60),
    textPrimary: Color(0xFFEDF1F8),
    textSecondary: Color(0xFF94A1B4),
    textTertiary: Color(0xFF657183),
    chipFill: Color(0xFF19212E),
    chipText: Color(0xFFCAD3E0),
    badgeInk: Color(0xFFEDF1F8),
    onBadgeInk: Color(0xFF0E1520),
    success: Color(0xFF2CC79C),
    warning: Color(0xFFF0B429),
    danger: Color(0xFFF0716E),
    skeleton: Color(0xFF131B27),
    skeletonHighlight: Color(0xFF1D2634),
    lime: LyAccent(
      fill: Color(0xFF232E0B),
      strong: Color(0xFFC3E91C),
      onFill: Color(0xFFE4F9B9),
    ),
    steel: LyAccent(
      fill: Color(0xFF1A212E),
      strong: Color(0xFF94A3B8),
      onFill: Color(0xFFDDE3EC),
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

  /// Deux bornes du dégradé d'identité, du plus nocturne au plus ouvert.
  final Color gradientTop;
  final Color gradientBottom;

  /// Métal : [chrome] est la teinte médiane, [chromeSoft] le reflet,
  /// [chromeDeep] l'ombre. Une touche, pas un fond.
  final Color chrome;
  final Color chromeSoft;
  final Color chromeDeep;

  /// Dégradé d'identité, en diagonale (les surfaces d'appel).
  LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientTop, gradientBottom],
  );

  /// Filet métallique : reflet, métal, ombre, reflet. Pour des bordures et
  /// des séparateurs fins, jamais pour remplir une surface.
  LinearGradient get chromeGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [chromeSoft, chrome, chromeDeep, chromeSoft],
    stops: const [0, 0.35, 0.7, 1],
  );

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

  /// L'acier du thème : remplace la famille violette d'origine.
  final LyAccent steel;
  final LyAccent blue;
  final LyAccent yellow;
  final LyAccent pink;

  /// Les cinq familles, dans leur ordre d'apparition sur la Home.
  List<LyAccent> get accents => [lime, blue, steel, yellow, pink];

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
    Color? gradientTop,
    Color? gradientBottom,
    Color? chrome,
    Color? chromeSoft,
    Color? chromeDeep,
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
    LyAccent? steel,
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
      gradientTop: gradientTop ?? this.gradientTop,
      gradientBottom: gradientBottom ?? this.gradientBottom,
      chrome: chrome ?? this.chrome,
      chromeSoft: chromeSoft ?? this.chromeSoft,
      chromeDeep: chromeDeep ?? this.chromeDeep,
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
      steel: steel ?? this.steel,
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
      gradientTop: Color.lerp(gradientTop, other.gradientTop, t)!,
      gradientBottom: Color.lerp(gradientBottom, other.gradientBottom, t)!,
      chrome: Color.lerp(chrome, other.chrome, t)!,
      chromeSoft: Color.lerp(chromeSoft, other.chromeSoft, t)!,
      chromeDeep: Color.lerp(chromeDeep, other.chromeDeep, t)!,
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
      skeletonHighlight: Color.lerp(
        skeletonHighlight,
        other.skeletonHighlight,
        t,
      )!,
      lime: LyAccent.lerp(lime, other.lime, t),
      steel: LyAccent.lerp(steel, other.steel, t),
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
