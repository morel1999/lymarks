import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/shared/data/mock_repository.dart';
import 'package:lymarks/shared/data/providers.dart';

void main() {
  test('la recherche attend la fin de la frappe : une requête, pas une par '
      'lettre', () async {
    final repo = MockLymarksRepository();
    final c = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWithValue(DemoAuthSession()),
        lymarksRepositoryProvider.overrideWithValue(repo),
        searchDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 20),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.read(searchStateProvider); // arme l'écoute de la saisie

    for (final typed in ['l', 'ly', 'lym', 'lyma']) {
      c.read(searchQueryProvider.notifier).state = typed;
    }
    expect(repo.calls.where((x) => x.startsWith('search:')), isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(repo.calls.where((x) => x.startsWith('search:')), [
      'search:lyma:text',
    ]);
    expect(c.read(searchStateProvider).query, 'lyma');
  });

  test('sans délai (démo, tests) : immédiat', () async {
    final repo = MockLymarksRepository();
    final c = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWithValue(DemoAuthSession()),
        lymarksRepositoryProvider.overrideWithValue(repo),
        searchDebounceProvider.overrideWithValue(null),
      ],
    );
    addTearDown(c.dispose);
    c.read(searchStateProvider);
    c.read(searchQueryProvider.notifier).state = 'ia';
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls.where((x) => x.startsWith('search:')), isNotEmpty);
  });
}
