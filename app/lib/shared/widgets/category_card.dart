import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/shared/models/knowledge.dart';

/// Grande carte de catégorie de la Home.
///
/// C'est la porte d'entrée du Category Path : elle doit donner l'impression
/// de se transformer en parcours (wireframe 02 §Navigation vers Category
/// Path), d'où le `Hero` partagé avec l'écran suivant.
class CategoryHeroCard extends StatelessWidget {
  const CategoryHeroCard({
    required this.category,
    required this.onTap,
    super.key,
  });

  final KnowledgeCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final accent = ly.accentAt(category.accent);

    return Hero(
      tag: 'category-${category.id}',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: LyRadius.heroR,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ly.lift(accent), accent.fill],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: LyRadius.heroR,
            child: Padding(
              padding: const EdgeInsets.all(LySpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: context.texts.displayMedium?.copyWith(
                                color: accent.onFill,
                              ),
                            ),
                            const SizedBox(height: LySpace.s),
                            Text(
                              category.tagline,
                              style: context.texts.bodyLarge?.copyWith(
                                color: accent.onFill.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _AccentGlyph(accent: accent, iconKey: category.iconKey),
                    ],
                  ),
                  const SizedBox(height: LySpace.xxl),
                  Row(
                    children: [
                      _RoundArrow(
                        background: ly.badgeInk,
                        foreground: ly.onBadgeInk,
                      ),
                      const SizedBox(width: LySpace.m),
                      Text(
                        '${category.count} Lymarks',
                        style: context.texts.titleSmall?.copyWith(
                          color: accent.onFill,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vignette de catégorie du carrousel horizontal.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.category,
    required this.onTap,
    super.key,
  });

  final KnowledgeCategory category;
  final VoidCallback onTap;

  static const double width = 168;

  @override
  Widget build(BuildContext context) {
    final accent = context.ly.accentAt(category.accent);

    return Hero(
      tag: 'category-${category.id}',
      child: Material(
        color: accent.fill,
        borderRadius: LyRadius.heroR,
        child: InkWell(
          onTap: onTap,
          borderRadius: LyRadius.heroR,
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.all(LySpace.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AccentGlyph(
                    accent: accent,
                    iconKey: category.iconKey,
                    size: 44,
                  ),
                  const SizedBox(height: LySpace.l),
                  Text(
                    category.name,
                    style: context.texts.titleLarge?.copyWith(
                      color: accent.onFill,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: LySpace.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${category.count} Lymarks',
                          style: context.texts.labelSmall?.copyWith(
                            color: accent.onFill.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      _RoundArrow(
                        size: 30,
                        background: context.ly.card,
                        foreground: context.ly.textPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccentGlyph extends StatelessWidget {
  const _AccentGlyph({
    required this.accent,
    required this.iconKey,
    this.size = 56,
  });

  final LyAccent accent;
  final String iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: ly.badgeInk, shape: BoxShape.circle),
      child: Icon(
        LyIcons.topic(iconKey),
        size: size * 0.45,
        color: accent.strong,
      ),
    );
  }
}

class _RoundArrow extends StatelessWidget {
  const _RoundArrow({
    required this.background,
    required this.foreground,
    this.size = 44,
  });

  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(LyIcons.enter, size: size * 0.45, color: foreground),
    );
  }
}
