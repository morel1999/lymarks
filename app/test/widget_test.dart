import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/main.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/lymark.dart';

/// Avance l'horloge de test sans attendre la stabilisation de l'arbre.
///
/// `pumpAndSettle` est inutilisable dès qu'un lymark `processing` est à
/// l'écran : son shimmer boucle indéfiniment (Design System : 1,2 s en
/// boucle), donc l'arbre ne se stabilise jamais. On pompe donc un nombre
/// fixe de frames, largement supérieur aux 250 ms de transition maximale
/// autorisés par l'UX Bible (règle 8).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  group('Parcours principal', () {
    testWidgets('l onboarding mene a la Home', (tester) async {
      // Les listes sont paresseuses : sur la surface de test par défaut
      // (800x600) les cartes ne sont jamais construites. On prend un format
      // téléphone haut pour que la Home tienne en entier.
      await tester.binding.setSurfaceSize(const Size(420, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const ProviderScope(child: LymarksApp()));
      await settle(tester);

      expect(
        find.text('Turn forgotten links\ninto active memory.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Skip'));
      await settle(tester);

      expect(find.text('All Lymarks'), findsOneWidget);
      expect(find.text('Building AI Agents'), findsWidgets);
    });

    testWidgets('les trois onglets sont accessibles', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: LymarksApp()));
      await settle(tester);
      await tester.tap(find.text('Skip'));
      await settle(tester);

      await tester.tap(find.text('Search'));
      await settle(tester);
      expect(find.text('Search your Lymarks'), findsOneWidget);

      await tester.tap(find.text('Digest'));
      await settle(tester);
      expect(find.text('Daily Digest'), findsOneWidget);
    });
  });

  group('Regles produit', () {
    test('la palette expose cinq familles d accent', () {
      expect(LyPalette.light.accents, hasLength(5));
      expect(LyPalette.dark.accents, hasLength(5));
    });

    test('accentFor est stable pour une meme cle', () {
      final a = LyPalette.light.accentFor('ai');
      final b = LyPalette.light.accentFor('ai');
      expect(identical(a, b), isTrue);
    });

    test('la suppression est reversible a la meme position', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(lymarksProvider.notifier);
      final before = container.read(lymarksProvider);
      final target = before[2];

      final removed = notifier.remove(target.id);
      expect(removed, isNotNull);
      expect(container.read(lymarksProvider), hasLength(before.length - 1));

      notifier.restore(removed!.lymark, removed.index);
      expect(container.read(lymarksProvider)[2].id, target.id);
    });

    test('un lymark en echec repasse en traitement au retry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(lymarksProvider.notifier);
      final failed = container
          .read(lymarksProvider)
          .firstWhere((l) => l.status == LymarkStatus.failed);

      notifier.retry(failed.id);
      expect(notifier.byId(failed.id)!.status, LymarkStatus.processing);
    });

    test('la recherche plein texte couvre titre, mots-cles et note', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(searchStateProvider.notifier).run('agents');
      final results = container.read(searchResultsProvider);

      expect(results, isNotEmpty);
      expect(results.first.title, 'Building AI Agents');
    });

    test('une requete vide ne retourne aucun resultat', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(searchStateProvider.notifier).run('   ');
      expect(container.read(searchResultsProvider), isEmpty);
    });

    test('la requete courante declenche la recherche', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Le notifier n'écoute la requête qu'une fois construit.
      container.read(searchStateProvider);
      container.read(searchQueryProvider.notifier).state = 'agents';
      await Future<void>.delayed(Duration.zero);

      expect(container.read(searchResultsProvider), isNotEmpty);
    });
  });
}
