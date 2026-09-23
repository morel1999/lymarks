import 'package:flutter/foundation.dart';
import 'package:lymarks/shared/models/lymark.dart';

/// Conversions JSON ↔ modèles. Miroir de `api/src/routes/serialize.ts` :
/// tout champ ajouté là-bas se lit ici.

Lymark lymarkFromJson(Map<String, dynamic> j) {
  return Lymark(
    id: j['id'] as String,
    url: j['url'] as String,
    domain: j['domain'] as String? ?? '',
    title: (j['title'] as String?)?.trim().isNotEmpty ?? false
        ? (j['title'] as String).trim()
        : (j['domain'] as String? ?? j['url'] as String),
    savedAt: DateTime.parse(j['savedAt'] as String).toLocal(),
    source: LymarkSource.values.byName(j['source'] as String? ?? 'web'),
    status: LymarkStatus.values.byName(j['status'] as String? ?? 'ready'),
    bullets: (j['bullets'] as List<dynamic>? ?? const []).cast<String>(),
    keywords: (j['keywords'] as List<dynamic>? ?? const []).cast<String>(),
    note: j['note'] as String?,
    lastOpenedAt: j['lastOpenedAt'] == null
        ? null
        : DateTime.parse(j['lastOpenedAt'] as String).toLocal(),
    archived: j['archived'] == true,
    locked: j['locked'] == true,
    savedCount: (j['savedCount'] as num?)?.toInt() ?? 1,
    failureReason: j['failureReason'] as String?,
    // Catégorie choisie par l'IA au résumé (taxonomie fermée côté API) ;
    // `other` ne rattache à aucune carte de la Home.
    categoryId: switch (j['category']) {
      final String c when c.isNotEmpty && c != 'other' => c,
      _ => null,
    },
    imageUrl: j['imageUrl'] as String?,
  );
}

/// Un lymark tel qu'il part dans l'export (RGPD art. 20).
///
/// Ce que l'utilisateur a mis là ou que l'IA a produit pour lui : le lien, ce
/// qu'on en a compris, sa note. Pas l'embedding, illisible et sans valeur
/// hors de notre index.
Map<String, dynamic> lymarkToJson(Lymark l) => {
  'id': l.id,
  'url': l.url,
  'domain': l.domain,
  'title': l.title,
  'savedAt': l.savedAt.toUtc().toIso8601String(),
  'source': l.source.name,
  'status': l.status.name,
  'summary': l.bullets,
  'keywords': l.keywords,
  if (l.note != null) 'note': l.note,
  if (l.categoryId != null) 'category': l.categoryId,
  if (l.lastOpenedAt != null)
    'lastOpenedAt': l.lastOpenedAt!.toUtc().toIso8601String(),
  'archived': l.archived,
  'locked': l.locked,
};

/// Résultat d'une capture : le lymark (nouveau ou existant) et s'il s'agissait
/// d'un doublon (PRD §3).
@immutable
class CaptureResult {
  const CaptureResult({required this.lymark, required this.duplicate});

  final Lymark lymark;
  final bool duplicate;
}

@immutable
class BookmarkPage {
  const BookmarkPage({required this.items, this.nextCursor});

  final List<Lymark> items;
  final String? nextCursor;
}

@immutable
class SearchPage {
  const SearchPage({
    required this.items,
    required this.semantic,
    this.degraded = false,
  });

  final List<Lymark> items;

  /// Mode réellement servi (le serveur peut retomber en texte).
  final bool semantic;
  final bool degraded;
}

/// `GET /me` : plan et compteurs, source de vérité côté serveur.
@immutable
class MeInfo {
  const MeInfo({
    required this.id,
    required this.isPro,
    required this.lymarkCount,
    required this.lymarkLimit,
    required this.createdAt,
    required this.digestOptin,
    required this.digestHour,
    required this.tz,
    this.avatar,
  });

  final String id;
  final bool isPro;
  final int lymarkCount;

  /// Null = illimité (Pro).
  final int? lymarkLimit;
  final DateTime createdAt;
  final bool digestOptin;
  final int digestHour;
  final String tz;

  /// Avatar choisi par l'utilisateur (un emoji), null = initiales.
  final String? avatar;
}

MeInfo meFromJson(Map<String, dynamic> j) => MeInfo(
  id: j['id'] as String,
  isPro: j['plan'] == 'pro',
  lymarkCount: (j['lymarkCount'] as num?)?.toInt() ?? 0,
  lymarkLimit: (j['lymarkLimit'] as num?)?.toInt(),
  createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
  digestOptin: j['digestOptin'] == true,
  digestHour: (j['digestHour'] as num?)?.toInt() ?? 8,
  tz: j['tz'] as String? ?? 'UTC',
  avatar: j['avatar'] as String?,
);
