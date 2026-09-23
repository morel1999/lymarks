import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/core/utils/relative_time.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/widgets/ly_card.dart';
import 'package:lymarks/shared/widgets/preview_image.dart';
import 'package:lymarks/shared/widgets/shimmer.dart';
import 'package:lymarks/shared/widgets/source_avatar.dart';
import 'package:lymarks/shared/widgets/tag_chip.dart';

/// Côté de la vignette carrée (aperçu ou icône de source).
const double _tileSize = 52;
const double _denseTileSize = 44;

/// Carte lymark — le composant central du produit.
///
/// Variantes portées par [Lymark.status] (Design System §Composants) :
///   * `processing` : squelette animé qui se remplit seul ;
///   * `ready` : aperçu de la page (ou icône de source), titre, 3 puces,
///     note, tags ;
///   * `partial` : badge « Limited summary » et métadonnées conservées ;
///   * `failed` : message clair et bouton de relance.
class BookmarkCard extends StatelessWidget {
  const BookmarkCard(
    this.lymark, {
    this.onTap,
    this.onMenu,
    this.onRetry,
    this.onTagTap,
    this.dense = false,
    super.key,
  });

  final Lymark lymark;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;
  final VoidCallback? onRetry;
  final void Function(String tag)? onTagTap;

  /// Version compacte : sans puces ni tags (listes « Related », clusters).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    // Avant le statut : un lymark verrouille n'a jamais traverse le
    // pipeline, il est donc `processing` cote serveur. Sans cette sortie il
    // afficherait un squelette qui scintille pour toujours.
    if (lymark.locked) return _LockedCard(lymark: lymark, onTap: onTap);
    if (lymark.status == LymarkStatus.processing) {
      return const _ProcessingCard();
    }

    final ly = context.ly;
    final texts = context.texts;
    final accent = ly.accentOr(lymark.accentSlot, lymark.accentKey);
    final tile = dense ? _denseTileSize : _tileSize;

    return LyCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PreviewImage(
                // Une carte en échec garde son icône : une image récupérée
                // avant l'échec ne dit rien de fiable sur la page.
                url: lymark.status == LymarkStatus.failed
                    ? null
                    : lymark.imageUrl,
                width: tile,
                height: tile,
                radius: LyRadius.tileR,
                fallback: SourceAvatar(
                  domain: lymark.domain,
                  accent: accent,
                  size: tile,
                ),
              ),
              const SizedBox(width: LySpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lymark.domain,
                      style: texts.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lymark.title,
                      style: dense ? texts.titleMedium : texts.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: LySpace.xs + 2),
                    _SavedLine(lymark: lymark),
                  ],
                ),
              ),
              if (onMenu != null) ...[
                const SizedBox(width: LySpace.s),
                _MenuButton(onPressed: onMenu!),
              ],
            ],
          ),
          if (lymark.status == LymarkStatus.failed)
            _FailedBlock(onRetry: onRetry)
          else if (!dense && lymark.bullets.isNotEmpty) ...[
            const SizedBox(height: LySpace.m),
            for (final bullet in lymark.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: LySpace.s),
                child: SummaryBullet(bullet, color: accent.strong),
              ),
          ],
          if (!dense && lymark.hasNote) ...[
            const SizedBox(height: LySpace.xs),
            _NoteLine(note: lymark.note!),
          ],
          if (!dense && lymark.keywords.isNotEmpty) ...[
            const SizedBox(height: LySpace.m),
            Row(
              children: [
                Expanded(
                  child: TagRow(lymark.keywords, onTagTap: onTagTap),
                ),
                if (lymark.status == LymarkStatus.partial)
                  Padding(
                    padding: const EdgeInsets.only(left: LySpace.s),
                    child: _PartialBadge(color: ly.warning),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Une puce de résumé : point coloré + texte.
class SummaryBullet extends StatelessWidget {
  const SummaryBullet(this.text, {this.color, super.key});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7, right: LySpace.m),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color ?? ly.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(text, style: context.texts.bodyMedium),
        ),
      ],
    );
  }
}

class _SavedLine extends StatelessWidget {
  const _SavedLine({required this.lymark});

  final Lymark lymark;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: switch (lymark.status) {
              LymarkStatus.failed => ly.danger,
              LymarkStatus.partial => ly.warning,
              _ => ly.primary,
            },
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: LySpace.s),
        Text(LyTime.savedAgo(lymark.savedAt), style: context.texts.labelSmall),
      ],
    );
  }
}

class _NoteLine extends StatelessWidget {
  const _NoteLine({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: LySpace.m,
        vertical: LySpace.s + 2,
      ),
      decoration: BoxDecoration(
        color: ly.chipFill,
        borderRadius: BorderRadius.circular(LyRadius.button),
      ),
      child: Text(
        note,
        style: context.texts.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: ly.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PartialBadge extends StatelessWidget {
  const _PartialBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LyIcons.warning, size: 14, color: color),
        const SizedBox(width: LySpace.xs + 2),
        Text(
          'Limited summary',
          style: context.texts.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _FailedBlock extends StatelessWidget {
  const _FailedBlock({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Padding(
      padding: const EdgeInsets.only(top: LySpace.m),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Couldn't process this link.",
              style: context.texts.bodySmall?.copyWith(color: ly.textSecondary),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(LyIcons.retry, size: 16),
            label: const Text('Try again'),
            style: TextButton.styleFrom(
              foregroundColor: ly.primary,
              padding: const EdgeInsets.symmetric(horizontal: LySpace.m),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(LyIcons.more, size: LyIconSize.regular),
      color: context.ly.textSecondary,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      tooltip: 'More actions',
    );
  }
}

/// Squelette animé de l'état `processing`.
class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard();

  @override
  Widget build(BuildContext context) {
    return LyCard(
      child: Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _tileSize,
                  height: _tileSize,
                  decoration: BoxDecoration(
                    color: context.ly.skeleton,
                    borderRadius: LyRadius.tileR,
                  ),
                ),
                const SizedBox(width: LySpace.m),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBar(width: 96, height: 10),
                      SizedBox(height: LySpace.s),
                      SkeletonBar(width: 190, height: 16),
                      SizedBox(height: LySpace.s),
                      SkeletonBar(width: 74, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: LySpace.l),
            const SkeletonBar.line(height: 11),
            const SizedBox(height: LySpace.m),
            const SkeletonBar.line(height: 11),
            const SizedBox(height: LySpace.m),
            const SkeletonBar(width: 210, height: 11),
          ],
        ),
      ),
    );
  }
}

/// Un lymark garde mais inaccessible (plan Free au-dela de sa limite).
///
/// Il est la, on voit qu'il y a quelque chose, on ne peut pas le lire. Le
/// flou est litteral : le titre est rendu puis brouille, pas remplace par un
/// texte generique — l'utilisateur doit sentir que **son** lien est bien
/// arrive, pas qu'une case vide l'attend.
class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.lymark, this.onTap});

  final Lymark lymark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return LyCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: _tileSize,
            height: _tileSize,
            decoration: BoxDecoration(
              color: ly.chipFill,
              borderRadius: LyRadius.tileR,
            ),
            child: Icon(
              LyIcons.security,
              size: LyIconSize.regular,
              color: ly.textSecondary,
            ),
          ),
          const SizedBox(width: LySpace.m),
          Expanded(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lymark.domain,
                    style: context.texts.labelSmall?.copyWith(
                      color: ly.textSecondary,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: LySpace.xs),
                  Text(
                    lymark.title,
                    style: context.texts.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: LySpace.s),
          Text(
            'Locked',
            style: context.texts.labelSmall?.copyWith(
              color: ly.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
