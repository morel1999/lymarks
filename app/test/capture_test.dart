import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lymarks/features/capture/capture_queue.dart';
import 'package:lymarks/features/capture/capture_sync.dart';
import 'package:lymarks/features/capture/share_app.dart';
import 'package:lymarks/features/capture/share_host.dart';
import 'package:lymarks/features/capture/shared_link.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/lymark.dart';

/// Hôte factice : rejoue ce qu'une app Android aurait partagé, et note si la
/// feuille a demandé sa fermeture.
class _FakeHost implements ShareHost {
  _FakeHost({this.text, this.subject});

  final String? text;
  final String? subject;
  int closeCalls = 0;

  @override
  Future<SharedPayload?> shared() async =>
      text == null ? null : SharedPayload(text: text, subject: subject);

  @override
  Future<int?> close() async {
    closeCalls++;
    return 420;
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// La feuille écrit un vrai fichier : ce sont des E/S réelles, que l'horloge
/// simulée de `pump` ne fait pas avancer. Chaque `await` qui suit une E/S
/// reprend dans une microtâche de la zone simulée, qui n'est vidée que par
/// `pump`. On alterne donc attente réelle (l'E/S aboutit) et `pump` (la suite
/// s'exécute), jusqu'à ce que l'hôte ait été prié de se fermer.
Future<void> _waitForClose(WidgetTester tester, _FakeHost host) async {
  for (var i = 0; i < 100 && host.closeCalls == 0; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

/// Lecture de la file en temps réel, pour la même raison.
Future<List<PendingCapture>> _peek(WidgetTester tester, Directory dir) async {
  final result = await tester.runAsync(() => CaptureQueue(dir).peek());
  return result ?? const [];
}

void main() {
  group('SharedLink.parse — formats reels des apps (SAD M1)', () {
    test('Chrome : URL en texte, titre en sujet', () {
      final l = SharedLink.parse(
        text: 'https://react.dev/reference/rsc/server-components',
        subject: 'React Server Components',
      );
      expect(l?.url, 'https://react.dev/reference/rsc/server-components');
      expect(l?.title, 'React Server Components');
      expect(l?.domain, 'react.dev');
      expect(l?.ignoredUrlCount, 0);
    });

    test('YouTube : lien court, titre en sujet', () {
      final l = SharedLink.parse(
        text: 'https://youtu.be/dQw4w9WgXcQ',
        subject: 'Building AI Agents — full course',
      );
      expect(l?.domain, 'youtu.be');
      expect(l?.title, 'Building AI Agents — full course');
    });

    test('X : texte du post puis URL, sans sujet', () {
      final l = SharedLink.parse(
        text: 'Thread on retrieval evaluation, worth a read '
            'https://x.com/someone/status/1234567890',
      );
      expect(l?.url, 'https://x.com/someone/status/1234567890');
      expect(l?.title, 'Thread on retrieval evaluation, worth a read');
      expect(l?.domain, 'x.com');
    });

    test('www. est retiré du domaine affiché', () {
      final l = SharedLink.parse(text: 'https://www.pinecone.io/learn/rag');
      expect(l?.domain, 'pinecone.io');
    });

    test('la ponctuation collée à l URL est retirée', () {
      final l = SharedLink.parse(
        text: 'Regarde ça : https://vercel.com/blog/nextjs-15.',
      );
      expect(l?.url, 'https://vercel.com/blog/nextjs-15');
    });

    test('sujet qui recopie l URL : on retombe sur le texte, puis le domaine',
        () {
      final l = SharedLink.parse(
        text: 'https://neon.tech/docs',
        subject: 'https://neon.tech/docs',
      );
      expect(l?.title, 'neon.tech');
    });

    test('plusieurs URL : la première est gardée, les autres comptées', () {
      final l = SharedLink.parse(
        text: 'https://a.example/1 puis https://b.example/2 '
            'et https://c.example/3',
      );
      expect(l?.url, 'https://a.example/1');
      expect(l?.ignoredUrlCount, 2);
    });

    test('texte sans URL : rien à enregistrer', () {
      expect(SharedLink.parse(text: 'juste une pensée'), isNull);
      expect(SharedLink.parse(text: '   '), isNull);
      expect(SharedLink.parse(), isNull);
    });
  });

  group('CaptureQueue', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('lymarks-q-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('enqueue puis drain rend les captures et vide la file', () async {
      final q = CaptureQueue(dir);
      await q.enqueue(
        PendingCapture(
          id: 'a',
          url: 'https://a.example',
          title: 'A',
          capturedAt: DateTime.utc(2026, 9, 18, 10),
        ),
      );
      await q.enqueue(
        PendingCapture(
          id: 'b',
          url: 'https://b.example',
          title: 'B',
          note: 'pour le week-end',
          capturedAt: DateTime.utc(2026, 9, 18, 11),
        ),
      );

      final drained = await q.drain();
      expect(drained.map((c) => c.id), ['a', 'b']);
      expect(drained[1].note, 'pour le week-end');
      expect(drained[1].capturedAt, DateTime.utc(2026, 9, 18, 11));
      expect(await q.peek(), isEmpty);
    });

    test('un fichier corrompu ne bloque pas : file vide', () async {
      File('${dir.path}/capture_queue.json').writeAsStringSync('{oops');
      expect(await CaptureQueue(dir).peek(), isEmpty);
    });
  });

  group('LymarksNotifier.addCaptures', () {
    test('une capture devient un lymark processing en tête', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final before = c.read(lymarksProvider).length;

      c.read(lymarksProvider.notifier).addCaptures([
        PendingCapture(
          id: 'cap-1',
          url: 'https://example.org/article',
          title: 'Un article',
          capturedAt: DateTime.now(),
        ),
      ]);

      final list = c.read(lymarksProvider);
      expect(list.length, before + 1);
      expect(list.first.id, 'cap-1');
      expect(list.first.status, LymarkStatus.processing);
      expect(list.first.domain, 'example.org');
    });

    test('doublon d URL : saved_count +1, note remplacée, pas de doublon',
        () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(lymarksProvider.notifier);
      final existing = c.read(lymarksProvider).first;
      final before = c.read(lymarksProvider).length;

      notifier.addCaptures([
        PendingCapture(
          id: 'cap-dup',
          url: '${existing.url}/',
          title: 'peu importe',
          note: 'nouvelle note',
          capturedAt: DateTime.now(),
        ),
      ]);

      final list = c.read(lymarksProvider);
      expect(list.length, before);
      final updated = list.firstWhere((l) => l.id == existing.id);
      expect(updated.savedCount, existing.savedCount + 1);
      expect(updated.note, 'nouvelle note');
    });

    test('la source est déduite du domaine', () {
      final x = PendingCapture(
        id: 'x',
        url: 'https://x.com/a/status/1',
        title: 't',
        capturedAt: DateTime.now(),
      ).toLymark();
      final yt = PendingCapture(
        id: 'y',
        url: 'https://youtu.be/abc',
        title: 't',
        capturedAt: DateTime.now(),
      ).toLymark();
      expect(x.source, LymarkSource.x);
      expect(yt.source, LymarkSource.youtube);
    });
  });

  group('ShareSheetView', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('lymarks-share-'));
    tearDown(() => dir.deleteSync(recursive: true));

    Widget harness(_FakeHost host) => ProviderScope(
          overrides: [
            shareHostProvider.overrideWithValue(host),
            captureQueueProvider.overrideWith((_) async => CaptureQueue(dir)),
          ],
          child: const ShareApp(),
        );

    testWidgets('affiche la source et enregistre puis se ferme',
        (tester) async {
      final host = _FakeHost(
        text: 'https://huggingface.co/learn/agents-course',
        subject: 'Building AI Agents',
      );
      await tester.pumpWidget(harness(host));
      await _settle(tester);

      expect(find.text('huggingface.co'), findsOneWidget);
      expect(find.text('Building AI Agents'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'for my agent system');
      await tester.tap(find.text('Save to Lymarks'));
      await _waitForClose(tester, host);

      final saved = await _peek(tester, dir);
      expect(saved, hasLength(1));
      expect(saved.single.url, 'https://huggingface.co/learn/agents-course');
      expect(saved.single.note, 'for my agent system');
      expect(host.closeCalls, 1);
    });

    testWidgets('sans lien : message clair, fermeture sans enregistrement',
        (tester) async {
      final host = _FakeHost(text: 'juste du texte');
      await tester.pumpWidget(harness(host));
      await _settle(tester);

      expect(find.text('No link in what you shared.'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await _waitForClose(tester, host);

      expect(await _peek(tester, dir), isEmpty);
      expect(host.closeCalls, 1);
    });

    testWidgets('un tap sur le voile ferme sans enregistrer', (tester) async {
      final host = _FakeHost(text: 'https://example.org');
      await tester.pumpWidget(harness(host));
      await _settle(tester);

      await tester.tapAt(const Offset(20, 20));
      await _waitForClose(tester, host);

      expect(await _peek(tester, dir), isEmpty);
      expect(host.closeCalls, 1);
    });
  });
}
