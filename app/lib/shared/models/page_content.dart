import 'package:flutter/foundation.dart';

/// Ce que le téléphone a pu lire d'une page que le serveur n'a pas pu lire
/// (anti-robot qui filtre les IP de Cloudflare : Les Échos, Eurosport,
/// Instagram). Envoyé à `POST /bookmarks/{id}/content`, le pipeline IA fait
/// le reste (résumé, catégorie, embedding).
@immutable
class PageContent {
  const PageContent({
    required this.text,
    this.title,
    this.description,
    this.lang,
    this.imageUrl,
  });

  final String? title;
  final String? description;

  /// Texte principal, borné à [maxChars] avant l'envoi.
  final String text;
  final String? lang;
  final String? imageUrl;

  /// Limite acceptée par l'API.
  static const int maxChars = 50000;

  Map<String, Object?> toJson() => {
    if (title != null) 'title': title,
    'text': text.length > maxChars ? text.substring(0, maxChars) : text,
    if (description != null) 'description': description,
    if (lang != null) 'lang': lang,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}
