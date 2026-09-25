import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lymarks/core/api/api_client.dart';
import 'package:lymarks/core/api/api_models.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/features/capture/capture_queue.dart';
import 'package:lymarks/shared/data/library_cache.dart';
import 'package:lymarks/shared/data/local_search.dart';
import 'package:lymarks/shared/data/lymarks_repository.dart';
import 'package:lymarks/shared/data/mock_repository.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/models/page_content.dart';

/// Mode hors-ligne.
///
/// La promesse : on ouvre Lymarks dans le métro, on entre, on lit. Elle tient
/// à trois choses — la session Clerk est restaurée depuis le disque (le SDK
/// s'en charge), la bibliothèque aussi ([LibraryCache]), et la recherche se
/// replie sur l'appareil au lieu d'annoncer une panne.
void main() {
  Lymark lymark(
    String id, {
    String title = 'Une page',
    List<String> keywords = const ['ia'],
    String? category = 'science',
  }) => Lymark(
    id: id,
    url: 'https://example.com/$id',
    domain: 'example.com',
    title: title,
    savedAt: DateTime.utc(2026, 9, 20, 10),
    bullets: const ['Une puce.', 'Une autre.', 'Une troisieme.'],
    keywords: keywords,
    categoryId: category,
    note: 'ma note',
    lastOpenedAt: DateTime.utc(2026, 9, 21, 8),
    imageUrl: 'https://example.com/og.jpg',
    savedCount: 2,
  );

  /// Un compte Free au plafond : le cas où se tromper de plan se voit.
  final me = MeInfo(
    id: 'user_1',
    isPro: false,
    lymarkCount: 30,
    lymarkLimit: 30,
    createdAt: DateTime.utc(2026),
    digestOptin: false,
    digestHour: 8,
    tz: 'Europe/Istanbul',
  );

  Directory tempDir() {
    final dir = Directory.systemTemp.createTempSync('lymarks_cache');
    addTearDown(() {
      // Windows garde parfois une poignée sur le fichier qu'on vient
      // d'écrire : le ménage du dossier temporaire n'est pas l'objet du test.
      try {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {}
    });
    return dir;
  }

  Future<LibraryCache> cacheWith(List<Lymark> items, {MeInfo? plan}) async {
    final cache = LibraryCache(tempDir());
    await cache.write(
      userId: 'demo-user',
      lymarks: items,
      me: plan,
      syncedAt: DateTime.utc(2026, 9, 23),
    );
    return cache;
  }

  ProviderContainer containerWith({
    required LymarksRepository repo,
    LibraryCache? cache,
  }) {
    final c = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWithValue(DemoAuthSession()),
        lymarksRepositoryProvider.overrideWithValue(repo),
        processingPollProvider.overrideWithValue(null),
        if (cache != null)
          libraryCacheProvider.overrideWith((_) async => cache),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Laisse retomber la chaîne restauration → rafraîchissement.
  /// Laisse retomber la chaine restauration du cache -> appel reseau ->
  /// reecriture du cache.
  ///
  /// 40 ms suffisaient quand la machine n'avait rien d'autre a faire, et le
  /// test « le reseau revenu reprend la main sur le cache » tombait une fois
  /// sur quatre des qu'un test un peu long le precedait. Le reseau gagne des
  /// qu'il a repondu (`LymarksNotifier`, la restauration se retire si l'etat
  /// n'est plus vide) : lui laisser de la marge rend l'issue certaine, et
  /// deux dixiemes de seconde par demarrage ne coutent rien.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 200));

  /// Démarre comme l'app : le conteneur, puis la chaîne restauration du
  /// cache → appel réseau, laissée retomber.
  Future<ProviderContainer> boot({
    required LymarksRepository repo,
    LibraryCache? cache,
  }) async {
    final c = containerWith(repo: repo, cache: cache)..read(lymarksProvider);
    await settle();
    return c;
  }

  group('Aller-retour JSON', () {
    test('un lymark relu depuis le cache est identique a celui ecrit', () {
      final before = lymark('lm-1');
      final after = lymarkFromJson(
        jsonDecode(jsonEncode(lymarkToApiJson(before))) as Map<String, dynamic>,
      );

      expect(after.id, before.id);
      expect(after.url, before.url);
      expect(after.domain, before.domain);
      expect(after.title, before.title);
      expect(after.savedAt, before.savedAt.toLocal());
      expect(after.bullets, before.bullets);
      expect(after.keywords, before.keywords);
      expect(after.note, before.note);
      expect(after.categoryId, before.categoryId);
      expect(after.lastOpenedAt, before.lastOpenedAt?.toLocal());
      expect(after.status, before.status);
      expect(after.source, before.source);
      expect(after.archived, before.archived);
      expect(after.locked, before.locked);
      expect(after.savedCount, before.savedCount);
      expect(after.imageUrl, before.imageUrl);
    });

    test('un lymark verrouille le reste apres l aller-retour', () {
      final locked = lymark('lm-2').copyWith(locked: true);
      final after = lymarkFromJson(lymarkToApiJson(locked));
      expect(after.locked, isTrue);
    });

    test('le plan survit a l aller-retour', () {
      final after = meFromJson(
        jsonDecode(jsonEncode(meToJson(me))) as Map<String, dynamic>,
      );
      expect(after.isPro, isFalse);
      expect(after.lymarkLimit, 30);
      expect(after.tz, 'Europe/Istanbul');
      expect(after.createdAt, me.createdAt.toLocal());
    });
  });

  group('LibraryCache', () {
    test('ecrit puis relu, avec le plan', () async {
      final cache = await cacheWith([lymark('a'), lymark('b')], plan: me);

      final read = await cache.read(userId: 'demo-user');
      expect(read, isNotNull);
      expect(read!.lymarks.map((l) => l.id), ['a', 'b']);
      expect(read.me?.isPro, isFalse);
      expect(read.syncedAt.toUtc(), DateTime.utc(2026, 9, 23));
    });

    test('la bibliotheque d un autre compte n est jamais rendue', () async {
      final cache = LibraryCache(tempDir());
      await cache.write(
        userId: 'user_a',
        lymarks: [lymark('a')],
        syncedAt: DateTime.utc(2026, 9, 23),
      );

      expect(await cache.read(userId: 'user_b'), isNull);
      expect(await cache.read(userId: 'user_a'), isNotNull);
    });

    test('le plan connu survit a une ecriture sans plan', () async {
      final cache = await cacheWith([lymark('a')], plan: me);
      // `GET /me` a echoue ce coup-ci : la liste s ecrit quand meme.
      await cache.write(
        userId: 'demo-user',
        lymarks: [lymark('a'), lymark('b')],
        syncedAt: DateTime.utc(2026, 9, 23),
      );

      final read = await cache.read(userId: 'demo-user');
      expect(read!.lymarks, hasLength(2));
      expect(read.me?.lymarkLimit, 30);
    });

    test('un fichier illisible vaut pas de cache', () async {
      final dir = tempDir();
      File(
        '${dir.path}${Platform.pathSeparator}library.json',
      ).writeAsStringSync('{ pas du json');
      expect(await LibraryCache(dir).read(userId: 'demo-user'), isNull);
    });

    test('deux ecritures simultanees ne se marchent pas dessus', () async {
      final cache = LibraryCache(tempDir());
      final now = DateTime.utc(2026, 9, 23);
      // Un rafraichissement et une note envoyee peuvent aboutir ensemble :
      // sans mise en file, les deux passent par le meme fichier temporaire.
      await Future.wait([
        for (var i = 0; i < 5; i++)
          cache.write(
            userId: 'demo-user',
            lymarks: [for (var n = 0; n <= i; n++) lymark('l$n')],
            syncedAt: now,
          ),
      ]);

      final read = await cache.read(userId: 'demo-user');
      expect(read, isNotNull);
      expect(read!.lymarks, hasLength(5));
    });

    test('la deconnexion efface la bibliotheque du disque', () async {
      final cache = await cacheWith([lymark('a')]);
      await cache.clear();
      expect(await cache.read(userId: 'demo-user'), isNull);
    });
  });

  group('Lancement sans reseau', () {
    test('la bibliotheque du dernier passage s affiche', () async {
      final cache = await cacheWith([
        lymark('a'),
        lymark('b'),
        lymark('c'),
      ], plan: me);

      final c = await boot(repo: _OfflineRepository(), cache: cache);

      expect(c.read(lymarksProvider).map((l) => l.id), ['a', 'b', 'c']);
      expect(c.read(librarySyncProvider), LibrarySync.offline);
    });

    test('sans cache, la liste est vide et le dit', () async {
      final c = await boot(repo: _OfflineRepository());

      expect(c.read(lymarksProvider), isEmpty);
      expect(c.read(librarySyncProvider), LibrarySync.offline);
    });

    // Le seul endroit ou une carte est encore « en traitement » : le reseau
    // a manque, l'envoi sera rejoue, et entre-temps la capture reste visible
    // plutot que de disparaitre (PRD 3 : l'UX ne change pas sans reseau).
    test('hors-ligne, la capture reste visible en traitement', () async {
      final c = await boot(repo: _OfflineRepository());

      final arejouer = await c.read(lymarksProvider.notifier).addCaptures([
        PendingCapture(
          id: 'cap-1',
          url: 'https://example.org/article',
          title: 'Un article',
          capturedAt: DateTime.utc(2026, 9, 25, 10),
        ),
      ]);

      expect(arejouer.map((p) => p.id), ['cap-1']);
      final carte = c.read(lymarksProvider).firstWhere((l) => l.id == 'cap-1');
      expect(carte.status, LymarkStatus.processing);
      expect(c.read(librarySyncProvider), LibrarySync.offline);
    });

    test('le plan vient du cache, pas du jeu de demo', () async {
      final cache = await cacheWith([lymark('a')], plan: me);
      final c = containerWith(repo: _OfflineRepository(), cache: cache);

      // Sans cache, `me` rend null et le profil retombe sur la demo, qui est
      // Pro : un compte Free s afficherait Pro hors-ligne.
      expect((await c.read(meProvider.future))?.isPro, isFalse);
      expect(c.read(profileProvider).isPro, isFalse);
    });

    test('le reseau revenu reprend la main sur le cache', () async {
      final cache = await cacheWith([lymark('vieux')]);
      final c = await boot(
        repo: _FreshRepository([lymark('frais')]),
        cache: cache,
      );

      expect(c.read(lymarksProvider).map((l) => l.id), ['frais']);
      expect(c.read(librarySyncProvider), LibrarySync.idle);
      // …et le cache a suivi : le prochain lancement sans reseau montrera
      // la liste fraiche, pas l ancienne.
      final read = await cache.read(userId: 'demo-user');
      expect(read!.lymarks.map((l) => l.id), ['frais']);
    });

    test('un rafraichissement reussi ecrit ce que le serveur a dit', () async {
      final cache = await cacheWith([]);
      final c = containerWith(
        repo: MockLymarksRepository(seed: [lymark('a'), lymark('b')]),
        cache: cache,
      );

      await c.read(lymarksProvider.notifier).refresh();
      await settle();

      final read = await cache.read(userId: 'demo-user');
      expect(read!.lymarks.map((l) => l.id), unorderedEquals(['a', 'b']));
    });
  });

  group('Recherche sur l appareil', () {
    test('le titre pese plus que le reste', () {
      final items = [
        lymark('motcle', title: 'Autre chose', keywords: const ['Postgres']),
        lymark('titre', title: 'Postgres et les index', keywords: const []),
      ];
      expect(localSearch(items, 'postgres').map((l) => l.id), [
        'titre',
        'motcle',
      ]);
    });

    test('un lymark archive ne remonte pas', () {
      final items = [lymark('a', title: 'Postgres').copyWith(archived: true)];
      expect(localSearch(items, 'postgres'), isEmpty);
    });

    // On invite l'utilisateur a *decrire* ce qu'il cherche — c'est la promesse
    // du produit. Une phrase entiere ramenait alors toute la bibliotheque,
    // puisque « a » ou « to » se trouvent dans n'importe quel resume.
    test('les mots vides ne ramenent pas toute la bibliotheque', () {
      final items = [
        lymark('vise', title: 'Postgres et les index'),
        lymark('autre', title: 'Autre chose'),
      ];
      final hits = localSearch(
        items,
        'a way to get postgres in my own project',
      );
      expect(hits.map((l) => l.id), ['vise']);
    });

    test('un terme est cherche en debut de mot', () {
      final items = [lymark('a', title: 'What embeddings really encode')];
      expect(localSearch(items, 'embed').map((l) => l.id), ['a']);
      expect(localSearch(items, 'bed'), isEmpty);
    });

    test('hors-ligne, la recherche se fait sur ce qui est deja la', () async {
      final cache = await cacheWith([
        lymark('a', title: 'Postgres et les index'),
        lymark('b', title: 'Autre sujet'),
      ]);

      final c = await boot(repo: _OfflineRepository(), cache: cache);

      await c.read(searchStateProvider.notifier).run('postgres');
      final state = c.read(searchStateProvider);

      expect(state.offline, isTrue);
      expect(state.error, isNull);
      expect(state.results.map((l) => l.id), ['a']);
    });

    test('une panne serveur reste une panne, pas un repli', () async {
      final c = await boot(repo: _BrokenRepository());

      await c.read(searchStateProvider.notifier).run('postgres');
      final state = c.read(searchStateProvider);

      expect(state.offline, isFalse);
      expect(state.error, isNotNull);
    });
  });

  group('Voisinage', () {
    test('hors-ligne, il se calcule sur les mots-cles deja generes', () async {
      final cache = await cacheWith([
        lymark('source', keywords: const ['RAG', 'Postgres']),
        lymark('voisin', keywords: const ['Postgres']),
        lymark('etranger', keywords: const ['Design'], category: 'design'),
      ]);

      final c = await boot(repo: _OfflineRepository(), cache: cache);

      final related = await c.read(relatedLymarksProvider('source').future);
      expect(related.map((l) => l.id), ['voisin']);
    });
  });
}

/// Dépôt d'un téléphone sans réseau : tout échoue en `status 0`.
class _OfflineRepository implements LymarksRepository {
  static const _offline = ApiException(0, 'network', 'No connection');

  @override
  List<Lymark> get initial => const [];

  @override
  Future<List<Lymark>> fetchAll() async => throw _offline;

  @override
  Future<CaptureResult> capture(PendingCapture c) async => throw _offline;

  @override
  Future<Lymark> updateNote(String id, String? note) async => throw _offline;

  @override
  Future<Lymark> setArchived(String id, {required bool archived}) async =>
      throw _offline;

  @override
  Future<void> delete(String id) async => throw _offline;

  @override
  Future<void> markOpened(String id) async => throw _offline;

  @override
  Future<Lymark> retry(String id) async => throw _offline;

  @override
  Future<Lymark> sendContent(String id, PageContent content) async =>
      throw _offline;

  @override
  Future<SearchPage> search(String q, {required bool semantic}) async =>
      throw _offline;

  @override
  Future<List<Lymark>> similar(String id) async => throw _offline;

  @override
  Future<MeInfo?> me() async => throw _offline;

  @override
  Future<void> deleteAccount() async => throw _offline;

  @override
  Future<Map<String, dynamic>> export() async => throw _offline;
}

/// Dépôt en ligne à l'`initial` vide, comme celui de l'API : la première
/// liste ne peut venir que du réseau — ou du cache.
class _FreshRepository extends _OfflineRepository {
  _FreshRepository(this.items);

  final List<Lymark> items;

  @override
  Future<List<Lymark>> fetchAll() async => items;

  @override
  Future<MeInfo?> me() async => null;
}

/// Serveur joignable mais en panne : surtout pas un repli local, sinon on
/// masquerait une vraie erreur derrière des résultats partiels.
class _BrokenRepository extends _OfflineRepository {
  static const _boom = ApiException(500, 'server_error', 'Boom');

  @override
  Future<List<Lymark>> fetchAll() async => throw _boom;

  @override
  Future<SearchPage> search(String q, {required bool semantic}) async =>
      throw _boom;

  @override
  Future<MeInfo?> me() async => throw _boom;
}
