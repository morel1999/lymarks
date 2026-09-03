import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/core/utils/relative_time.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/widgets/bookmark_card.dart';

/// Carte du Daily Digest.
///
/// Elle répond explicitement à « Pourquoi est-ce que Lymarks me montre ça
/// aujourd'hui ? » (wireframe 06 §Contenu) via [reason]. Fond teinté par
/// l'accent du lymark : le digest est coloré, jamais bruyant.
class DigestCard extends StatelessWidget {
  const DigestCard({
    required this.lymark,
    required this.reason,
    required this.onOpen,
    this.onSnooze,
    this.onArchive,
    super.key,
  });

  final Lymark lymark;
  final String reason;
  final VoidCallback onOpen;
  final VoidCallback? onSnooze;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final accent = ly.accentOr(lymark.accentSlot, lymark.accentKey);

    return Container(
      decoration: BoxDecoration(
        color: accent.fill,
        borderRadius: LyRadius.heroR,
      ),
      padding: const EdgeInsets.all(LySpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LyIcons.sparkle, size: 16, color: accent.onFill),
              const SizedBox(width: LySpace.s),
              Expanded(
                child: Text(
                  reason,
                  style: context.texts.labelSmall?.copyWith(
                    color: accent.onFill.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LySpace.l),
          Text(
            lymark.title,
            style: context.texts.displaySmall?.copyWith(color: accent.onFill),
          ),
          const SizedBox(height: LySpace.s),
          Text(
            '${lymark.domain} · ${LyTime.savedAgo(lymark.savedAt)}',
            style: context.texts.labelSmall?.copyWith(
              color: accent.onFill.withValues(alpha: 0.7),
            ),
          ),
          if (lymark.bullets.isNotEmpty) ...[
            const SizedBox(height: LySpace.l),
            for (final bullet in lymark.bullets.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: LySpace.s),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: accent.onFill),
                  child: SummaryBullet(bullet, color: accent.strong),
                ),
              ),
          ],
          const SizedBox(height: LySpace.l),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(LyIcons.enter, size: LyIconSize.regular),
                  label: const Text('Open Lymark'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ly.badgeInk,
                    foregroundColor: ly.onBadgeInk,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              if (onSnooze != null) ...[
                const SizedBox(width: LySpace.s),
                _GhostAction(
                  icon: LyIcons.clock,
                  tooltip: 'Snooze for a week',
                  color: accent.onFill,
                  onPressed: onSnooze!,
                ),
              ],
              if (onArchive != null) ...[
                const SizedBox(width: LySpace.s),
                _GhostAction(
                  icon: LyIcons.check,
                  tooltip: 'Archive',
                  color: accent.onFill,
                  onPressed: onArchive!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GhostAction extends StatelessWidget {
  const _GhostAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.ly.card.withValues(alpha: 0.7),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: LyIconSize.regular, color: color),
          ),
        ),
      ),
    );
  }
}
