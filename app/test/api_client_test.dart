import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lymarks/core/api/api_client.dart';
import 'package:lymarks/core/api/api_models.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/features/capture/capture_queue.dart';
import 'package:lymarks/shared/data/lymarks_repository.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/lymark.dart';

/// Réponse JSON telle que l'API la sert (`api/src/routes/serialize.ts`).
Map<String, Object?> _bookmarkJson({
  String id = 'b1',
  String status = 'processing',
  List<String> bullets = const [],
}) => {
  'id': id,
  'url': 'https://example.com/post',
  'domain': 'example.com',
  'title': 'Un post',
  'source': 'web',
  'status': status,
  'bullets': bullets,
  'keywords': const ['ia'],
  'lang': 'fr',
  'note': null,
  'savedAt': '2026-09-18T10:00:00.000Z',
  'updatedAt': '2026-09-18T10:00:00.000Z',
  'lastOpenedAt': null,
  'archived': false,
  'savedCount': 1,
  'failureReason': null,
};

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('ApiClient', () {
    late List<http.Request> sent;

    ApiClient client(
      http.Response Function(http.Request) handler, {
      String? token = 'jwt-123',
    }) {
      sent = [];
      return ApiClient(
        baseUrl: 'https://api.test',
        token: () async => token,
        client: MockClient((req) async {
          sent.add(req);
          return handler(req);
        }),
      );
    }

    test('POST /bookmarks : jeton, corps JSON, réponse convertie', () async {
      final api = client(
        (_) => _json({
          'bookmark': _bookmarkJson(),
          'duplicate': false,
        }, status: 201),
      );
      final result = await api.createBookmark(
        url: 'https://example.com/post',
        note: 'à lire',
        title: 'Un post',
      );

      expect(result.duplicate, isFalse);
      expect(result.lymark.id, 'b1');
      expect(result.lymark.status, LymarkStatus.processing);
      expect(result.lymark.domain, 'example.com');
      expect(result.lymark.savedAt.isUtc, isFalse);

      final req = sent.single;
      expect(req.method, 'POST');
      expect(req.url.toString(), 'https://api.test/bookmarks');
      expect(req.headers['authorization'], 'Bearer jwt-123');
      expect(jsonDecode(req.body), {
        'url': 'https://example.com/post',
        'note': 'à lire',
        'title': 'Un post',
      });
    });

    test('GET /bookmarks : paramètres et curseur', () async {
      final api = client(
        (_) => _json({
          'items': [_bookmarkJson(id: 'a'), _bookmarkJson(id: 'b')],
          'nextCursor': '2026-09-17T00:00:00.000Z',
        }),
      );
      final page = await api.listBookmarks(
        limit: 2,
        status: LymarkStatus.ready,
      );
      expect(page.items.map((l) => l.id), ['a', 'b']);
      expect(page.nextCursor, isNotNull);
      expect(sent.single.url.queryParameters, {
        'limit': '2',
        'status': 'ready',
      });
    });

    test('sans jeton : 401 local, aucun appel réseau', () async {
      final api = client((_) => _json({}), token: null);
      await expectLater(
        api.me(),
        throwsA(
          isA<ApiException>().having((e) => e.status, 'status', 401),
        ),
      );
      expect(sent, isEmpty);
    });

    test('erreur API : code et message transmis', () async {
      final api = client(
        (_) => _json({
          'error': 'limit_reached',
          'message': 'Limite atteinte',
          'details': {'limit': 30},
        }, status: 403),
      );
      await expectLater(
        api.createBookmark(url: 'https://x.test'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isLimitReached, 'limit', isTrue)
              .having((e) => e.status, 'status', 403),
        ),
      );
    });

    test('panne réseau : ApiException réseau', () async {
      final api = client((_) => throw http.ClientException('offline'));
      await expectLater(
        api.me(),
        throwsA(isA<ApiException>().having((e) => e.isNetwork, 'net', isTrue)),
      );
    });

    test(
      'TLS cassé (filtre FAI) : ApiException réseau, pas un crash',
      () async {
        final api = client(
          (_) => throw const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
        );
        await expectLater(
          api.me(),
          throwsA(
            isA<ApiException>().having((e) => e.isNetwork, 'net', isTrue),
          ),
        );
      },
    );

    test('204 sans corps : succès silencieux', () async {
      final api = client((_) => http.Response('', 204));
      await api.deleteBookmark('b1');
      expect(sent.single.method, 'DELETE');
    });

    test('GET /me : plan et limite', () async {
      final api = client(
        (_) => _json({
          'me': {
            'id': 'u1',
            'plan': 'free',
            'lymarkCount': 3,
            'lymarkLimit': 30,
            'tz': 'Europe/Paris',
            'digestHour': 8,
            'digestOptin': false,
            'createdAt': '2026-09-01T00:00:00.000Z',
          },
        }),
      );
      final me = await api.me();
      expect(me.isPro, isFalse);
      expect(me.lymarkLimit, 30);
      expect(me.lymarkCount, 3);
    });
  });

  group('LymarksNotifier avec le dépôt API', () {
    ProviderContainer containerWith(http.Response Function(http.Request) h) {
      final api = ApiClient(
        baseUrl: 'https://api.test',
        token: () async => 'jwt',
        client: MockClient((req) async => h(req)),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWithValue(DemoAuthSession()),
          lymarksRepositoryProvider.overrideWithValue(
            ApiLymarksRepository(api),
          ),
          processingPollProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    final capture = PendingCapture(
      id: 'cap-1',
      url: 'https://example.com/post',
      title: 'Un post',
      capturedAt: DateTime.utc(2026, 9, 18),
    );

    test('la liste se charge depuis GET /bookmarks', () async {
      final c = containerWith(
        (_) => _json({
          'items': [
            _bookmarkJson(id: 'ready', status: 'ready', bullets: ['Un']),
          ],
          'nextCursor': null,
        }),
      );
      expect(c.read(lymarksProvider), isEmpty);
      await c.read(lymarksProvider.notifier).refresh();
      expect(c.read(lymarksProvider).single.bullets, ['Un']);
      expect(c.read(librarySyncProvider), LibrarySync.idle);
    });

    test('une capture envoyée est consommée ; une panne la garde', () async {
      var online = true;
      final stored = <Map<String, Object?>>[];
      final c = containerWith((req) {
        if (!online) throw http.ClientException('offline');
        if (req.method == 'POST') {
          stored.add(_bookmarkJson(id: 'srv-1'));
          return _json({
            'bookmark': stored.last,
            'duplicate': false,
          }, status: 201);
        }
        return _json({'items': stored, 'nextCursor': null});
      });
      final notifier = c.read(lymarksProvider.notifier);

      expect(await notifier.addCaptures([capture]), isEmpty);
      expect(c.read(lymarksProvider).single.id, 'srv-1');

      online = false;
      final again = capture.copyWithId('cap-2');
      expect(await notifier.addCaptures([again]), [again]);
      // L'échec laisse une carte en attente à côté de l'entrée serveur.
      expect(
        c.read(lymarksProvider).map((l) => l.id),
        unorderedEquals(['cap-2', 'srv-1']),
      );
    });

    test(
      'hors-ligne : la capture reste visible en attente, puis part',
      () async {
        var online = false;
        final stored = <Map<String, Object?>>[];
        final c = containerWith((req) {
          if (!online) throw const HandshakeException('blocked');
          if (req.method == 'POST') {
            stored.add(_bookmarkJson(id: 'srv-1'));
            return _json({
              'bookmark': stored.last,
              'duplicate': false,
            }, status: 201);
          }
          return _json({'items': stored, 'nextCursor': null});
        });
        final notifier = c.read(lymarksProvider.notifier);

        expect(await notifier.addCaptures([capture]), [capture]);
        final placeholder = c.read(lymarksProvider).single;
        expect(placeholder.id, 'cap-1');
        expect(placeholder.status, LymarkStatus.processing);
        expect(c.read(librarySyncProvider), LibrarySync.offline);

        // Un rafraîchissement raté ne fait pas disparaître la carte en attente.
        await notifier.refresh();
        expect(c.read(lymarksProvider).single.id, 'cap-1');

        online = true;
        expect(await notifier.addCaptures([capture]), isEmpty);
        expect(c.read(lymarksProvider).map((l) => l.id), ['srv-1']);
        await notifier.refresh();
        expect(c.read(lymarksProvider).map((l) => l.id), ['srv-1']);
        expect(c.read(librarySyncProvider), LibrarySync.idle);
      },
    );

    test('403 limit_reached : capture abandonnée, paywall signalé', () async {
      final c = containerWith(
        (req) => req.method == 'POST'
            ? _json({'error': 'limit_reached', 'message': 'x'}, status: 403)
            : _json({'items': <Object>[], 'nextCursor': null}),
      );
      final retry = await c.read(lymarksProvider.notifier).addCaptures([
        capture,
      ]);
      expect(retry, isEmpty);
      expect(c.read(captureLimitHitProvider), isTrue);
    });

    test('hors-ligne au chargement : état offline, liste conservée', () async {
      final c = containerWith((_) => throw http.ClientException('offline'));
      await c.read(lymarksProvider.notifier).refresh();
      expect(c.read(librarySyncProvider), LibrarySync.offline);
    });
  });

  group('MeInfo', () {
    test('Pro = limite nulle', () {
      final me = meFromJson({
        'id': 'u',
        'plan': 'pro',
        'lymarkCount': 100,
        'lymarkLimit': null,
        'createdAt': '2026-01-01T00:00:00Z',
      });
      expect(me.isPro, isTrue);
      expect(me.lymarkLimit, isNull);
    });
  });
}

extension on PendingCapture {
  PendingCapture copyWithId(String newId) => PendingCapture(
    id: newId,
    url: url,
    title: title,
    capturedAt: capturedAt,
    note: note,
  );
}
