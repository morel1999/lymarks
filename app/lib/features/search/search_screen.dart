import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/widgets/bookmark_card.dart';
import 'package:lymarks/shared/widgets/empty_state.dart';
import 'package:lymarks/shared/widgets/ly_card.dart';
import 'package:lymarks/shared/widgets/lymark_actions.dart';
import 'package:lymarks/shared/widgets/mascot.dart';
import 'package:lymarks/shared/widgets/paywall_sheet.dart';
import 'package:lymarks/shared/widgets/search_field.dart';

/// 05 — Search.
///
/// Une expérience de **récupération**, pas d'exploration : un seul champ, pas
/// de filtre, pas de syntaxe, pas de choix de mode (wireframe 05, UX Bible
/// règle 5). La requête et la position sont conservées dans les providers,
/// donc restaurées au retour d'une fiche (règle 10).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Une requête en langage naturel (plusieurs mots) part en sémantique.
  /// L'utilisateur ne choisit jamais le mode (wireframe 05 §Principe).
  static bool _isSemantic(String q) => looksSemantic(q);

  void _submit(String value) {
    ref.read(recentSearchesProvider.notifier).push(value);
    if (_isSemantic(value) && !ref.read(profileProvider).isPro) {
      unawaited(
        PaywallSheet.show(context, trigger: PaywallTrigger.semanticSearch),
      );
    }
  }

  void _setQuery(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    ref.read(searchQueryProvider.notifier).state = value;
    _submit(value);
  }

  @override
  Widget build(BuildContext context) {
    // Le champ peut être alimenté depuis un tag : on resynchronise.
    final query = ref.watch(searchQueryProvider);
    if (_controller.text != query) {
      _controller
        ..text = query
        ..selection = TextSelection.collapsed(offset: query.length);
    }

    final isPro = ref.watch(profileProvider).isPro;
    final results = ref.watch(searchResultsProvider);
    final semantic = _isSemantic(query);
    final error = ref.watch(searchStateProvider).error;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              LySpace.screen,
              LySpace.xxl + LySpace.l,
              LySpace.screen,
              LySpace.l,
            ),
            sliver: SliverToBoxAdapter(
              child: Text('Search', style: context.texts.displayLarge),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: LySpace.screen),
            sliver: SliverToBoxAdapter(
              child: SearchField(
                controller: _controller,
                semantic: semantic,
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
                onSubmitted: _submit,
                onClear: () {
                  _controller.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              ),
            ),
          ),
          if (query.trim().isEmpty)
            SliverToBoxAdapter(child: _InitialState(onPick: _setQuery))
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.screen,
                LySpace.l,
                LySpace.screen,
                LySpace.l,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: SearchModeLabel(
                        semantic: semantic,
                        isPro: isPro,
                      ),
                    ),
                    const SizedBox(width: LySpace.m),
                    Text(
                      results.length == 1
                          ? '1 result'
                          : '${results.length} results',
                      style: context.texts.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
            if (semantic && !isPro)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  LySpace.screen,
                  0,
                  LySpace.screen,
                  LySpace.l,
                ),
                sliver: SliverToBoxAdapter(
                  child: _SemanticUpsell(
                    onUpgrade: () => PaywallSheet.show(
                      context,
                      trigger: PaywallTrigger.semanticSearch,
                    ),
                  ),
                ),
              ),
            if (results.isEmpty)
              SliverToBoxAdapter(child: _NoResults(error: error))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: LySpace.screen),
                sliver: SliverList.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: LySpace.m),
                  itemBuilder: (context, i) {
                    final lymark = results[i];
                    return BookmarkCard(
                      lymark,
                      onTap: () => context.push(LyRoute.lymark(lymark.id)),
                      onMenu: () =>
                          LymarkActions.showMenu(context, ref, lymark),
                      onRetry: () =>
                          ref.read(lymarksProvider.notifier).retry(lymark.id),
                      onTagTap: _setQuery,
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
}

class _InitialState extends ConsumerWidget {
  const _InitialState({required this.onPick});

  final void Function(String query) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ly = context.ly;
    final recent = ref.watch(recentSearchesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LySpace.screen,
        LySpace.xxl,
        LySpace.screen,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search your Lymarks', style: context.texts.titleLarge),
          const SizedBox(height: LySpace.s),
          Text(
            'Find something you saved without remembering '
            'the exact words.',
            style: context.texts.bodyMedium?.copyWith(color: ly.textSecondary),
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: LySpace.xxl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent searches',
                    style: context.texts.labelSmall?.copyWith(
                      color: ly.textTertiary,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(recentSearchesProvider.notifier).clear(),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: LySpace.s),
            for (var i = 0; i < recent.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: LySpace.s),
                child: _RecentRow(
                  query: recent[i],
                  accent: ly.accents[i % ly.accents.length],
                  onTap: () => onPick(recent[i]),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.query,
    required this.accent,
    required this.onTap,
  });

  final String query;
  final LyAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LyCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: LySpace.l,
        vertical: LySpace.m,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.fill,
              borderRadius: LyRadius.tileR,
            ),
            child: Icon(LyIcons.clock, size: 16, color: accent.onFill),
          ),
          const SizedBox(width: LySpace.m),
          Expanded(child: Text(query, style: context.texts.bodyLarge)),
          Icon(
            LyIcons.enter,
            size: 16,
            color: context.ly.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _SemanticUpsell extends StatelessWidget {
  const _SemanticUpsell({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return LyCard(
      color: ly.primarySoft,
      borderColor: ly.primarySoft,
      onTap: onUpgrade,
      child: Row(
        children: [
          Icon(LyIcons.sparkle, size: 20, color: ly.primary),
          const SizedBox(width: LySpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Searching by meaning is a Pro feature',
                  style: context.texts.titleSmall?.copyWith(color: ly.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  'These results match your words. '
                  'Pro also matches your intent.',
                  style: context.texts.bodySmall?.copyWith(
                    color: ly.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(LyIcons.forward, size: 18, color: ly.primary),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({this.error});

  /// Message du serveur quand la recherche a été refusée (plan, réseau) :
  /// un « 0 résultat » muet cacherait la vraie cause.
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: LySpace.xxl),
      child: EmptyState(
        icon: LyIcons.search,
        // Recherche vaine : la mascotte cherche encore. Un refus du serveur,
        // lui, est une panne — pas le moment de faire le mignon.
        pose: error == null ? MascotPose.searching : null,
        title: error == null ? 'Nothing surfaced yet.' : 'Search unavailable.',
        message:
            error ??
            'Try describing what you remember '
                'rather than searching exact words.',
      ),
    );
  }
}
