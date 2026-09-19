import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lymarks/shared/models/page_content.dart';

/// Lit une page que le serveur n'a pas pu lire.
///
/// Certains sites refusent les adresses IP de Cloudflare (protection
/// anti-robot : Les Échos, Eurosport, Instagram…) — la carte arrive alors en
/// échec `blocked`. Le téléphone, lui, passe : on lit la page ici, on en
/// extrait l'essentiel, et l'API fait le résumé (`POST …/{id}/content`).
/// Seule une page publique, sauvegardée par l'utilisateur, est lue ; rien
/// d'autre ne quitte le téléphone.
class PageRescue {
  const PageRescue({this.timeout = const Duration(seconds: 12)});

  final Duration timeout;

  /// Au-delà, la page est tronquée : le texte utile tient dans le début.
  static const int maxBytes = 2 * 1024 * 1024;

  static const String _chromeUa =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36';

  /// Instagram (et Threads) ne servent leurs métadonnées — image, compte —
  /// qu'aux robots d'aperçu ; à un navigateur non connecté ils renvoient une
  /// coquille vide. La légende, elle, n'est jamais servie sans connexion.
  static const String _previewUa =
      'facebookexternalhit/1.1 '
      '(+http://www.facebook.com/externalhit_uatext.php)';

  @visibleForTesting
  static String userAgentFor(Uri url) {
    final host = url.host.toLowerCase();
    const previewHosts = ['instagram.com', 'threads.net'];
    for (final h in previewHosts) {
      if (host == h || host.endsWith('.$h')) return _previewUa;
    }
    return _chromeUa;
  }

  /// Rend null dès que rien d'utile ne peut être envoyé : erreur réseau,
  /// statut non 200, contenu non HTML, page sans texte ni description.
  /// Ne lève jamais.
  Future<PageContent?> read(Uri url, {http.Client? client}) async {
    final own = client == null;
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(
            url,
            headers: {
              'user-agent': userAgentFor(url),
              'accept': 'text/html,application/xhtml+xml;q=0.9,*/*;q=0.1',
              'accept-language': 'fr,en;q=0.8',
            },
          )
          .timeout(timeout);
      if (res.statusCode != 200) {
        debugPrint('[lymarks/rescue] ${url.host}: HTTP ${res.statusCode}');
        return null;
      }
      final type = (res.headers['content-type'] ?? '').toLowerCase();
      if (!type.contains('html')) {
        debugPrint('[lymarks/rescue] ${url.host}: not html ($type)');
        return null;
      }
      final bytes = res.bodyBytes.length > maxBytes
          ? res.bodyBytes.sublist(0, maxBytes)
          : res.bodyBytes;
      // `res.body` retombe sur latin-1 sans charset déclaré : l'UTF-8 est la
      // norme du web ; on ne suit l'en-tête que s'il dit autre chose.
      final html = _isLatin1(type)
          ? latin1.decode(bytes)
          : utf8.decode(bytes, allowMalformed: true);
      final content = extract(html, base: res.request?.url ?? url);
      if (content == null) {
        debugPrint('[lymarks/rescue] ${url.host}: nothing to send');
      }
      return content;
    } on Object catch (e) {
      debugPrint('[lymarks/rescue] ${url.host}: $e');
      return null;
    } finally {
      if (own) c.close();
    }
  }

  static bool _isLatin1(String contentType) {
    final m = RegExp(r'charset=([\w-]+)').firstMatch(contentType);
    final cs = m?.group(1)?.toLowerCase();
    return cs == 'iso-8859-1' || cs == 'latin1' || cs == 'windows-1252';
  }

  /// Extraction sans DOM : titre, description, image d'aperçu, langue et
  /// texte principal (`<article>`, sinon `<main>`, sinon `<body>`).
  @visibleForTesting
  static PageContent? extract(String html, {required Uri base}) {
    final meta = _metaTags(html);
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = meta[k]?.trim();
        if (v != null && v.isNotEmpty) return _decodeEntities(v);
      }
      return null;
    }

    final title =
        pick(['og:title', 'twitter:title']) ?? _tagText(html, 'title');
    final description = pick([
      'og:description',
      'twitter:description',
      'description',
    ]);
    final imageUrl = _httpsImage(pick(['og:image', 'twitter:image']), base);
    final lang = RegExp(
      r'''<html[^>]*\blang\s*=\s*["']?([a-zA-Z]{2,3}(?:-[a-zA-Z0-9]+)?)''',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);

    var text = _mainText(html);
    final hasDescription = description != null && description.isNotEmpty;
    if (text.isEmpty && !hasDescription) {
      // Instagram (robot d'aperçu) : ni texte ni légende, mais le compte et
      // l'image — assez pour une carte partielle. Le titre fait office de
      // texte, l'API exige un contenu non vide ; une page vraiment vide
      // (titre générique, sans image) n'apporte rien.
      final worth = imageUrl != null && title != null && title != 'Instagram';
      if (!worth) return null;
      text = title;
    }
    return PageContent(
      title: title,
      description: description,
      text: text.length > PageContent.maxChars
          ? text.substring(0, PageContent.maxChars)
          : text,
      lang: lang,
      imageUrl: imageUrl,
    );
  }

  /// `property`/`name` → `content` de chaque `<meta>`, quel que soit l'ordre
  /// des attributs.
  static Map<String, String> _metaTags(String html) {
    final out = <String, String>{};
    final attr = RegExp(
      r'''([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))''',
    );
    for (final m in RegExp(r'<meta\b([^>]*)>', caseSensitive: false).allMatches(
      html,
    )) {
      String? key;
      String? content;
      for (final a in attr.allMatches(m.group(1)!)) {
        final name = a.group(1)!.toLowerCase();
        final value = a.group(2) ?? a.group(3) ?? a.group(4) ?? '';
        if (name == 'property' || name == 'name') {
          key ??= value.toLowerCase();
        } else if (name == 'content') {
          content = value;
        }
      }
      if (key != null && content != null) {
        out.putIfAbsent(key, () => content!);
      }
    }
    return out;
  }

  static String? _tagText(String html, String tag) {
    final m = RegExp(
      '<$tag[^>]*>(.*?)</$tag>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    final t = m == null ? null : _clean(m.group(1)!);
    return t == null || t.isEmpty ? null : t;
  }

  static String? _httpsImage(String? raw, Uri base) {
    if (raw == null) return null;
    final u = base.resolve(raw.trim());
    final ok = u.scheme == 'https' && u.host.isNotEmpty;
    return ok && u.toString().length <= 2048 ? u.toString() : null;
  }

  static String _mainText(String html) {
    String? region;
    for (final tag in ['article', 'main', 'body']) {
      final m = RegExp(
        '<$tag\\b[^>]*>(.*?)</$tag>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(html);
      if (m != null) {
        region = m.group(1);
        break;
      }
    }
    return _clean(region ?? html);
  }

  /// Retire le bruit (scripts, navigation…), puis toutes les balises, décode
  /// les entités et normalise les espaces.
  static String _clean(String fragment) {
    var s = fragment;
    const noise = [
      'script',
      'style',
      'noscript',
      'nav',
      'header',
      'footer',
      'aside',
      'svg',
      'iframe',
      'template',
    ];
    for (final tag in noise) {
      s = s.replaceAll(
        RegExp('<$tag\\b[^>]*>.*?</$tag>', caseSensitive: false, dotAll: true),
        ' ',
      );
    }
    s = s.replaceAll(RegExp('<!--.*?-->', dotAll: true), ' ');
    // Une balise de bloc vaut une coupure : deux paragraphes ne se collent pas.
    s = s.replaceAll(
      RegExp(
        r'</?(?:p|div|br|li|h[1-6]|tr|section|blockquote|figcaption)\b[^>]*>',
        caseSensitive: false,
      ),
      '\n',
    );
    s = s.replaceAll(RegExp('<[^>]+>'), ' ');
    s = _decodeEntities(s);
    return s
        .replaceAll(RegExp(r'[ \t\r\f\v]+'), ' ')
        .replaceAll(RegExp(r'\s*\n\s*'), '\n')
        .trim();
  }

  static const Map<String, String> _named = {
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
    'laquo': '«',
    'raquo': '»',
    'hellip': '…',
    'ndash': '–',
    'mdash': '—',
    'rsquo': '’',
    'lsquo': '‘',
    'rdquo': '”',
    'ldquo': '“',
    'eacute': 'é',
    'egrave': 'è',
    'ecirc': 'ê',
    'agrave': 'à',
    'ccedil': 'ç',
    'ocirc': 'ô',
    'ugrave': 'ù',
    'copy': '©',
  };

  static String _decodeEntities(String s) => s.replaceAllMapped(
    RegExp('&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);'),
    (m) {
      final e = m.group(1)!;
      if (e.startsWith('#')) {
        final hex = e.startsWith('#x');
        final digits = e.substring(hex ? 2 : 1);
        final code = int.tryParse(digits, radix: hex ? 16 : 10);
        return code == null || code > 0x10FFFF
            ? m.group(0)!
            : String.fromCharCode(code);
      }
      return _named[e] ?? m.group(0)!;
    },
  );
}
