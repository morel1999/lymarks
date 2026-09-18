import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lymarks/core/api/api_models.dart';
import 'package:lymarks/shared/models/lymark.dart';

/// Erreur renvoyée par l'API (`{error, message, details?}`) ou par le réseau.
@immutable
class ApiException implements Exception {
  const ApiException(this.status, this.code, this.message, {this.details});

  /// 0 = pas de réponse (réseau, timeout).
  final int status;
  final String code;
  final String message;
  final Object? details;

  bool get isNetwork => status == 0;
  bool get isUnauthorized => status == 401;
  bool get isLimitReached => code == 'limit_reached';
  bool get isProRequired => code == 'pro_required';

  @override
  String toString() => 'ApiException($status $code: $message)';
}

/// Fournit le JWT courant, ou null si déconnecté.
typedef TokenProvider = Future<String?> Function();

/// Client HTTP de l'API Lymarks (`api/README.md` § Routes).
///
/// Seule porte vers le réseau côté app (Coding Standards §2 : appels API
/// isolés dans `core/api/`). Aucune clé tierce ici : l'app ne parle qu'à
/// l'API Lymarks (Security §2).
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required TokenProvider token,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _token = token,
       _http = client ?? http.Client();

  final String baseUrl;
  final TokenProvider _token;
  final http.Client _http;
  final Duration timeout;

  // ── Santé ──────────────────────────────────────────────────────────────

  Future<bool> health() async {
    try {
      final json = await _send('GET', '/health', auth: false);
      return json['ok'] == true;
    } on ApiException {
      return false;
    }
  }

  // ── Lymarks ────────────────────────────────────────────────────────────

  Future<CaptureResult> createBookmark({
    required String url,
    String? note,
    String? title,
  }) async {
    final json = await _send(
      'POST',
      '/bookmarks',
      body: {'url': url, 'note': ?note, 'title': ?title},
    );
    return CaptureResult(
      lymark: lymarkFromJson(json['bookmark'] as Map<String, dynamic>),
      duplicate: json['duplicate'] == true,
    );
  }

  Future<BookmarkPage> listBookmarks({
    int limit = 100,
    DateTime? before,
    bool? archived,
    LymarkStatus? status,
  }) async {
    final json = await _send(
      'GET',
      '/bookmarks',
      query: {
        'limit': '$limit',
        'before': ?before?.toUtc().toIso8601String(),
        'archived': ?archived?.toString(),
        'status': ?status?.name,
      },
    );
    final items = (json['items'] as List<dynamic>)
        .map((e) => lymarkFromJson(e as Map<String, dynamic>))
        .toList();
    return BookmarkPage(
      items: items,
      nextCursor: json['nextCursor'] as String?,
    );
  }

  Future<Lymark> getBookmark(String id) async {
    final json = await _send('GET', '/bookmarks/$id');
    return lymarkFromJson(json['bookmark'] as Map<String, dynamic>);
  }

  Future<Lymark> patchBookmark(
    String id, {
    Object? note = _absent,
    bool? archived,
  }) async {
    final json = await _send(
      'PATCH',
      '/bookmarks/$id',
      body: {
        if (!identical(note, _absent)) 'note': note,
        'archived': ?archived,
      },
    );
    return lymarkFromJson(json['bookmark'] as Map<String, dynamic>);
  }

  Future<void> deleteBookmark(String id) => _send('DELETE', '/bookmarks/$id');

  Future<void> markOpened(String id) => _send('POST', '/bookmarks/$id/opened');

  Future<Lymark> retryBookmark(String id) async {
    final json = await _send('POST', '/bookmarks/$id/retry');
    return lymarkFromJson(json['bookmark'] as Map<String, dynamic>);
  }

  Future<List<Lymark>> similar(String id) async {
    final json = await _send('GET', '/bookmarks/$id/similar');
    return _hits(json);
  }

  // ── Recherche ──────────────────────────────────────────────────────────

  Future<SearchPage> search(
    String query, {
    bool semantic = false,
    int limit = 20,
  }) async {
    final json = await _send(
      'GET',
      '/search',
      query: {
        'q': query,
        'mode': semantic ? 'semantic' : 'text',
        'limit': '$limit',
      },
    );
    return SearchPage(
      items: _hits(json),
      semantic: json['mode'] == 'semantic',
      degraded: json['degraded'] == true,
    );
  }

  // ── Compte ─────────────────────────────────────────────────────────────

  Future<MeInfo> me() async {
    final json = await _send('GET', '/me');
    return meFromJson(json['me'] as Map<String, dynamic>);
  }

  Future<MeInfo> patchMe({
    String? tz,
    int? digestHour,
    bool? digestOptin,
  }) async {
    final json = await _send(
      'PATCH',
      '/me',
      body: {'tz': ?tz, 'digestHour': ?digestHour, 'digestOptin': ?digestOptin},
    );
    return meFromJson(json['me'] as Map<String, dynamic>);
  }

  /// Export JSON brut, tel que servi (Privacy §5).
  Future<Map<String, dynamic>> export() => _send('GET', '/me/export');

  Future<void> deleteAccount() => _send('DELETE', '/me');

  // ── Transport ──────────────────────────────────────────────────────────

  static const Object _absent = Object();

  List<Lymark> _hits(Map<String, dynamic> json) =>
      (json['items'] as List<dynamic>)
          .map(
            (e) => lymarkFromJson(
              (e as Map<String, dynamic>)['bookmark'] as Map<String, dynamic>,
            ),
          )
          .toList();

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, Object?>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{'accept': 'application/json'};
    if (auth) {
      final token = await _token();
      if (token == null) {
        throw const ApiException(401, 'unauthorized', 'Not signed in');
      }
      headers['authorization'] = 'Bearer $token';
    }
    if (body != null) headers['content-type'] = 'application/json';

    http.Response res;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      res = await http.Response.fromStream(
        await _http.send(request).timeout(timeout),
      );
    } on TimeoutException {
      throw const ApiException(0, 'timeout', 'The server took too long');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'network', e.message);
    } on IOException catch (e) {
      // SocketException, HandshakeException (TLS cassé par un filtre FAI,
      // R12), HttpException… : tout vaut « pas de réseau ».
      throw ApiException(0, 'network', e.toString());
    } on Object catch (e) {
      throw ApiException(0, 'network', e.toString());
    }

    if (res.statusCode == 204 || res.body.isEmpty) {
      if (res.statusCode >= 400) {
        throw ApiException(
          res.statusCode,
          'http_${res.statusCode}',
          res.reasonPhrase ?? '',
        );
      }
      return const {};
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(res.statusCode, 'invalid_json', 'Unreadable response');
    }
    if (res.statusCode >= 400) {
      throw ApiException(
        res.statusCode,
        json['error'] as String? ?? 'http_${res.statusCode}',
        json['message'] as String? ?? '',
        details: json['details'],
      );
    }
    return json;
  }

  void close() => _http.close();
}
