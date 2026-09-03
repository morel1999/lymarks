import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';

/// Chip de mot-clé.
///
/// En V1.0 les mots-clés générés font office de tags et sont cliquables : un
/// tap lance une recherche (`05-data/01-knowledge-vault-spec.md` §2).
class TagChip extends StatelessWidget {
  const TagChip(
    this.label, {
    this.onTap,
    this.accent,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;

  /// Teinte optionnelle : sert à colorer les tags de la fiche détail.
  final LyAccent? accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final bg = accent?.fill ?? ly.chipFill;
    final fg = accent?.onFill ?? ly.chipText;

    return Material(
      color: bg,
      borderRadius: LyRadius.pillR,
      child: InkWell(
        onTap: onTap,
        borderRadius: LyRadius.pillR,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LySpace.m,
            vertical: LySpace.s,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: LySpace.xs + 2),
              ],
              Text(
                label,
                style: context.texts.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rangée de chips qui se limite d'elle-même et résume le reste en « +N ».
class TagRow extends StatelessWidget {
  const TagRow(
    this.tags, {
    this.max = 3,
    this.onTagTap,
    super.key,
  });

  final List<String> tags;
  final int max;
  final void Function(String tag)? onTagTap;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final shown = tags.take(max).toList();
    final rest = tags.length - shown.length;

    return Wrap(
      spacing: LySpace.s,
      runSpacing: LySpace.s,
      children: [
        for (final t in shown)
          TagChip(t, onTap: onTagTap == null ? null : () => onTagTap!(t)),
        if (rest > 0) TagChip('+$rest'),
      ],
    );
  }
}
