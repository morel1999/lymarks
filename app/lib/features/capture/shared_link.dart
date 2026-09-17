import 'package:flutter/foundation.dart';

/// Ce que le menu de partage nous a tendu, une fois compris.
///
/// Les apps ne partagent pas toutes de la même façon (SAD M1, cas limites) :
///   * Chrome : `text` = URL, `subject` = titre de la page ;
///   * YouTube : `text` = URL courte, `subject` = titre ;
///   * X : `text` = « texte du post https://x.com/… », pas de sujet ;
///   * LinkedIn : `text` = URL, parfois précédée du titre ;
///   * un partage de texte sans URL existe aussi — Lymarks le refuse, il
///     n'enregistre que des liens.
@immutable
class SharedLink {
  const SharedLink({
    required this.url,
    required this.title,
    required this.domain,
    this.ignoredUrlCount = 0,
  });

  final String url;

  /// Meilleur titre disponible : sujet du partage, sinon le texte hors URL,
  /// sinon le domaine. Jamais vide.
  final String title;
  final String domain;

  /// Nombre d'URL supplémentaires trouvées et laissées de côté. Décision
  /// V1.0 : on enregistre la première, on le dit à l'utilisateur.
  final int ignoredUrlCount;

  static final RegExp _urlPattern = RegExp(
    r'''https?://[^\s<>"'`\)\]\}]+''',
    caseSensitive: false,
  );

  /// Ponctuation qui colle souvent à la fin d'une URL dans un texte.
  static const String _trailing = '.,;:!?)]}\'"';

  /// Extrait le lien d'un partage. `null` si aucune URL n'est présente.
  static SharedLink? parse({String? text, String? subject}) {
    final body = text?.trim() ?? '';
    final urls = _urlPattern
        .allMatches(body)
        .map((m) => _trim(m.group(0)!))
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) return null;

    final url = urls.first;
    final domain = domainOf(url);
    final cleanSubject = subject?.trim() ?? '';

    // Le sujet est le meilleur titre, sauf quand une app y recopie l'URL.
    var title = cleanSubject.isNotEmpty && !_looksLikeUrl(cleanSubject)
        ? cleanSubject
        : _textWithoutUrls(body);
    if (title.isEmpty) title = domain;

    return SharedLink(
      url: url,
      title: title,
      domain: domain,
      ignoredUrlCount: urls.length - 1,
    );
  }

  /// Domaine affiché à la place de l'URL, sans `www.`.
  static String domainOf(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host.isEmpty) return url;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static String _trim(String url) {
    var end = url.length;
    while (end > 0 && _trailing.contains(url[end - 1])) {
      end--;
    }
    return url.substring(0, end);
  }

  static bool _looksLikeUrl(String s) =>
      _urlPattern.hasMatch(s) && _textWithoutUrls(s).isEmpty;

  /// Première ligne non vide du texte une fois les URL retirées.
  static String _textWithoutUrls(String s) {
    final stripped = s.replaceAll(_urlPattern, ' ');
    for (final line in stripped.split('\n')) {
      final clean = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (clean.isNotEmpty) return clean;
    }
    return '';
  }

  @override
  bool operator ==(Object other) =>
      other is SharedLink &&
      other.url == url &&
      other.title == title &&
      other.ignoredUrlCount == ignoredUrlCount;

  @override
  int get hashCode => Object.hash(url, title, ignoredUrlCount);
}
