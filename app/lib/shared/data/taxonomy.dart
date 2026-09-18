import 'package:lymarks/shared/models/knowledge.dart';

/// Taxonomie fermée des catégories.
///
/// Le rangement n'est pas décidé par l'app : au résumé, l'IA côté serveur
/// choisit **une** catégorie dans cette liste (`category` du bookmark), et
/// chaque lymark va dans celle qui lui correspond le mieux. L'app ne fait que
/// regrouper ce qui lui arrive. La liste est la même des deux côtés : un
/// identifiant inconnu ici n'a pas de carte.
///
/// `other` est le repli du modèle (« rien de tout cela ») : il arrive à l'app
/// comme `Lymark.categoryId == null` et n'est jamais une carte de la Home.
///
/// Emplacements de couleur : les cinq catégories du jeu de démonstration
/// gardent les leurs (0..4, `LyPalette.accentAt`) ; la palette n'ayant que
/// cinq familles, les suivantes la reprennent en boucle dans l'ordre.
abstract final class Taxonomy {
  static const String otherId = 'other';

  /// Les dix catégories, `other` en dernier. Le `count` vaut 0 : il est
  /// calculé par `categoriesProvider` d'après la bibliothèque.
  static const List<KnowledgeCategory> all = [
    KnowledgeCategory(
      id: 'ai',
      name: 'AI',
      tagline: 'Explore your AI knowledge',
      count: 0,
      iconKey: 'ai',
      accent: 0,
    ),
    KnowledgeCategory(
      id: 'development',
      name: 'Development',
      tagline: 'Architecture, performance and tooling',
      count: 0,
      iconKey: 'development',
      accent: 2,
    ),
    KnowledgeCategory(
      id: 'design',
      name: 'Design',
      tagline: 'Systems, type and interface craft',
      count: 0,
      iconKey: 'design',
      accent: 1,
    ),
    KnowledgeCategory(
      id: 'product',
      name: 'Product',
      tagline: 'Discovery, positioning and craft',
      count: 0,
      iconKey: 'product',
      accent: 4,
    ),
    KnowledgeCategory(
      id: 'business',
      name: 'Business',
      tagline: 'Markets, pricing and strategy',
      count: 0,
      iconKey: 'business',
      accent: 3,
    ),
    KnowledgeCategory(
      id: 'science',
      name: 'Science',
      tagline: 'Research, discoveries and how things work',
      count: 0,
      iconKey: 'science',
      accent: 0,
    ),
    KnowledgeCategory(
      id: 'culture',
      name: 'Culture & Media',
      tagline: 'Films, music, books and the news',
      count: 0,
      iconKey: 'culture',
      accent: 1,
    ),
    KnowledgeCategory(
      id: 'sport',
      name: 'Sport',
      tagline: 'Games, training and the people who play',
      count: 0,
      iconKey: 'sport',
      accent: 2,
    ),
    KnowledgeCategory(
      id: 'lifestyle',
      name: 'Lifestyle',
      tagline: 'Food, travel, health and everyday life',
      count: 0,
      iconKey: 'lifestyle',
      accent: 3,
    ),
    KnowledgeCategory(
      id: otherId,
      name: 'Other',
      tagline: 'Everything that fits nowhere else',
      count: 0,
      iconKey: 'other',
      accent: 4,
    ),
  ];

  /// Les catégories qui peuvent devenir une carte : tout sauf `other`.
  static final List<KnowledgeCategory> cards = List.unmodifiable(
    all.where((c) => c.id != otherId),
  );

  static KnowledgeCategory? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Rang dans la taxonomie, pour départager deux catégories à égalité de
  /// compte sans dépendre de la stabilité du tri. Inconnu = après tout.
  static int rank(String id) {
    final i = all.indexWhere((c) => c.id == id);
    return i == -1 ? all.length : i;
  }
}
