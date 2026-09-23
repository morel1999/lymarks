// Captures de soumission Devpost.
//
// Le règlement demande du **1179 × 2556, sans cadre d'appareil**. C'est
// exactement 393 × 852 points à 3×, soit un vrai format de téléphone — et
// non les 420 × 1400 des rendus de référence, une hauteur qu'aucun appareil
// n'a, choisie là-bas pour qu'un écran entier tienne dans une seule image.
//
// Les captures sont donc rendues par l'app elle-même, à la dimension exacte
// exigée : pas de redimensionnement, pas de cadre à détourer, et elles se
// refont d'une commande si le design bouge.
//
//   flutter test --tags golden test/devpost_test.dart --update-goldens
//
// Taguées `golden` comme les rendus de référence : la CI les exclut, parce
// qu'elles dépendent elles aussi de la plateforme qui les a produites.
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lymarks/main.dart';
import 'package:lymarks/shared/data/mock_data.dart';
import 'package:lymarks/shared/data/mock_repository.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/widgets/mascot.dart';

/// 393 × 852 points × 3 = 1179 × 2556 pixels, la dimension exigée.
const Size _store = Size(393, 852);

/// Le jeu de démo, cartes en traitement retirées.
final List<Lymark> _ready = [
  for (final l in MockData.lymarks)
    if (l.status == LymarkStatus.ready) l,
];

/// Horloge figée : une capture qui suit l'horloge réelle se périme seule.
final DateTime _fixedNow = DateTime(2026, 9, 4, 9);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _loadFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
  await inter.load();

  final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(
      rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
    );
  await lucide.load();
}

Future<void> _precacheImages(WidgetTester tester) async {
  final context = tester.element(find.byType(LymarksApp));
  await tester.runAsync(() async {
    for (final pose in MascotPose.values) {
      await precacheImage(AssetImage(pose.asset), context);
    }
  });
}

Future<ProviderContainer> _boot(
  WidgetTester tester, {
  UserPlan? plan,
  List<Override> overrides = const [],
}) async {
  await tester.binding.setSurfaceSize(_store);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _fixedNow),
      splashDurationProvider.overrideWithValue(Duration.zero),
      // Que des lymarks aboutis. Le jeu de demo porte des cartes en cours
      // de traitement, utiles aux rendus de reference — un squelette de
      // chargement dans une capture de soumission, lui, ne montre rien.
      lymarksRepositoryProvider.overrideWithValue(
        MockLymarksRepository(seed: _ready),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  if (plan != null) container.read(profileProvider.notifier).setPlan(plan);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const LymarksApp(),
    ),
  );
  await _precacheImages(tester);
  await _settle(tester);
  return container;
}

Future<void> _skipOnboarding(WidgetTester tester) async {
  await tester.tap(find.text('Skip'));
  await _settle(tester);
}

Future<void> _shoot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(LymarksApp),
    matchesGoldenFile('../devpost/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  testWidgets('01 la Home', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await _shoot(tester, '01-home');
  });

  testWidgets('02 une fiche', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.text('Building AI Agents').first);
    await _settle(tester);
    await _shoot(tester, '02-lymark');
  });

  testWidgets('03 le chemin d une categorie', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.text('Explore your AI knowledge'));
    await _settle(tester);
    await _shoot(tester, '03-category-path');
  });

  testWidgets('04 des lymarks gardes hors d atteinte', (tester) async {
    // L'histoire RevenueCat : au-dela de la limite Free le lien est garde,
    // pas perdu, et le passage a Pro l'ouvre.
    final seed = [
      ..._ready.take(1),
      for (final l in _ready.skip(1).take(3)) l.copyWith(locked: true),
    ];
    await _boot(
      tester,
      plan: UserPlan.free,
      overrides: [
        lymarksRepositoryProvider.overrideWithValue(
          MockLymarksRepository(seed: seed),
        ),
      ],
    );
    await _skipOnboarding(tester);
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -700),
    );
    await _settle(tester);
    await _shoot(tester, '04-locked');
  });

  testWidgets('05 le paywall', (tester) async {
    await _boot(tester, plan: UserPlan.free);
    await _skipOnboarding(tester);
    await tester.tap(find.bySemanticsLabel('Profile'));
    await _settle(tester);
    await tester.tap(find.text('Upgrade'));
    await _settle(tester);
    await _shoot(tester, '05-paywall');
  });
}
