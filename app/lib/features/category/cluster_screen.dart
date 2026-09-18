import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/features/home/home_screen.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/widgets/bookmark_card.dart';
import 'package:lymarks/shared/widgets/empty_state.dart';
import 'package:lymarks/shared/widgets/lymark_actions.dart';

/// Les lymarks d'un cluster (wireframe 03 §Interaction).
class ClusterScreen extends ConsumerWidget {
  const ClusterScreen({
    required this.categoryId,
    required this.clusterId,
    super.key,
  });

  final String categoryId;
  final String clusterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(categoryId));
    final cluster = category?.clusters
        .where((c) => c.id == clusterId)
        .firstOrNull;
    final lymarks = ref.watch(clusterLymarksProvider(clusterId));

    if (cluster == null) {
      return const Scaffold(body: Center(child: Text('Unknown cluster')));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LyScreenHeader(
              title: cluster.name,
              subtitle: cluster.description,
              onBack: () => context.pop(),
            ),
          ),
          if (lymarks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: LyIcons.topic(cluster.iconKey),
                accent: context.ly.accentFor(cluster.id),
                title: 'Nothing here yet.',
                message:
                    'Save something related to '
                    '${cluster.name} to start building this path.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.screen,
                LySpace.s,
                LySpace.screen,
                LySpace.xxl,
              ),
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
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
