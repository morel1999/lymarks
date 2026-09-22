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
import 'package:lymarks/shared/widgets/digest_card.dart';
import 'package:lymarks/shared/widgets/empty_state.dart';
import 'package:lymarks/shared/widgets/ly_card.dart';
import 'package:lymarks/shared/widgets/mascot.dart';
import 'package:lymarks/shared/widgets/paywall_sheet.dart';

/// 06 — Daily Digest.
///
/// Search répond à « je cherche quelque chose » ; le Digest répond à
/// « Lymarks me rappelle quelque chose au bon moment ». C'est la boucle de
/// mémoire qui se referme (wireframe 06 §Objectif).
///
/// Le ton est éditorial et calme. Aucune série, aucun badge, aucun compteur
/// d'engagement : l'UX Bible interdit explicitement la gamification (§Ton) et
/// limite le digest à un rappel par jour (règle 6).
class DigestScreen extends ConsumerWidget {
  const DigestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(digestProvider);
    final isPro = ref.watch(profileProvider).isPro;
    final today = ref.watch(clockProvider)();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Digest',
                          style: context.texts.displayLarge,
                        ),
                        const SizedBox(height: LySpace.s),
                        Text(
                          LyTime.digestHeading(today),
                          style: context.texts.bodyMedium?.copyWith(
                            color: context.ly.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: LySpace.m),
                  LyCircleButton(
                    icon: LyIcons.calendar,
                    tooltip: 'Digest settings',
                    onTap: () => context.push(LyRoute.settings),
                  ),
                ],
              ),
            ),
          ),
          if (!isPro)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.screen,
                0,
                LySpace.screen,
                LySpace.l,
              ),
              sliver: SliverToBoxAdapter(
                child: _DigestUpsell(
                  onUpgrade: () => PaywallSheet.show(
                    context,
                    trigger: PaywallTrigger.dailyDigest,
                  ),
                ),
              ),
            ),
          if (entries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: LyIcons.digest,
                pose: MascotPose.sleeping,
                title: 'Nothing to revisit yet.',
                message:
                    "Keep saving things. We'll bring something back "
                    'when it matters.',
              ),
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
                child: Text(
                  'A few things worth revisiting',
                  style: context.texts.headlineSmall,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: LySpace.screen),
              sliver: SliverList.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: LySpace.l),
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  return DigestCard(
                    lymark: entry.lymark,
                    reason: entry.reason,
                    onOpen: () => context.push(LyRoute.lymark(entry.lymark.id)),
                    onSnooze: () => _snack(
                      context,
                      "Snoozed. We won't surface it for a week.",
                    ),
                    onArchive: () {
                      ref
                          .read(lymarksProvider.notifier)
                          .archive(entry.lymark.id);
                      _snack(context, 'Archived.');
                    },
                  );
                },
              ),
            ),
          ],
          const SliverToBoxAdapter(
            child: SizedBox(height: LySpace.navBarInset),
          ),
        ],
      ),
    );
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }
}

class _DigestUpsell extends StatelessWidget {
  const _DigestUpsell({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return LyCard(
      color: ly.lime.fill,
      borderColor: ly.lime.fill,
      onTap: onUpgrade,
      child: Row(
        children: [
          Icon(LyIcons.digest, size: 20, color: ly.lime.onFill),
          const SizedBox(width: LySpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Digest is a Pro feature',
                  style: context.texts.titleSmall?.copyWith(
                    color: ly.lime.onFill,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'One forgotten link a day, at the hour you choose.',
                  style: context.texts.bodySmall?.copyWith(
                    color: ly.lime.onFill.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Icon(LyIcons.forward, size: 18, color: ly.lime.onFill),
        ],
      ),
    );
  }
}
