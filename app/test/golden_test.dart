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
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/main.dart';
import 'package:lymarks/shared/data/mock_data.dart';
import 'package:lymarks/shared/data/mock_repository.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/widgets/bookmark_card.dart';
import 'package:lymarks/shared/widgets/category_card.dart';
import 'package:lymarks/shared/widgets/mascot.dart';

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
      // L'ouverture de l'app n'a pas a etre traversee par chaque test.
      splashDurationProvider.overrideWithValue(Duration.zero),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _boot(
  WidgetTester tester, {
  ThemeMode? theme,
  UserPlan? plan,
  List<Override> overrides = const [],
}) async {
  await tester.binding.setSurfaceSize(_phone);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = _container(overrides: overrides);
  if (theme != null) {
    container.read(themeModeProvider.notifier).state = theme;
  }
  if (plan != null) {
    container.read(profileProvider.notifier).setPlan(plan);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const LymarksApp(),
    ),
  );
  await _precacheImages(tester);
  await _settle(tester);
}

/// Décode les images embarquées avant la capture.
///
/// `Image.asset` lit le bundle de façon asynchrone : dans un test de widget,
/// l'horloge est simulée et le décodage n'aboutit jamais entre deux `pump`.
/// La mascotte de l'onboarding sortait donc blanche du rendu. `runAsync`
/// rend la main au vrai event loop le temps de remplir le cache d'images,
/// dans lequel le widget puise ensuite sans attendre.
Future<void> _precacheImages(WidgetTester tester) async {
  final context = tester.element(find.byType(LymarksApp));
  await tester.runAsync(() async {
    for (final pose in MascotPose.values) {
      await precacheImage(AssetImage(pose.asset), context);
    }
  });
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
    // Le compte de démo est Pro, et « Manage » mène desormais au store, pas
    // au paywall : on part donc d'un compte Free.
    await _boot(tester, plan: UserPlan.free);
    await _skipOnboarding(tester);
    await tester.tap(find.bySemanticsLabel('Profile'));
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

  // Les poses de la mascotte.
  //
  // Les captures ci-dessus ne traversent aucun des six points où la mascotte
  // remplace une icône : sans ces rendus, un asset manquant ou une pose
  // inversée passerait sans bruit.

  testWidgets('16 connexion : la mascotte salue', (tester) async {
    await _boot(
      tester,
      overrides: [
        authSessionProvider.overrideWithValue(DemoAuthSession(signedIn: false)),
      ],
    );
    // Session fermée : le Skip de l'onboarding sort vers la connexion.
    await _skipOnboarding(tester);
    await _shoot(tester, '16-sign-in');
  });

  testWidgets('17 digest vide : la mascotte dort', (tester) async {
    await _boot(
      tester,
      overrides: [
        lymarksRepositoryProvider.overrideWithValue(
          MockLymarksRepository(seed: const []),
        ),
      ],
    );
    await _skipOnboarding(tester);
    await tester.tap(find.text('Digest'));
    await _settle(tester);
    await _shoot(tester, '17-digest-empty');
  });

  testWidgets('18 recherche vaine : la mascotte cherche', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.text('Search'));
    await _settle(tester);
    // Le compte de démo est Pro : rien ne vient masquer le zéro résultat.
    await tester.enterText(find.byType(EditableText), 'quantum gardening');
    await _settle(tester);
    await _shoot(tester, '18-search-no-results');
  });

  testWidgets('19 lecture en echec : la mascotte hausse les epaules', (
    tester,
  ) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    // Le lymark en échec est le plus ancien du jeu de démo et la Home n'en
    // liste que six : la recherche est le chemin le plus court.
    await tester.tap(find.text('Search'));
    await _settle(tester);
    await tester.enterText(find.byType(EditableText), 'retrieval');
    await _settle(tester);
    await tester.tap(find.text('Thread on retrieval evaluation').first);
    await _settle(tester);
    await _shoot(tester, '19-detail-failed');
  });

  testWidgets('20 categorie vide : la mascotte constate le vide', (
    tester,
  ) async {
    // Le chemin d'une categorie montre ses lymarks : une categorie qu'on
    // n'a pas encore alimentee tombe sur l'etat vide. C'est la que vit la
    // pose `empty`.
    await _boot(
      tester,
      overrides: [
        lymarksRepositoryProvider.overrideWithValue(
          MockLymarksRepository(
            seed: MockData.lymarks
                .where((l) => l.categoryId != 'business')
                .toList(),
          ),
        ),
      ],
    );
    await _skipOnboarding(tester);
    final tile = find.widgetWithText(CategoryTile, 'Business');
    await tester.ensureVisible(tile);
    await _settle(tester);
    await tester.tap(tile);
    await _settle(tester);
    await _shoot(tester, '20-category-empty');
  });

  testWidgets('22 confidentialite : un texte de reference habille', (
    tester,
  ) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.bySemanticsLabel('Profile'));
    await _settle(tester);
    await tester.tap(find.text('All settings'));
    await _settle(tester);
    await tester.tap(find.text('Privacy policy'));
    await _settle(tester);
    await _shoot(tester, '22-privacy');
  });

  testWidgets('23 la carte d identite de l app', (tester) async {
    await _boot(tester);
    await _skipOnboarding(tester);
    await tester.tap(find.bySemanticsLabel('Profile'));
    await _settle(tester);
    await tester.tap(find.text('All settings'));
    await _settle(tester);
    await tester.tap(find.text('About Lymarks'));
    await _settle(tester);
    await _shoot(tester, '23-about');
  });

  testWidgets('24 fiche : un titre a rallonge reste lisible', (tester) async {
    // Certains sites servent une legende entiere comme titre. Coince dans la
    // colonne a droite de la vignette, il tombait en deux mots par ligne et
    // chassait tout le reste sous la ligne de flottaison.
    final bavard = Lymark(
      id: 'lm-long',
      url: 'https://instagram.com/p/xyz',
      domain: 'instagram.com',
      title:
          'Nicolas sur Instagram : « Commente INSPI pour recevoir les 4 '
          'sites directement en DM. Quand tu n as plus d inspiration, ton '
          'premier reflexe est surement d ouvrir Pinterest, et le probleme '
          'c est qu on finit vite par voir les memes references »',
      savedAt: DateTime.now().subtract(const Duration(days: 2)),
      bullets: const [
        'Quatre sites pour sortir de la boucle Pinterest.',
        'Le probleme des references vues partout.',
      ],
      keywords: const ['Design', 'Inspiration'],
    );

    await _boot(
      tester,
      overrides: [
        lymarksRepositoryProvider.overrideWithValue(
          MockLymarksRepository(seed: [bavard]),
        ),
      ],
    );
    await _skipOnboarding(tester);
    await tester.tap(find.byType(BookmarkCard).first);
    await _settle(tester);
    await _shoot(tester, '24-detail-long-title');
  });

  testWidgets('25 des lymarks gardes hors d atteinte', (tester) async {
    // Plan Free au-dela de sa limite : les liens sont bien arrives, on les
    // voit, on ne peut pas les lire. Le message est pose une fois au-dessus
    // du groupe, avec la mascotte endormie — ni perdus, ni en echec.
    // Peu de lisibles, pour que le groupe ferme tienne dans la capture.
    final seed = [
      ...MockData.lymarks.take(2),
      for (final l in MockData.lymarks.skip(2).take(3))
        l.copyWith(locked: true),
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
    // Le groupe ferme vit sous la liste lisible : on y descend.
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -900),
    );
    await _settle(tester);
    await _shoot(tester, '25-home-locked');
  });

  testWidgets('26 sans reseau : la Home montre le dernier passage', (
    tester,
  ) async {
    // L'app ouverte dans le metro. La bibliotheque vient du cache disque,
    // le bandeau dit pourquoi elle peut etre en retard, et tout le reste
    // fonctionne : on entre, on lit.
    await tester.binding.setSurfaceSize(_phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Sans sondage : il rappellerait le depot, qui repond, et ferait
    // repasser l'etat en ligne au milieu de la capture. Et sans carte en
    // traitement : hors-ligne le pipeline ne tourne pas, une carte
    // squelette y resterait squelette — ce n'est pas ce que cette image
    // doit montrer.
    final container = _container(
      overrides: [
        processingPollProvider.overrideWithValue(null),
        lymarksRepositoryProvider.overrideWithValue(
          MockLymarksRepository(
            seed: [
              for (final l in MockData.lymarks)
                if (l.status == LymarkStatus.ready) l,
            ],
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LymarksApp(),
      ),
    );
    await _precacheImages(tester);
    await _settle(tester);
    await _skipOnboarding(tester);

    container.read(librarySyncProvider.notifier).value = LibrarySync.offline;
    await _settle(tester);
    await _shoot(tester, '26-home-offline');
  });
}
