import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';

/// Conteneur de carte standard : fond `card`, filet `cardBorder`, rayon 16.
///
/// Toute surface de contenu passe par ici afin que le rayon, le filet et le
/// retour tactile restent identiques d'un écran à l'autre.
class LyCard extends StatelessWidget {
  const LyCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(LySpace.l),
    this.color,
    this.borderColor,
    this.radius = LyRadius.card,
    this.gradient,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final shape = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? ly.card) : null,
        gradient: gradient,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? ly.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: shape,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          splashColor: ly.primary.withValues(alpha: 0.06),
          highlightColor: ly.primary.withValues(alpha: 0.04),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Pastille d'icône sombre des maquettes (cercle encre, glyphe clair).
class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    this.size = 48,
    this.background,
    this.foreground,
    this.shape = BoxShape.circle,
    super.key,
  });

  /// Variante carrée à coins arrondis, utilisée par les réglages.
  const IconBadge.tile(
    this.icon, {
    this.size = 40,
    this.background,
    this.foreground,
    super.key,
  }) : shape = BoxShape.rectangle;

  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? ly.badgeInk,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? LyRadius.tileR : null,
      ),
      child: Icon(
        icon,
        size: size * 0.44,
        color: foreground ?? ly.onBadgeInk,
      ),
    );
  }
}
