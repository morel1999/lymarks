import 'package:flutter_test/flutter_test.dart';
import 'package:lymarks/shared/data/mock_data.dart';

/// Cohérence du jeu de démonstration.
///
/// Les `count` des catégories et des clusters sont écrits à la main : rien
/// dans le code ne les recalcule, puisque le mode démo sert la liste telle
/// qu'elle est curée. Un compte décoratif finit à l'écran — l'en-tête d'un
/// chemin annonçait sept lymarks au-dessus d'un état vide. Ces tests rendent
/// la dérive impossible à committer.
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

    test('le compte annoncé par un cluster est son compte réel', () {
      for (final category in MockData.categories) {
        for (final cluster in category.clusters) {
          final real = MockData.lymarks
              .where((l) => !l.archived && l.clusterId == cluster.id)
              .length;
          expect(cluster.count, real, reason: cluster.id);
        }
      }
    });

    test('chaque catégorie trace un chemin, sans nœud vide', () {
      for (final category in MockData.categories) {
        expect(category.clusters, isNotEmpty, reason: category.id);
        for (final cluster in category.clusters) {
          expect(cluster.count, greaterThan(0), reason: cluster.id);
        }
      }
    });

    test('un lymark ne se range que dans un cluster de sa catégorie', () {
      final owner = {
        for (final c in MockData.categories)
          for (final cluster in c.clusters) cluster.id: c.id,
      };

      for (final lymark in MockData.lymarks) {
        if (lymark.clusterId case final id?) {
          expect(owner, contains(id), reason: lymark.id);
          expect(owner[id], lymark.categoryId, reason: lymark.id);
        }
      }
    });

    test('les identifiants sont uniques', () {
      final ids = MockData.lymarks.map((l) => l.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });
}
