import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lymarks/core/api/api_client.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/main.dart';
import 'package:lymarks/shared/data/lymarks_repository.dart';
import 'package:lymarks/shared/data/mock_data.dart';
import 'package:lymarks/shared/data/mock_repository.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/data/taxonomy.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/widgets/category_card.dart';

/// Rangement des lymarks en catégories.
///
/// `AppConfig.isDemo` vient d'un `--dart-define` que les tests ne contrôlent
/// pas : on force le mode réel en surchargeant `categoriesModeProvider`, et
/// le jeu de données via le dépôt (mock en mémoire, ou API sur `MockClient`
/// pour vérifier le chemin complet depuis le JSON).
final DateTime _now = DateTime(2026, 9, 18, 12);

Lymark _lymark(
  String id, {
  String? category,
  int daysAgo = 0,
  bool archived = false,
}) => Lymark(
  id: id,
  url: 'https://example.com/$id',
  domain: 'example.com',
  title: id,
  savedAt: _now.subtract(Duration(days: daysAgo)),
  categoryId: category,
  archived: archived,
);

/// Jeu de référence : trois `science`, un `sport`, un sans catégorie.
final List<Lymark> _seed = [
  _lymark('sci-old', category: 'science', daysAgo: 9),
  _lymark('sport-1', category: 'sport', daysAgo: 4),
  _lymark('sci-mid', category: 'science', daysAgo: 3),
  _lymark('loose', daysAgo: 2),
  _lymark('sci-new', category: 'science', daysAgo: 1),
];

ProviderContainer _container({
  required List<Lymark> seed,
  CategoriesMode mode = CategoriesMode.live,
}) {
  final container = ProviderContainer(
    overrides: [
      authSessionProvider.overrideWithValue(DemoAuthSession()),
      categoriesModeProvider.overrideWithValue(mode),
      lymarksRepositoryProvider.overrideWithValue(
        MockLymarksRepository(seed: seed),
      ),
      processingPollProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  group('Taxonomie', () {
    test('dix catégories, other jamais en carte', () {
      expect(Taxonomy.all, hasLength(10));
      expect(Taxonomy.all.map((c) => c.id), contains(Taxonomy.otherId));
      expect(Taxonomy.cards, hasLength(9));
      expect(Taxonomy.cards.map((c) => c.id), isNot(contains('other')));
    });

    test('les catégories de démo gardent leur couleur', () {
      for (final mock in MockData.categories) {
        expect(Taxonomy.byId(mock.id)?.accent, mock.accent, reason: mock.id);
      }
    });
  });

  group('categoriesProvider en mode réel', () {
    test('une carte par catégorie présente, la plus fournie en tête', () {
      final c = _container(seed: _seed);
      final cards = c.read(categoriesProvider);

      expect(cards.map((k) => k.id), ['science', 'sport']);
      expect(cards.first.count, 3);
      expect(cards.last.count, 1);
    });

    test('un lymark archivé ne compte pas', () {
      final c = _container(
        seed: [
          ..._seed,
          _lymark('sci-gone', category: 'science', archived: true),
          _lymark('life-gone', category: 'lifestyle', archived: true),
        ],
      );
      final cards = c.read(categoriesProvider);

      expect(cards.map((k) => k.id), ['science', 'sport']);
      expect(cards.first.count, 3);
    });

    test('à égalité, l ordre de la taxonomie départage', () {
      final c = _container(
        seed: [
          _lymark('a', category: 'sport'),
          _lymark('b', category: 'science'),
          _lymark('c', category: 'ai'),
        ],
      );
      expect(
        c.read(categoriesProvider).map((k) => k.id),
        ['ai', 'science', 'sport'],
      );
    });

    test('other et un identifiant inconnu ne font pas de carte', () {
      final c = _container(
        seed: [
          _lymark('a', category: 'other'),
          _lymark('b', category: 'astrology'),
        ],
      );
      expect(c.read(categoriesProvider), isEmpty);
    });

    test('la liste suit la bibliothèque', () {
      final c = _container(seed: _seed);
      expect(c.read(categoriesProvider), hasLength(2));

      c.read(lymarksProvider.notifier).remove('sport-1');
      expect(c.read(categoriesProvider).map((k) => k.id), ['science']);
    });

    test('depuis GET /bookmarks : la catégorie choisie par l API', () async {
      Map<String, Object?> json(String id, String category) => {
        'id': id,
        'url': 'https://example.com/$id',
        'domain': 'example.com',
        'title': id,
        'source': 'web',
        'status': 'ready',
        'bullets': const <String>[],
        'keywords': const <String>[],
        'savedAt': '2026-09-18T10:00:00.000Z',
        'updatedAt': '2026-09-18T10:00:00.000Z',
        'archived': false,
        'savedCount': 1,
        'category': category,
      };
      final api = ApiClient(
        baseUrl: 'https://api.test',
        token: () async => 'jwt',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'items': [json('a', 'culture'), json('b', 'other')],
              'nextCursor': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      final c = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWithValue(DemoAuthSession()),
          categoriesModeProvider.overrideWithValue(CategoriesMode.live),
          lymarksRepositoryProvider.overrideWithValue(
            ApiLymarksRepository(api),
          ),
          processingPollProvider.overrideWithValue(null),
        ],
      );
      addTearDown(c.dispose);

      await c.read(lymarksProvider.notifier).refresh();
      final cards = c.read(categoriesProvider);
      expect(cards.single.id, 'culture');
      expect(cards.single.name, 'Culture & Media');
      expect(cards.single.count, 1);
    });
  });

  group('categoryLymarksProvider', () {
    test('du plus récent au plus ancien, sans archivé', () {
      final c = _container(
        seed: [
          ..._seed,
          _lymark('sci-gone', category: 'science', archived: true),
        ],
      );
      expect(
        c.read(categoryLymarksProvider('science')).map((l) => l.id),
        ['sci-new', 'sci-mid', 'sci-old'],
      );
      expect(c.read(categoryLymarksProvider('lifestyle')), isEmpty);
    });
  });

  group('categoryByIdProvider', () {
    test('une catégorie vide s ouvre quand même', () {
      final c = _container(seed: _seed);
      final lifestyle = c.read(categoryByIdProvider('lifestyle'));

      expect(lifestyle, isNotNull);
      expect(lifestyle!.count, 0);
      expect(lifestyle.name, 'Lifestyle');
      expect(c.read(categoryByIdProvider('science'))?.count, 3);
      expect(c.read(categoryByIdProvider('nope')), isNull);
    });
  });

  group('mode démo', () {
    test('les tests tournent en démo par défaut', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(categoriesModeProvider), CategoriesMode.demo);
    });

    test('MockData.categories, inchangé, clusters compris', () {
      final c = _container(seed: _seed, mode: CategoriesMode.demo);
      final cards = c.read(categoriesProvider);

      expect(identical(cards, MockData.categories), isTrue);
      expect(cards.first.id, 'ai');
      expect(cards.first.count, greaterThan(0));
      // Une catégorie absente de la démo reste ouvrable.
      expect(c.read(categoryByIdProvider('science'))?.count, 0);
    });
  });

  group('Home en mode réel', () {
    testWidgets('sans catégorie : une carte le dit, pas de démo', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = _container(seed: [_lymark('loose')]);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const LymarksApp()),
      );
      await _settle(tester);
      await tester.tap(find.text('Skip'));
      await _settle(tester);

      expect(find.text('Your categories appear as you save'), findsOneWidget);
      expect(find.byType(CategoryHeroCard), findsNothing);
      expect(find.text('Explore your AI knowledge'), findsNothing);
    });

    testWidgets('avec des catégories : hero puis vignettes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = _container(seed: _seed);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const LymarksApp()),
      );
      await _settle(tester);
      await tester.tap(find.text('Skip'));
      await _settle(tester);

      expect(find.byType(CategoriesEmptyCard), findsNothing);
      expect(find.byType(CategoryHeroCard), findsOneWidget);
      expect(find.text('Science'), findsOneWidget);
      expect(find.byType(CategoryTile), findsOneWidget);
      expect(find.text('Sport'), findsOneWidget);
    });
  });
}
