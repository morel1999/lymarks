import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/widgets/bookmark_card.dart';
import 'package:lymarks/shared/widgets/category_card.dart';
import 'package:lymarks/shared/widgets/empty_state.dart';
import 'package:lymarks/shared/widgets/locked_notice.dart';
import 'package:lymarks/shared/widgets/ly_card.dart';
import 'package:lymarks/shared/widgets/lymark_actions.dart';
import 'package:lymarks/shared/widgets/paywall_sheet.dart';
import 'package:lymarks/shared/widgets/profile_avatar.dart';
import 'package:lymarks/shared/widgets/section_header.dart';

/// 02 — Home / Knowledge Hub.
///
/// Répond à deux questions : « où se trouve ma mémoire ? » et « qu'est-ce que
/// j'ai récemment sauvegardé ? ». Ce n'est donc pas une simple liste
/// (wireframe 02 §Objectif).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final lymarks = ref.watch(lymarksProvider);
    final sync = ref.watch(librarySyncProvider);
    // Les verrouilles vivent a part : ils sont les plus recents, ils
    // noieraient la liste lisible s'ils s'y melaient.
    final live = lymarks.where((l) => !l.archived && !l.locked);
    final locked = lymarks.where((l) => !l.archived && l.locked).toList();
    // Quand des liens sont fermes, la liste lisible s'ecourte : le
    // signalement doit arriver au bout de deux ou trois cartes, pas au bout
    // de six. « See all » reste la porte vers la bibliotheque entiere.
    final recent = live.take(locked.isEmpty ? 6 : 3).toList();

    // Le paywall ne surgit plus tout seul à l'ouverture. Il le faisait après
    // une capture refusée, sans contexte : on tombait sur une feuille de
    // vente sans savoir ce qui venait d'échouer. Les liens gardés hors
    // d'atteinte s'expliquent désormais là où ils sont, dans la liste.

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _HomeHeader()),
          if (sync == LibrarySync.offline)
            const SliverToBoxAdapter(child: _OfflineBanner()),
          if (lymarks.isEmpty && sync == LibrarySync.loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (lymarks.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(LySpace.xl),
                child: CaptureTutorial(),
              ),
            )
          else ...[
            // Cartes de catégories : la première en hero, les suivantes en
            // carrousel. En mode réel elles n'existent que si l'IA a déjà
            // rangé quelque chose ; d'ici là, une carte le dit.
            if (categories.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: LySpace.screen),
                sliver: SliverToBoxAdapter(child: CategoriesEmptyCard()),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  LySpace.screen,
                  0,
                  LySpace.screen,
                  LySpace.l,
                ),
                sliver: SliverToBoxAdapter(
                  child: CategoryHeroCard(
                    category: categories.first,
                    onTap: () =>
                        context.push(LyRoute.category(categories.first.id)),
                  ),
                ),
              ),
              if (categories.length > 1)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 152,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: LySpace.screen,
                      ),
                      itemCount: categories.length - 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: LySpace.m),
                      itemBuilder: (context, i) {
                        final category = categories[i + 1];
                        return CategoryTile(
                          category: category,
                          onTap: () =>
                              context.push(LyRoute.category(category.id)),
                        );
                      },
                    ),
                  ),
                ),
            ],
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.screen,
                LySpace.xxl,
                LySpace.screen,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  'All Lymarks',
                  actionLabel: 'See all',
                  onAction: () => context.push(LyRoute.library),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: LySpace.screen,
              ),
              sliver: SliverList.separated(
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(height: LySpace.m),
                itemBuilder: (context, i) => _HomeCard(lymark: recent[i]),
              ),
            ),
            if (locked.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  LySpace.screen,
                  LySpace.xl,
                  LySpace.screen,
                  LySpace.m,
                ),
                sliver: SliverToBoxAdapter(
                  child: LockedNotice(
                    count: locked.length,
                    onUpgrade: () => unawaited(
                      PaywallSheet.show(
                        context,
                        trigger: PaywallTrigger.captureLimit,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LySpace.screen,
                ),
                sliver: SliverList.separated(
                  itemCount: locked.length,
                  separatorBuilder: (_, _) => const SizedBox(height: LySpace.m),
                  itemBuilder: (context, i) => BookmarkCard(
                    locked[i],
                    onTap: () => unawaited(
                      PaywallSheet.show(
                        context,
                        trigger: PaywallTrigger.captureLimit,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
          const SliverToBoxAdapter(
            child: SizedBox(height: LySpace.navBarInset),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends ConsumerWidget {
  const _HomeCard({required this.lymark});

  final Lymark lymark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BookmarkCard(
      lymark,
      onTap: () => context.push(LyRoute.lymark(lymark.id)),
      onMenu: () => LymarkActions.showMenu(context, ref, lymark),
      onRetry: () => ref.read(lymarksProvider.notifier).retry(lymark.id),
      onTagTap: (tag) {
        ref.read(searchQueryProvider.notifier).state = tag;
        context.go(LyRoute.search);
      },
    );
  }
}

/// En-tête éditorial : salutation puis accès au compte.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning,';
    if (now.hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final now = ref.watch(clockProvider)();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LySpace.screen,
        LySpace.xxl + LySpace.l,
        LySpace.screen,
        LySpace.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${_greeting(now)}\nyour knowledge',
              style: context.texts.displayLarge,
            ),
          ),
          const SizedBox(width: LySpace.m),
          // L'avatar mène au profil ; les réglages s'ouvrent depuis là.
          ProfileAvatar(
            profile: profile,
            onTap: () => context.push(LyRoute.profile),
          ),
        ],
      ),
    );
  }
}

/// Coquille réutilisée par les écrans secondaires : un titre, une action.
///
/// Un cran sous le titre de la Home (`displayMedium`, 28) : ces pages sont
/// des sous-écrans, pas des points d'entrée. Le [SafeArea] tient le titre
/// à distance de la barre de statut.
class LyScreenHeader extends StatelessWidget {
  const LyScreenHeader({
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LySpace.screen,
          LySpace.l,
          LySpace.screen,
          LySpace.l,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null) ...[
              _CircleButton(
                icon: LyIcons.back,
                onTap: onBack!,
                tooltip: 'Back',
              ),
              const SizedBox(width: LySpace.l),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.texts.displayMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: LySpace.xs),
                    Text(
                      subtitle!,
                      style: context.texts.bodyLarge?.copyWith(
                        color: ly.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: LySpace.m),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Bouton rond des en-têtes (retour, menu ⋯, calendrier).
class LyCircleButton extends StatelessWidget {
  const LyCircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) =>
      _CircleButton(icon: icon, onTap: onTap, tooltip: tooltip);
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: ly.card,
        shape: CircleBorder(side: BorderSide(color: ly.cardBorder)),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: LyIconSize.large, color: ly.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Bandeau de limite Free, affiché **après** la capture, jamais pendant
/// (UX Bible règle 11).
class FreeLimitBanner extends StatelessWidget {
  const FreeLimitBanner({
    required this.count,
    required this.onUpgrade,
    super.key,
  });

  final int count;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return LyCard(
      color: ly.yellow.fill,
      borderColor: ly.yellow.strong,
      onTap: onUpgrade,
      child: Row(
        children: [
          Icon(LyIcons.warning, size: 20, color: ly.yellow.onFill),
          const SizedBox(width: LySpace.m),
          Expanded(
            child: Text(
              'You reached the $count lymarks of the free plan. '
              'New links are saved and waiting.',
              style: context.texts.bodySmall?.copyWith(color: ly.yellow.onFill),
            ),
          ),
          Icon(LyIcons.forward, size: 18, color: ly.yellow.onFill),
        ],
      ),
    );
  }
}

/// Bandeau discret quand la dernière synchronisation a échoué : la liste
/// affichée est celle du dernier passage réussi (PRD §3, hors-ligne).
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LySpace.screen,
        0,
        LySpace.screen,
        LySpace.m,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LySpace.m,
          vertical: LySpace.s,
        ),
        decoration: BoxDecoration(
          color: ly.yellow.fill,
          borderRadius: LyRadius.tileR,
        ),
        child: Row(
          children: [
            Icon(
              LyIcons.offline,
              size: LyIconSize.small,
              color: ly.yellow.onFill,
            ),
            const SizedBox(width: LySpace.s),
            Expanded(
              child: Text(
                'Offline — showing your last synced lymarks.',
                style: context.texts.bodySmall?.copyWith(
                  color: ly.yellow.onFill,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
