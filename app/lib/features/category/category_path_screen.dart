import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/features/home/home_screen.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/widgets/empty_state.dart';
import 'package:lymarks/shared/widgets/mascot.dart';

/// 03 — Category Path.
///
/// Une catégorie n'est pas une liste : c'est un chemin dans une partie de sa
/// mémoire (wireframe 03 §Objectif). Le chemin est vertical, légèrement
/// sinueux, avec des nœuds alternés — une métaphore visuelle, pas un graphe.
///
/// **Les nœuds sont les lymarks eux-mêmes.** Le wireframe imaginait un niveau
/// intermédiaire de clusters thématiques ; il supposait un regroupement
/// automatique que ni le PRD ni le Knowledge Vault Spec n'ont jamais défini
/// (wireframe 03 §Point à formaliser). Plutôt que d'inventer cette règle dans
/// l'urgence, le chemin mène droit au contenu : il fonctionne sur les vraies
/// données, en démo comme en réel, et la fiche est à un tap au lieu de deux.
/// Les clusters pourront revenir comme niveau supplémentaire le jour où leur
/// calcul sera spécifié.
class CategoryPathScreen extends ConsumerWidget {
  const CategoryPathScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(categoryId));
    if (category == null) {
      return const Scaffold(body: Center(child: Text('Unknown category')));
    }

    final lymarks = ref.watch(categoryLymarksProvider(categoryId));
    final accent = context.ly.accentAt(category.accent);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LyScreenHeader(
              title: category.name,
              // Ce que le chemin montre vraiment, jamais un compte annonce
              // ailleurs : les deux ne peuvent plus diverger.
              subtitle: lymarks.length == 1
                  ? '1 Lymark'
                  : '${lymarks.length} Lymarks',
              onBack: () => context.pop(),
            ),
          ),
          if (lymarks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: LyIcons.topic(category.iconKey),
                accent: accent,
                pose: MascotPose.empty,
                title: 'Nothing here yet.',
                message:
                    'Save something about ${category.name} '
                    'and it will land here.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.screen,
                LySpace.l,
                LySpace.screen,
                LySpace.xxl,
              ),
              sliver: SliverToBoxAdapter(
                child: _KnowledgePath(
                  lymarks: lymarks,
                  onOpen: (lymark) => context.push(LyRoute.lymark(lymark.id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Le chemin lui-même : des nœuds alternés, reliés par une courbe.
class _KnowledgePath extends StatelessWidget {
  const _KnowledgePath({required this.lymarks, required this.onOpen});

  final List<Lymark> lymarks;
  final void Function(Lymark lymark) onOpen;

  /// Hauteur fixe d'un nœud : la géométrie de la courbe en dépend.
  static const double nodeHeight = 148;
  static const double gap = 28;
  static const double indent = 44;
  static const double dotRadius = 7;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    LyAccent accentOf(Lymark l) => ly.accentOr(l.accentSlot, l.accentKey);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final total = lymarks.length * nodeHeight + (lymarks.length - 1) * gap;

        // Centre du point de chaque nœud, alterné gauche / droite.
        final dots = <Offset>[
          for (var i = 0; i < lymarks.length; i++)
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
                    color: ly.cardBorder,
                    strokeWidth: 3,
                  ),
                ),
              ),
              for (var i = 0; i < lymarks.length; i++)
                Positioned(
                  top: i * (nodeHeight + gap),
                  left: i.isEven ? indent : 0,
                  right: i.isEven ? 0 : indent,
                  height: nodeHeight,
                  child: _LymarkNode(
                    lymark: lymarks[i],
                    accent: accentOf(lymarks[i]),
                    onTap: () => onOpen(lymarks[i]),
                  ),
                ),
              for (var i = 0; i < lymarks.length; i++)
                Positioned(
                  left: dots[i].dx - dotRadius,
                  top: dots[i].dy - dotRadius,
                  child: _PathDot(color: accentOf(lymarks[i]).strong),
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Un nœud du chemin : le titre, sa source, et la flèche pour entrer.
///
/// Volontairement dépouillé. Les puces, les mots-clés et la note vivent sur
/// la fiche ; ici on ne donne que de quoi reconnaître ce qu'on avait gardé.
class _LymarkNode extends StatelessWidget {
  const _LymarkNode({
    required this.lymark,
    required this.accent,
    required this.onTap,
  });

  final Lymark lymark;
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
                      LyIcons.forDomain(lymark.domain),
                      size: 20,
                      color: accent.strong,
                    ),
                  ),
                  const SizedBox(width: LySpace.m),
                  Expanded(
                    child: Text(
                      lymark.title,
                      style: context.texts.titleLarge?.copyWith(
                        color: accent.onFill,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    lymark.domain,
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
                    child: Icon(LyIcons.enter, size: 16, color: ly.textPrimary),
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
