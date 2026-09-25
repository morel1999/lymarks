import 'package:flutter_test/flutter_test.dart';
import 'package:lymarks/shared/data/mock_data.dart';

/// Cohérence du jeu de démonstration.
///
/// Les `count` des catégories sont écrits à la main : rien ne les recalcule,
/// le mode démo servant la liste telle qu'elle est curée. Un compte décoratif
/// finit à l'écran — la Home annonçait sept lymarks pour une catégorie qui
/// n'en contenait qu'un. Ces tests rendent la dérive impossible à committer.
void main() {
  group('Jeu de démonstration', () {
    test('le compte annoncé par une catégorie est son compte réel', () {
      for (final category in MockData.categories) {
        final real = MockData.lymarks
            .where((l) => !l.archived && l.categoryId == category.id)
            .length;
        expect(category.count, real, reason: category.id);
      }
    });

    test('aucune catégorie ne mène à un chemin vide', () {
      for (final category in MockData.categories) {
        expect(category.count, greaterThan(0), reason: category.id);
      }
    });

    test('un lymark ne se range que dans une catégorie de la démo', () {
      final known = MockData.categories.map((c) => c.id).toSet();

      for (final lymark in MockData.lymarks) {
        if (lymark.categoryId case final id?) {
          expect(known, contains(id), reason: lymark.id);
        }
      }
    });

    test('les identifiants sont uniques', () {
      final ids = MockData.lymarks.map((l) => l.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    // Le README promet un mode démo qui « makes no network calls at all », et
    // la vidéo de soumission le dit à voix haute. Trois lymarks portaient une
    // `imageUrl` chez images.unsplash.com ; `PreviewImage` la chargeait en
    // `Image.network` depuis la Home, donc la démo sortait sur le réseau sans
    // que personne n'ait rien touché. Les rendus de référence ne l'avaient
    // jamais montré : ils sont générés sans réseau, l'image échouait, et le
    // repli tenait l'écran.
    test('aucun lymark de la démo ne pointe vers une image distante', () {
      final distantes = [
        for (final lymark in MockData.lymarks)
          if (lymark.imageUrl != null) '${lymark.id} -> ${lymark.imageUrl}',
      ];
      expect(distantes, isEmpty);
    });
  });
}
