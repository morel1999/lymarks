import 'package:flutter/foundation.dart';

/// Une catégorie de connaissance (« AI », « Design », « Development »).
///
/// Le regroupement automatique n'est pas encore spécifié — le wireframe
/// (§03 « Point à formaliser ») l'assume. Le modèle est donc volontairement
/// plat côté app : la catégorie porte son nom, son compte et ses clusters.
@immutable
class KnowledgeCategory {
  const KnowledgeCategory({
    required this.id,
    required this.name,
    required this.tagline,
    required this.count,
    required this.iconKey,
    required this.accent,
    this.clusters = const [],
  });

  final String id;
  final String name;

  /// Emplacement dans la palette (`LyPalette.accentAt`). Explicite et non
  /// déduit d'un hachage : la couleur d'une catégorie doit rester la même
  /// d'un appareil à l'autre, donc le serveur la portera.
  final int accent;

  /// Phrase courte affichée sur la carte hero (« Explore your AI knowledge »).
  final String tagline;
  final int count;

  /// Clé d'icône Lucide, résolue par `LyIcons.byKey`.
  final String iconKey;
  final List<KnowledgeCluster> clusters;
}

/// Un nœud du Category Path : un sous-ensemble cohérent d'une catégorie.
@immutable
class KnowledgeCluster {
  const KnowledgeCluster({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.count,
    required this.iconKey,
    required this.accent,
  });

  final String id;
  final String categoryId;

  /// Emplacement dans la palette, voir [KnowledgeCategory.accent].
  final int accent;
  final String name;
  final String description;
  final int count;
  final String iconKey;
}

/// Plan de l'utilisateur. La source de vérité reste le serveur : le client
/// affiche, il ne décide pas (Core Principles §3).
enum UserPlan { free, pro }

/// Profil affiché dans les réglages et le compte.
@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.plan,
    required this.lymarkCount,
    required this.noteCount,
    required this.memberSince,
  });

  final String name;
  final String email;
  final UserPlan plan;
  final int lymarkCount;
  final int noteCount;
  final DateTime memberSince;

  bool get isPro => plan == UserPlan.pro;

  /// Limite Free : 30 lymarks actifs (`09-produit/02-monetization-spec.md`).
  static const int freeLimit = 30;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters(2);
    return '${parts.first.characters(1)}${parts.last.characters(1)}';
  }
}

extension on String {
  String characters(int n) =>
      substring(0, n.clamp(0, length)).toUpperCase();
}

/// Une entrée du Daily Digest : un lymark plus la raison de son retour.
@immutable
class DigestEntry {
  const DigestEntry({
    required this.lymarkId,
    required this.reason,
  });

  final String lymarkId;

  /// Réponse à « Pourquoi est-ce que Lymarks me montre ça aujourd'hui ? »
  /// (wireframe 06 §Contenu).
  final String reason;
}
