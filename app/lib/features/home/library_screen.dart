import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/features/home/home_screen.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/widgets/bookmark_card.dart';
import 'package:lymarks/shared/widgets/empty_state.dart';
import 'package:lymarks/shared/widgets/lymark_actions.dart';

/// « See all » — la liste complète, antéchronologique (PRD F3).
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lymarks = ref
        .watch(lymarksProvider)
        .where((l) => !l.archived)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LyScreenHeader(
              title: 'All Lymarks',
              subtitle: '${lymarks.length} saved, newest first',
              onBack: () => context.pop(),
            ),
          ),
          if (lymarks.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(LySpace.xl),
                child: CaptureTutorial(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: LySpace.screen),
              sliver: SliverList.separated(
                itemCount: lymarks.length,
                separatorBuilder: (_, _) => const SizedBox(height: LySpace.m),
                itemBuilder: (context, i) {
                  final lymark = lymarks[i];
                  return BookmarkCard(
                    lymark,
                    onTap: () => context.push(LyRoute.lymark(lymark.id)),
                    onMenu: () => LymarkActions.showMenu(context, ref, lymark),
                    onRetry: () =>
                        ref.read(lymarksProvider.notifier).retry(lymark.id),
                    onTagTap: (tag) {
                      ref.read(searchQueryProvider.notifier).state = tag;
                      context.go(LyRoute.search);
                    },
                  );
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: LySpace.xxl)),
        ],
      ),
    );
  }
}

/// Icône exportée pour les écrans qui listent sans en-tête propre.
const IconData libraryIcon = LyIcons.bookmark;
