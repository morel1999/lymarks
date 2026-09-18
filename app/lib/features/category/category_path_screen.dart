import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/features/home/home_screen.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/widgets/bookmark_card.dart';
import 'package:lymarks/shared/widgets/empty_state.dart';
import 'package:lymarks/shared/widgets/lymark_actions.dart';

/// 03 — Category Path.
///
/// Une catégorie n'est pas une liste : c'est un chemin dans une partie de sa
/// mémoire (wireframe 03 §Objectif). Le chemin est vertical, légèrement
/// sinueux, avec peu de nœuds — une métaphore visuelle, pas un graphe.
///
/// Les clusters ne sont pas encore calculés par le serveur : en mode réel la
/// page liste directement les lymarks rangés dans la catégorie, du plus
/// récent au plus ancien. Le chemin reste celui du jeu de démonstration.
class CategoryPathScreen extends ConsumerWidget {
  const CategoryPathScreen({required this.categoryId, super.key});

  final String categoryId;

  /// En réel il n'y a pas de chemin à construire : le lymark atterrit ici
  /// dès que l'IA l'a rangé.
  static String _emptyMessage(
    KnowledgeCategory category, {
    required bool live,
  }) => live
      ? 'Save something about ${category.name} and it will land here.'
      : 'Save something related to this category '
            'to start building this path.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(categoryId));
    if (category == null) {
      return const Scaffold(body: Center(child: Text('Unknown category')));
    }

    final live = ref.watch(categoriesModeProvider) == CategoriesMode.live;
    final lymarks = live
        ? ref.watch(categoryLymarksProvider(categoryId))
        : const <Lymark>[];
    final accent = context.ly.accentAt(category.accent);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LyScreenHeader(
              title: category.name,
              subtitle: '${category.count} Lymarks',
              onBack: () => context.pop(),
              trailing: LyCircleButton(
                icon: LyIcons.more,
                tooltip: 'Category options',
                onTap: () {},
              ),
            ),
          ),
          if (live && lymarks.isNotEmpty)
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
                itemBuilder: (context, i) => _CategoryCard(lymark: lymarks[i]),
              ),
            )
          else if (live || category.clusters.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: LyIcons.topic(category.iconKey),
                accent: accent,
                title: 'Nothing here yet.',
                message: _emptyMessage(category, live: live),
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
              sliver: SliverToBoxAdapter(
                child: _KnowledgePath(
                  clusters: category.clusters,
                  onOpen: (cluster) => context.push(
                    LyRoute.cluster(category.id, cluster.id),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Une carte de la liste plate (mode réel), câblée comme celles de la
/// bibliothèque : ouverture, menu, relance, tag vers la recherche.
class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.lymark});

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

/// Le chemin lui-même : des nœuds alternés, reliés par une courbe.
class _KnowledgePath extends StatelessWidget {
  const _KnowledgePath({required this.clusters, required this.onOpen});

  final List<KnowledgeCluster> clusters;
  final void Function(KnowledgeCluster cluster) onOpen;

  /// Hauteur fixe d'un nœud : la géométrie de la courbe en dépend.
  static const double nodeHeight = 148;
  static const double gap = 28;
  static const double indent = 44;
  static const double dotRadius = 7;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final total =
            clusters.length * nodeHeight + (clusters.length - 1) * gap;

        // Centre du point de chaque nœud, alterné gauche / droite.
        final dots = <Offset>[
          for (var i = 0; i < clusters.length; i++)
            Offset(
              i.isEven ? dotRadius + 2 : width - dotRadius - 2,
              i * (nodeHeight + gap) + nodeHeight * 0.42,
            ),
        ];

        return SizedBox(
          height: total,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter(
                    dots: dots,
                    color: ly.lavender.fill,
                    strokeWidth: 3,
                  ),
                ),
              ),
              for (var i = 0; i < clusters.length; i++)
                Positioned(
                  top: i * (nodeHeight + gap),
                  left: i.isEven ? indent : 0,
                  right: i.isEven ? 0 : indent,
                  height: nodeHeight,
                  child: _ClusterNode(
                    cluster: clusters[i],
                    accent: ly.accentAt(clusters[i].accent),
                    onTap: () => onOpen(clusters[i]),
                  ),
                ),
              for (var i = 0; i < clusters.length; i++)
                Positioned(
                  left: dots[i].dx - dotRadius,
                  top: dots[i].dy - dotRadius,
                  child: _PathDot(
                    color: ly.accentAt(clusters[i].accent).strong,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PathPainter extends CustomPainter {
  const _PathPainter({
    required this.dots,
    required this.color,
    required this.strokeWidth,
  });

  final List<Offset> dots;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (dots.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(dots.first.dx, dots.first.dy);
    for (var i = 0; i < dots.length - 1; i++) {
      final a = dots[i];
      final b = dots[i + 1];
      final midY = (a.dy + b.dy) / 2;
      // Une seule courbe douce par segment : « légèrement sinueux »,
      // jamais un graphe (wireframe 03 §Forme du chemin).
      path.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.dots != dots || old.color != color;
}

class _PathDot extends StatelessWidget {
  const _PathDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _KnowledgePath.dotRadius * 2,
      height: _KnowledgePath.dotRadius * 2,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: context.ly.surface, width: 3),
      ),
    );
  }
}

class _ClusterNode extends StatelessWidget {
  const _ClusterNode({
    required this.cluster,
    required this.accent,
    required this.onTap,
  });

  final KnowledgeCluster cluster;
  final LyAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Material(
      color: accent.fill,
      borderRadius: LyRadius.heroR,
      child: InkWell(
        onTap: onTap,
        borderRadius: LyRadius.heroR,
        child: Padding(
          padding: const EdgeInsets.all(LySpace.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ly.badgeInk,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LyIcons.topic(cluster.iconKey),
                      size: 20,
                      color: accent.strong,
                    ),
                  ),
                  const SizedBox(width: LySpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cluster.name,
                          style: context.texts.titleLarge?.copyWith(
                            color: accent.onFill,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cluster.description,
                          style: context.texts.bodySmall?.copyWith(
                            color: accent.onFill.withValues(alpha: 0.72),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    '${cluster.count} Lymarks',
                    style: context.texts.labelSmall?.copyWith(
                      color: accent.onFill.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: ly.card,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LyIcons.enter,
                      size: 16,
                      color: ly.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
