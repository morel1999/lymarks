// Les rendus de reference dependent de la plateforme qui les a produits (ici
// Windows) : l'anticrenelage des polices differe sous Linux, d'ou 0,4 a 2 %
// de pixels d'ecart en CI. Ils sont donc tagues et exclus du runner Linux
// (`flutter test --exclude-tags golden`), et restent un outil local.
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lymarks/main.dart';
import 'package:lymarks/shared/data/mock_repository.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/knowledge.dart';

/// Rendus de référence des sept écrans.
///
/// Ils servent deux buts : constater le rendu réel sans device ni navigateur
/// (le renderer web ne s'initialise pas en headless), et détecter toute
/// régression visuelle. Régénération : `flutter test --update-goldens`.
///
/// Surface 420x1400 : format téléphone assez haut pour qu'un écran tienne
/// entier, sans quoi les listes paresseuses ne construisent pas leurs cartes.
const Size _phone = Size(420, 1400);

/// `pumpAndSettle` est inutilisable : le shimmer de l'état `processing`
/// boucle indéfiniment. On pompe un nombre fixe de frames.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Horloge figée : la Home salue selon l'heure, le Digest affiche la date du
/// jour, le Profil compte les mois — un golden qui suit l'horloge réelle
/// casse tout seul le lendemain.
final DateTime _fixedNow = DateTime(2026, 9, 4, 9);

ProviderContainer _container({List<Override> overrides = const []}) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _fixedNow),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _boot(WidgetTester tester, {ThemeMode? theme}) async {
  await tester.binding.setSurfaceSize(_phone);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = _container();
  if (theme != null) {
    container.read(themeModeProvider.notifier).state = theme;
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const LymarksApp(),
    ),
  );
  await _settle(tester);
}

Future<void> _shoot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(LymarksApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

Future<void> _skipOnboarding(WidgetTester tester) async {
  await tester.tap(find.text('Skip'));
  await _settle(tester);
}

/// Charge les vraies polices dans l'environnement de test.
///
/// Sans cela, `flutter test` rend chaque glyphe en pavé plein : les goldens
/// valideraient la mise en page mais pas la typographie ni les icônes.
Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final weight in ['400', '500', '600', '700']) {
    inter.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
  }
  await inter.load();

  // Le nom de famille d'une police de paquet est préfixé par Flutter.
  final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(
      rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
    );
  await lucide.load();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  testWidgets('01 onboarding promise', (tester) async {
    await _boot(tester);
    await _shoot(tester, '01-onboarding-promise');
  });

  testWidgets('01b onboarding mechanism', (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Get started'));
    await _settle(tester);
    await _shoot(tester, '02-onboarding-mechanism');
  });

  testWidgets('02 home', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await _shoot(tester, '03-home');
  });

  testWidgets('03 category path', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.text('Explore your AI knowledge'));
    await _settle(tester);
    await _shoot(tester, '04-category-path');
  });

  testWidgets('04 lymark detail', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.text('Building AI Agents').first);
    await _settle(tester);
    await _shoot(tester, '05-lymark-detail');
  });

  testWidgets('05 search initial', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.text('Search'));
    await _settle(tester);
    await _shoot(tester, '06-search-initial');
  });

  testWidgets('05b search results', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.text('Search'));
    await _settle(tester);
    await tester.enterText(find.byType(EditableText), 'react architecture');
    await _settle(tester);
    await _shoot(tester, '07-search-results');
  });

  testWidgets('06 daily digest', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.text('Digest'));
    await _settle(tester);
    await _shoot(tester, '08-digest');
  });

  testWidgets('07 profile', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.bySemanticsLabel('Profile'));
    await _settle(tester);
    await _shoot(tester, '09-profile');
  });

  testWidgets('07b settings', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.bySemanticsLabel('Profile'));
    await _settle(tester);
    await tester.tap(find.text('All settings'));
    await _settle(tester);
    await _shoot(tester, '10-settings');
  });

  testWidgets('paywall sheet', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.bySemanticsLabel('Profile'));
    await _settle(tester);
    // Le compte de démo est Pro : on repasse en Free pour voir le paywall.
    await tester.tap(find.text('Manage'));
    await _settle(tester);
    await tester.tap(find.text('Upgrade'));
    await _settle(tester);
    await _shoot(tester, '11-paywall');
  });

  testWidgets('home en mode sombre', (tester) async {
    await _boot(tester, theme: ThemeMode.dark);
    await _skipOnboarding(tester);
    await _shoot(tester, '12-home-dark');
  });

  testWidgets('detail en mode sombre', (tester) async {
    await _boot(tester, theme: ThemeMode.dark);
    await _skipOnboarding(tester);
    await tester.tap(find.text('Building AI Agents').first);
    await _settle(tester);
    await _shoot(tester, '13-detail-dark');
  });

  testWidgets('bibliotheque vide', (tester) async {
    await tester.binding.setSurfaceSize(_phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = _container(
      overrides: [
        lymarksRepositoryProvider.overrideWithValue(
          MockLymarksRepository(seed: const []),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LymarksApp(),
      ),
    );
    await _settle(tester);
    await _skipOnboarding(tester);
    await _shoot(tester, '14-home-empty');
  });

  testWidgets('search en plan Free declenche l upsell', (tester) async {
    await tester.binding.setSurfaceSize(_phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = _container();
    container.read(profileProvider.notifier).setPlan(UserPlan.free);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LymarksApp(),
      ),
    );
    await _settle(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.text('Search'));
    await _settle(tester);
    await tester.enterText(find.byType(EditableText), 'react component ideas');
    await _settle(tester);
    await _shoot(tester, '15-search-free-upsell');
  });
}
