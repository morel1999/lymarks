import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/core/utils/relative_time.dart';
import 'package:lymarks/features/home/home_screen.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/widgets/bookmark_card.dart';
import 'package:lymarks/shared/widgets/ly_card.dart';
import 'package:lymarks/shared/widgets/lymark_actions.dart';
import 'package:lymarks/shared/widgets/preview_image.dart';
import 'package:lymarks/shared/widgets/section_header.dart';
import 'package:lymarks/shared/widgets/shimmer.dart';
import 'package:lymarks/shared/widgets/source_avatar.dart';
import 'package:lymarks/shared/widgets/tag_chip.dart';

/// 04 — Lymark Detail / Memory Page.
///
/// Ce n'est pas une fiche de bookmark : elle restitue **le contexte que
/// l'utilisateur risque d'avoir oublié** (wireframe 04 §Objectif). D'où
/// « Remember this » plutôt que « AI summary » comme titre de section.
class LymarkDetailScreen extends ConsumerStatefulWidget {
  const LymarkDetailScreen({required this.lymarkId, super.key});

  final String lymarkId;

  @override
  ConsumerState<LymarkDetailScreen> createState() => _LymarkDetailScreenState();
}

class _LymarkDetailScreenState extends ConsumerState<LymarkDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Le re-surfaçage a besoin de `last_opened_at`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lymarksProvider.notifier).markOpened(widget.lymarkId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lymark = ref.watch(lymarkByIdProvider(widget.lymarkId));
    if (lymark == null) {
      return const Scaffold(body: Center(child: Text('Lymark not found')));
    }

    final ly = context.ly;
    final accent = ly.accentOr(lymark.accentSlot, lymark.accentKey);
    final related =
        ref.watch(relatedLymarksProvider(lymark.id)).valueOrNull ?? const [];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.screen,
                LySpace.l,
                LySpace.screen,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    LyCircleButton(
                      icon: LyIcons.back,
                      tooltip: 'Back',
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    LyCircleButton(
                      icon: LyIcons.more,
                      tooltip: 'More actions',
                      onTap: () => LymarkActions.showMenu(
                        context,
                        ref,
                        lymark,
                        onDeleted: () => context.pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.screen,
                LySpace.xl,
                LySpace.screen,
                LySpace.xxl,
              ),
              sliver: SliverList.list(
                children: [
                  _SourceHeader(lymark: lymark, accent: accent),
                  const SizedBox(height: LySpace.xl),
                  _SourcePreview(lymark: lymark, accent: accent),
                  const SizedBox(height: LySpace.xxl),
                  if (lymark.status == LymarkStatus.processing)
                    const _ProcessingBlock()
                  else if (lymark.status == LymarkStatus.failed)
                    _FailedBlock(
                      onRetry: () =>
                          ref.read(lymarksProvider.notifier).retry(lymark.id),
                    )
                  else ...[
                    _RememberThis(lymark: lymark, accent: accent),
                    const SizedBox(height: LySpace.xxl),
                  ],
                  _YourNote(lymark: lymark),
                  if (lymark.keywords.isNotEmpty) ...[
                    const SizedBox(height: LySpace.xl),
                    _Tags(lymark: lymark, accent: accent),
                  ],
                  if (related.isNotEmpty) ...[
                    const SizedBox(height: LySpace.xxl),
                    SectionHeader(
                      'Related Lymarks',
                      actionLabel: 'See all',
                      onAction: () => context.push(LyRoute.library),
                    ),
                    for (final r in related)
                      Padding(
                        padding: const EdgeInsets.only(bottom: LySpace.m),
                        child: BookmarkCard(
                          r,
                          dense: true,
                          onTap: () =>
                              context.pushReplacement(LyRoute.lymark(r.id)),
                        ),
                      ),
                  ],
                  const SizedBox(height: LySpace.xl),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      LyIcons.openExternal,
                      size: LyIconSize.regular,
                    ),
                    label: const Text('Open original'),
                  ),
                  SizedBox(
                    height: MediaQuery.paddingOf(context).bottom + LySpace.l,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceHeader extends StatelessWidget {
  const _SourceHeader({required this.lymark, required this.accent});

  final Lymark lymark;
  final LyAccent accent;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SourceAvatar(
          domain: lymark.domain,
          accent: accent,
          size: 64,
        ),
        const SizedBox(width: LySpace.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Le domaine, jamais l'URL entière (wireframe 04 §Source).
              Text(
                lymark.domain,
                style: context.texts.labelMedium?.copyWith(
                  color: ly.textSecondary,
                ),
              ),
              const SizedBox(height: LySpace.xs),
              Text(lymark.title, style: context.texts.displaySmall),
              const SizedBox(height: LySpace.s),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: ly.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: LySpace.s),
                  Text(
                    LyTime.savedAgo(lymark.savedAt),
                    style: context.texts.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hauteur du bandeau d'aperçu.
const double _previewHeight = 168;

/// Aperçu de la source : l'image `og:image` de la page en `cover`.
///
/// Pour les pages qui n'en ont pas, tant qu'elle charge ou si elle échoue,
/// un aplat coloré tenant de l'accent du lymark : jamais un cadre vide
/// (wireframe 04 §Source Preview). Aucune icône de source en surimpression :
/// l'en-tête juste au-dessus montre déjà la vignette et le domaine, et un
/// glyphe posé sur une photo exigerait un voile pour rester lisible.
class _SourcePreview extends StatelessWidget {
  const _SourcePreview({required this.lymark, required this.accent});

  final Lymark lymark;
  final LyAccent accent;

  @override
  Widget build(BuildContext context) {
    return PreviewImage(
      url: lymark.status == LymarkStatus.failed ? null : lymark.imageUrl,
      height: _previewHeight,
      radius: LyRadius.heroR,
      fallback: _SourceFallback(lymark: lymark, accent: accent),
    );
  }
}

/// Aplat d'accent avec l'icône du domaine, repli de [_SourcePreview].
class _SourceFallback extends StatelessWidget {
  const _SourceFallback({required this.lymark, required this.accent});

  final Lymark lymark;
  final LyAccent accent;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return ClipRRect(
      borderRadius: LyRadius.heroR,
      child: Container(
        height: _previewHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ly.lift(accent, 0.12),
              accent.fill,
              ly.lift(accent, 0.38),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -20,
              child: _Blob(
                color: accent.strong.withValues(alpha: 0.35),
                size: 150,
              ),
            ),
            Positioned(
              right: 90,
              bottom: -40,
              child: _Blob(color: ly.card.withValues(alpha: 0.55), size: 120),
            ),
            Center(
              child: Icon(
                LyIcons.forDomain(lymark.domain),
                size: 44,
                color: accent.onFill.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RememberThis extends StatelessWidget {
  const _RememberThis({required this.lymark, required this.accent});

  final Lymark lymark;
  final LyAccent accent;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Remember this',
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LySpace.m,
              vertical: LySpace.xs + 2,
            ),
            decoration: BoxDecoration(
              color: ly.primarySoft,
              borderRadius: LyRadius.pillR,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LyIcons.sparkle, size: 14, color: ly.primary),
                const SizedBox(width: LySpace.s),
                Text(
                  'AI summary',
                  style: context.texts.labelSmall?.copyWith(
                    color: ly.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (lymark.status == LymarkStatus.partial)
          Padding(
            padding: const EdgeInsets.only(bottom: LySpace.m),
            child: Row(
              children: [
                Icon(LyIcons.warning, size: 16, color: ly.warning),
                const SizedBox(width: LySpace.s),
                Expanded(
                  child: Text(
                    'This page could not be read in full. '
                    'The summary uses its metadata only.',
                    style: context.texts.bodySmall?.copyWith(color: ly.warning),
                  ),
                ),
              ],
            ),
          ),
        for (final bullet in lymark.bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: LySpace.m),
            child: SummaryBullet(bullet, color: accent.strong),
          ),
      ],
    );
  }
}

class _YourNote extends ConsumerWidget {
  const _YourNote({required this.lymark});

  final Lymark lymark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ly = context.ly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Your note',
          trailing: TextButton.icon(
            onPressed: () => LymarkActions.editNote(context, ref, lymark),
            icon: const Icon(LyIcons.edit, size: 14),
            label: Text(lymark.hasNote ? 'Edit' : 'Add'),
            style: TextButton.styleFrom(
              foregroundColor: ly.primary,
              backgroundColor: ly.primarySoft,
              padding: const EdgeInsets.symmetric(
                horizontal: LySpace.m,
                vertical: LySpace.s,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const RoundedRectangleBorder(
                borderRadius: LyRadius.pillR,
              ),
            ),
          ),
        ),
        LyCard(
          color: ly.chipFill,
          borderColor: ly.chipFill,
          onTap: () => LymarkActions.editNote(context, ref, lymark),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              lymark.hasNote
                  ? lymark.note!
                  : 'Add why this mattered to you. Only you can see it.',
              style: context.texts.bodyLarge?.copyWith(
                fontStyle: lymark.hasNote ? FontStyle.italic : FontStyle.normal,
                color: lymark.hasNote ? ly.textPrimary : ly.textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tags extends ConsumerWidget {
  const _Tags({required this.lymark, required this.accent});

  final Lymark lymark;
  final LyAccent accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: LySpace.s,
      runSpacing: LySpace.s,
      children: [
        for (final tag in lymark.keywords)
          TagChip(
            tag,
            accent: accent,
            onTap: () {
              ref.read(searchQueryProvider.notifier).state = tag;
              context.go(LyRoute.search);
            },
          ),
        TagChip(
          'Add tag',
          icon: LyIcons.plus,
          accent: LyAccent(
            fill: context.ly.primarySoft,
            strong: context.ly.primary,
            onFill: context.ly.primary,
          ),
          onTap: () {},
        ),
      ],
    );
  }
}

class _ProcessingBlock extends StatelessWidget {
  const _ProcessingBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Remember this'),
        const Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBar.line(height: 13),
              SizedBox(height: LySpace.m),
              SkeletonBar.line(height: 13),
              SizedBox(height: LySpace.m),
              SkeletonBar(width: 220, height: 13),
            ],
          ),
        ),
        const SizedBox(height: LySpace.m),
        Text(
          'Reading the page. This takes a few seconds — '
          'you can close the app.',
          style: context.texts.bodySmall?.copyWith(
            color: context.ly.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FailedBlock extends StatelessWidget {
  const _FailedBlock({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return LyCard(
      color: ly.pink.fill,
      borderColor: ly.pink.fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LyIcons.warning, size: 20, color: ly.pink.onFill),
              const SizedBox(width: LySpace.m),
              Expanded(
                child: Text(
                  "Couldn't process this link.",
                  style: context.texts.titleSmall?.copyWith(
                    color: ly.pink.onFill,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LySpace.s),
          Text(
            'The page refused to load. Your link and note are safe.',
            style: context.texts.bodySmall?.copyWith(
              color: ly.pink.onFill.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: LySpace.l),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(LyIcons.retry, size: LyIconSize.regular),
            label: const Text('Try again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ly.pink.onFill,
              side: BorderSide(color: ly.pink.strong),
            ),
          ),
        ],
      ),
    );
  }
}
