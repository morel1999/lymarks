import 'package:flutter/foundation.dart';

/// États du pipeline d'ingestion (miroir de l'enum SQL `bookmark_status`,
/// voir `05-data/02-database-schema.md`).
enum LymarkStatus {
  /// Le pipeline IA tourne : la carte affiche un squelette animé.
  processing,

  /// Résumé et embedding disponibles.
  ready,

  /// Page partiellement accessible : métadonnées seules, résumé dégradé.
  partial,

  /// Échec après retry : l'utilisateur peut relancer.
  failed,
}

/// Origine du partage (miroir de l'enum SQL `bookmark_source`).
enum LymarkSource { x, youtube, linkedin, web }

/// Une unité de connaissance.
///
/// Champs alignés sur `05-data/01-knowledge-vault-spec.md` §1. La [note] est
/// l'intention de l'utilisateur : elle pèse dans la recherche plein texte mais
/// n'est **jamais** envoyée à un LLM (Core Principles §4).
@immutable
class Lymark {
  const Lymark({
    required this.id,
    required this.url,
    required this.domain,
    required this.title,
    required this.savedAt,
    this.source = LymarkSource.web,
    this.status = LymarkStatus.ready,
    this.bullets = const [],
    this.keywords = const [],
    this.note,
    this.categoryId,
    this.accentSlot,
    this.lastOpenedAt,
    this.archived = false,
    this.locked = false,
    this.savedCount = 1,
    this.failureReason,
    this.imageUrl,
  });

  final String id;
  final String url;

  /// Domaine affiché à la place de l'URL complète (wireframe 04 §Source).
  final String domain;
  final String title;

  /// Résumé IA : exactement 3 puces quand [status] vaut ready.
  final List<String> bullets;

  /// Mots-clés générés, qui font office de tags en V1.0.
  final List<String> keywords;

  /// Note personnelle, optionnelle.
  final String? note;

  final LymarkSource source;
  final LymarkStatus status;
  final DateTime savedAt;
  final DateTime? lastOpenedAt;
  final String? categoryId;

  /// Emplacement de couleur hérité de la catégorie (voir le champ `accent`
  /// de `KnowledgeCategory`). Nul tant que le lymark n'est rattaché à aucune
  /// catégorie : la vignette retombe alors sur son domaine.
  final int? accentSlot;
  final bool archived;

  /// Enregistré au-delà de la limite du plan Free : visible dans la liste,
  /// mais illisible tant que le compte n'est pas passé Pro. Le lien n'est
  /// jamais perdu — c'est tout l'intérêt (Monetization §4).
  final bool locked;
  final int savedCount;

  /// Code court renvoyé par l'API quand [status] vaut failed (`not_found`,
  /// `timeout`, `unsafe_url`…). Null sinon.
  final String? failureReason;

  /// Image d'aperçu de la page (`og:image`), chargée depuis le site
  /// d'origine. Null quand la page n'en expose pas (posts X, échecs).
  final String? imageUrl;

  bool get hasNote => note != null && note!.trim().isNotEmpty;

  /// Clé de repli quand aucun emplacement n'est connu.
  String get accentKey => domain;

  Lymark copyWith({
    String? title,
    String? note,
    LymarkStatus? status,
    List<String>? bullets,
    List<String>? keywords,
    DateTime? lastOpenedAt,
    bool? archived,
    bool? locked,
    int? savedCount,
    Object? failureReason = _keep,
    String? imageUrl,
  }) {
    return Lymark(
      id: id,
      url: url,
      domain: domain,
      title: title ?? this.title,
      savedAt: savedAt,
      source: source,
      status: status ?? this.status,
      bullets: bullets ?? this.bullets,
      keywords: keywords ?? this.keywords,
      note: note ?? this.note,
      categoryId: categoryId,
      accentSlot: accentSlot,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      archived: archived ?? this.archived,
      locked: locked ?? this.locked,
      savedCount: savedCount ?? this.savedCount,
      failureReason: identical(failureReason, _keep)
          ? this.failureReason
          : failureReason as String?,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static const Object _keep = Object();

  /// Du plus récent au plus ancien, l'identifiant départageant les ex æquo.
  ///
  /// Le départage n'est pas une coquetterie : `List.sort` n'est pas stable
  /// en Dart, et deux lymarks enregistrés le même jour changeaient de place
  /// d'un lancement à l'autre — un rendu de référence s'en est plaint avant
  /// qu'on comprenne pourquoi. À jeu de données égal, l'ordre affiché est
  /// désormais le même partout, toujours.
  static int byRecency(Lymark a, Lymark b) {
    final byDate = b.savedAt.compareTo(a.savedAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Lymark && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
