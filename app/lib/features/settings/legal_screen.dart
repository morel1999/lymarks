import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/features/home/home_screen.dart';
import 'package:lymarks/shared/widgets/ly_card.dart';

/// Les textes de référence — confidentialité et conditions.
///
/// Dans l'app et pas derrière un lien : ce sont les deux pages qu'on
/// consulte au moment précis où l'on doute, souvent sans réseau. Le ton reste
/// celui du produit (UX Bible §Ton) : concret, sobre, jamais culpabilisant —
/// on dit ce qu'on fait des données, pas ce que le lecteur risque.
class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.page, super.key});

  final LegalPage page;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LyScreenHeader(
              title: page.title,
              subtitle: page.updated,
              onBack: () => context.pop(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              LySpace.screen,
              0,
              LySpace.screen,
              LySpace.xxl,
            ),
            sliver: SliverList.list(
              children: [
                // L'essentiel d'abord : qui lit jusqu'au bout ?
                LyCard(
                  color: page.accent(ly).fill,
                  borderColor: page.accent(ly).fill,
                  child: Text(
                    page.essence,
                    style: context.texts.titleSmall?.copyWith(
                      color: page.accent(ly).onFill,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: LySpace.xl),
                for (final section in page.sections) ...[
                  _Section(section: section, accent: page.accent(ly)),
                  const SizedBox(height: LySpace.xl),
                ],
                Text(
                  page.footer,
                  style: context.texts.bodySmall?.copyWith(
                    color: ly.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.section, required this.accent});

  final LegalSection section;
  final LyAccent accent;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Le même point que les nœuds d'un chemin : un repère, pas un
            // ornement.
            Container(
              margin: const EdgeInsets.only(top: 7),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent.strong,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: LySpace.s),
            Expanded(
              child: Text(section.heading, style: context.texts.titleSmall),
            ),
          ],
        ),
        const SizedBox(height: LySpace.s),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.body,
                style: context.texts.bodyMedium?.copyWith(
                  color: ly.textSecondary,
                  height: 1.55,
                ),
              ),
              for (final point in section.points) ...[
                const SizedBox(height: LySpace.s),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 9),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ly.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: LySpace.s),
                    Expanded(
                      child: Text(
                        point,
                        style: context.texts.bodyMedium?.copyWith(
                          color: ly.textSecondary,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Une section : un titre, un paragraphe, et au besoin des points.
class LegalSection {
  const LegalSection({
    required this.heading,
    required this.body,
    this.points = const [],
  });

  final String heading;
  final String body;
  final List<String> points;
}

/// Un texte de référence complet.
class LegalPage {
  const LegalPage({
    required this.title,
    required this.updated,
    required this.essence,
    required this.sections,
    required this.footer,
    required this.accent,
  });

  final String title;
  final String updated;

  /// Une phrase qui tient lieu de résumé, en tête de page.
  final String essence;
  final List<LegalSection> sections;
  final String footer;
  final LyAccent Function(LyPalette ly) accent;
}
