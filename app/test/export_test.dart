import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lymarks/core/api/api_models.dart';
import 'package:lymarks/shared/data/mock_data.dart';
import 'package:lymarks/shared/data/mock_repository.dart';
import 'package:lymarks/shared/models/lymark.dart';

/// Portabilité (RGPD art. 20, Privacy Spec §5).
///
/// L'export est une promesse écrite dans la page Confidentialité : « vos
/// liens, notes, résumés, mots-clés et dates ». Ces tests vérifient que le
/// fichier la tient.
void main() {
  group('Export', () {
    test('tout le compte part, rien ne manque', () async {
      final repo = MockLymarksRepository();
      final data = await repo.export();

      expect(data['lymarkCount'], MockData.lymarks.length);
      expect(data['lymarks'], hasLength(MockData.lymarks.length));
      expect(data['exportedAt'], isA<String>());
    });

    test('un lymark porte ce que la page Confidentialite annonce', () {
      final lymark = Lymark(
        id: 'lm-x',
        url: 'https://example.com/a',
        domain: 'example.com',
        title: 'Une page',
        savedAt: DateTime.utc(2026, 9, 4, 9),
        bullets: const ['Une puce.'],
        keywords: const ['Tag'],
        note: 'Pourquoi je l ai garde.',
        categoryId: 'ai',
      );

      final json = lymarkToJson(lymark);

      expect(json['url'], 'https://example.com/a');
      expect(json['title'], 'Une page');
      expect(json['note'], 'Pourquoi je l ai garde.');
      expect(json['summary'], ['Une puce.']);
      expect(json['keywords'], ['Tag']);
      expect(json['category'], 'ai');
      expect(json['savedAt'], '2026-09-04T09:00:00.000Z');
    });

    test('les champs vides ne sont pas ecrits', () {
      final json = lymarkToJson(
        Lymark(
          id: 'lm-y',
          url: 'https://example.com/b',
          domain: 'example.com',
          title: 'Sans note',
          savedAt: DateTime.utc(2026, 9, 4),
        ),
      );

      expect(json.containsKey('note'), isFalse);
      expect(json.containsKey('category'), isFalse);
      expect(json.containsKey('lastOpenedAt'), isFalse);
    });

    test('le tout est encodable en JSON', () async {
      final data = await MockLymarksRepository().export();
      expect(() => jsonEncode(data), returnsNormally);
    });
  });
}
