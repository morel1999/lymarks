import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lymarks/core/api/api_client.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/features/capture/page_rescue.dart';
import 'package:lymarks/shared/data/lymarks_repository.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/models/page_content.dart';

const _page = '''
<!doctype html>
<html lang="fr-FR">
<head>
  <title>Titre &amp; balise</title>
  <meta content="Titre OG" property="og:title">
  <meta property="og:description" content="Une description &eacute;crite.">
  <meta property="og:image" content="/img/cover.jpg">
  <script>var x = "<p>pas du texte</p>";</script>
</head>
<body>
  <nav><a href="/">Accueil</a> Menu</nav>
  <article>
    <h1>Un titre d&#39;article</h1>
    <p>Premier   paragraphe.</p>
    <p>Second paragraphe &mdash; avec entit&eacute;.</p>
  </article>
  <footer>Mentions légales</footer>
</body>
</html>
''';

http.Response _html(String body, {int status = 200, String? type}) =>
    http.Response(
      body,
      status,
      headers: {'content-type': type ?? 'text/html; charset=utf-8'},
    );

void main() {
  final base = Uri.parse('https://example.com/a/b');

  group('PageRescue.extract', () {
    test('titre, description, image, langue et texte de l\'article', () {
      final c = PageRescue.extract(_page, base: base)!;
      expect(c.title, 'Titre OG');
      expect(c.description, 'Une description écrite.');
      expect(c.imageUrl, 'https://example.com/img/cover.jpg');
      expect(c.lang, 'fr-FR');
      expect(c.text, contains("Un titre d'article"));
      expect(c.text, contains('Premier paragraphe.'));
      expect(c.text, contains('Second paragraphe — avec entité.'));
      expect(c.text, isNot(contains('pas du texte')));
      expect(c.text, isNot(contains('Menu')));
      expect(c.text, isNot(contains('Mentions')));
    });

    test('sans og:title : la balise title, entités décodées', () {
      final c = PageRescue.extract(
        '<html><head><title>A &amp; B</title></head>'
        '<body><main>Texte</main></body></html>',
        base: base,
      )!;
      expect(c.title, 'A & B');
      expect(c.text, 'Texte');
    });

    test('image http ou relative vers http : ignorée', () {
      final c = PageRescue.extract(
        '<html><head><meta property="og:image" content="http://x.test/i.png">'
        '</head><body>t</body></html>',
        base: base,
      )!;
      expect(c.imageUrl, isNull);
    });

    test('ni texte ni description : rien à envoyer', () {
      expect(
        PageRescue.extract(
          '<html><body><script>only()</script></body></html>',
          base: base,
        ),
        isNull,
      );
    });

    test('texte borné à la limite de l\'API', () {
      final c = PageRescue.extract(
        '<html><body>${'a' * (PageContent.maxChars + 500)}</body></html>',
        base: base,
      )!;
      expect(c.text.length, PageContent.maxChars);
    });
  });

  group('PageRescue.read', () {
    test('UA de navigateur partout, UA d\'aperçu pour Instagram', () async {
      final agents = <String, String>{};
      final client = MockClient((req) async {
        agents[req.url.host] = req.headers['user-agent']!;
        return _html(_page);
      });
      const rescue = PageRescue();
      await rescue.read(Uri.parse('https://lesechos.fr/x'), client: client);
      await rescue.read(
        Uri.parse('https://www.instagram.com/p/abc/'),
        client: client,
      );
      expect(agents['lesechos.fr'], startsWith('Mozilla/5.0'));
      expect(agents['www.instagram.com'], startsWith('facebookexternalhit'));
    });

    test('erreur réseau, statut non 200, type non HTML : null', () async {
      const rescue = PageRescue();
      final down = MockClient((_) async => throw http.ClientException('x'));
      expect(await rescue.read(base, client: down), isNull);
      final denied = MockClient((_) async => _html('nope', status: 403));
      expect(await rescue.read(base, client: denied), isNull);
      final json = MockClient(
        (_) async => _html('{"a":1}', type: 'application/json'),
      );
      expect(await rescue.read(base, client: json), isNull);
    });
  });

  group('LymarksNotifier.rescue', () {
    Map<String, Object?> blocked() => {
      'id': 'b1',
      'url': 'https://www.lesechos.fr/article',
      'domain': 'lesechos.fr',
      'title': 'Titre partagé',
      'source': 'web',
      'status': 'failed',
      'bullets': const <String>[],
      'keywords': const <String>[],
      'lang': null,
      'note': null,
      'savedAt': '2026-09-18T10:00:00.000Z',
      'updatedAt': '2026-09-18T10:00:00.000Z',
      'lastOpenedAt': null,
      'archived': false,
      'savedCount': 1,
      'failureReason': 'blocked',
      'category': 'other',
      'imageUrl': null,
    };

    ProviderContainer containerWith({
      required http.Response Function(http.Request) api,
      required PageContent? Function(Uri) reader,
    }) {
      final client = ApiClient(
        baseUrl: 'https://api.test',
        token: () async => 'jwt',
        client: MockClient((req) async => api(req)),
      );
      final c = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWithValue(DemoAuthSession()),
          lymarksRepositoryProvider.overrideWithValue(
            ApiLymarksRepository(client),
          ),
          processingPollProvider.overrideWithValue(null),
          pageRescueProvider.overrideWithValue(_FakeRescue(reader)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('page lue → contenu envoyé, carte remplie ; une fois par '
        'session', () async {
      final sent = <http.Request>[];
      var listed = blocked();
      final c = containerWith(
        api: (req) {
          if (req.method == 'POST') {
            sent.add(req);
            listed = {...blocked(), 'status': 'processing'};
            return http.Response(
              jsonEncode({'bookmark': listed}),
              202,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'items': [listed],
              'nextCursor': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        },
        reader: (_) => const PageContent(
          title: 'Titre lu',
          text: 'Texte lu sur le téléphone.',
          imageUrl: 'https://www.lesechos.fr/og.jpg',
        ),
      );
      final notifier = c.read(lymarksProvider.notifier);
      await notifier.refresh();
      // Le rafraîchissement enchaîne le repli de lui-même.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(sent, hasLength(1));
      expect(sent.single.url.path, '/bookmarks/b1/content');
      final body = jsonDecode(sent.single.body) as Map<String, dynamic>;
      expect(body['text'], 'Texte lu sur le téléphone.');
      expect(body['title'], 'Titre lu');
      expect(body['imageUrl'], 'https://www.lesechos.fr/og.jpg');
      expect(c.read(lymarksProvider).single.status, LymarkStatus.processing);

      // Déjà tentée : pas de second envoi sans demande explicite.
      expect(await notifier.rescue('b1'), isFalse);
      expect(sent, hasLength(1));
    });

    test('page illisible : la carte revient en échec bloqué', () async {
      var posts = 0;
      final c = containerWith(
        api: (req) {
          if (req.method == 'POST') posts += 1;
          return http.Response(
            jsonEncode({
              'items': [blocked()],
              'nextCursor': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        },
        reader: (_) => null,
      );
      final notifier = c.read(lymarksProvider.notifier);
      await notifier.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(posts, 0);
      final card = c.read(lymarksProvider).single;
      expect(card.status, LymarkStatus.failed);
      expect(card.failureReason, 'blocked');
      // « Try again » sur une carte bloquée retente la lecture, pas le serveur.
      notifier.retry('b1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(posts, 0);
      expect(c.read(lymarksProvider).single.failureReason, 'blocked');
    });
  });
}

class _FakeRescue extends PageRescue {
  const _FakeRescue(this.reader);

  final PageContent? Function(Uri) reader;

  @override
  Future<PageContent?> read(Uri url, {http.Client? client}) async =>
      reader(url);
}
