import 'package:lymarks/core/api/api_models.dart';
import 'package:lymarks/features/capture/capture_queue.dart';
import 'package:lymarks/shared/data/lymarks_repository.dart';
import 'package:lymarks/shared/data/mock_data.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/models/page_content.dart';

/// Dépôt du mode démo : le jeu de données de `MockData`, en mémoire, avec les
/// mêmes règles métier que l'API (doublon par URL normalisée, retry qui
/// remplit la carte, recherche plein texte pondérée).
///
/// Sert aussi de double aux tests : tout est synchrone sous le capot, les
/// futures se résolvent en une microtâche.
class MockLymarksRepository implements LymarksRepository {
  MockLymarksRepository({
    List<Lymark>? seed,
    bool? isPro,
    DateTime Function()? clock,
  }) : _items = [...seed ?? MockData.lymarks],
       isPro = isPro ?? MockData.profile.isPro,
       _clock = clock ?? DateTime.now;

  final List<Lymark> _items;
  final DateTime Function() _clock;
  bool isPro;

  /// Journal des appels, pour les assertions de test.
  final List<String> calls = [];

  @override
  List<Lymark> get initial => List.unmodifiable(_items);

  @override
  Future<List<Lymark>> fetchAll() async {
    calls.add('fetchAll');
    return List.unmodifiable(_items);
  }

  @override
  Future<CaptureResult> capture(PendingCapture c) async {
    calls.add('capture:${c.url}');
    final key = normalizeUrl(c.url);
    final i = _items.indexWhere((l) => normalizeUrl(l.url) == key);
    if (i != -1) {
      final bumped = _items[i].copyWith(
        savedCount: _items[i].savedCount + 1,
        note: c.note ?? _items[i].note,
      );
      _items[i] = bumped;
      return CaptureResult(lymark: bumped, duplicate: true);
    }
    final created = c.toLymark();
    _items.insert(0, created);
    return CaptureResult(lymark: created, duplicate: false);
  }

  @override
  Future<Lymark> updateNote(String id, String? note) async {
    calls.add('updateNote:$id');
    return _patch(id, (l) => l.copyWith(note: note ?? ''));
  }

  @override
  Future<Lymark> setArchived(String id, {required bool archived}) async {
    calls.add('archive:$id:$archived');
    return _patch(id, (l) => l.copyWith(archived: archived));
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete:$id');
    _items.removeWhere((l) => l.id == id);
  }

  @override
  Future<void> markOpened(String id) async {
    calls.add('opened:$id');
    _patch(id, (l) => l.copyWith(lastOpenedAt: _clock()));
  }

  /// Le mock « réussit » un retry immédiatement avec un résumé de démo ; la
  /// vraie API repasse en `processing` et le pipeline remplit la carte.
  @override
  Future<Lymark> retry(String id) async {
    calls.add('retry:$id');
    return _patch(
      id,
      (l) => l.copyWith(
        status: LymarkStatus.ready,
        failureReason: null,
        bullets: const [
          'Evaluation needs a fixed question set before it needs a model.',
          'Measure retrieval and generation separately.',
          'Human review stays the tie-breaker on ambiguous answers.',
        ],
        keywords: const ['AI', 'Evaluation', 'Retrieval'],
      ),
    );
  }

  @override
  Future<Lymark> sendContent(String id, PageContent content) async {
    calls.add('sendContent:$id:${content.text.length}');
    return _patch(
      id,
      (l) => l.copyWith(
        title: content.title ?? l.title,
        status: LymarkStatus.ready,
        failureReason: null,
        bullets: const [
          'Read by the phone, summarised by the server.',
          'Sites that block robots still end up in your memory.',
          'Nothing changes for you: the card fills itself.',
        ],
        keywords: const ['Rescue', 'Content'],
        imageUrl: content.imageUrl,
      ),
    );
  }

  @override
  Future<SearchPage> search(String query, {required bool semantic}) async {
    calls.add('search:$query:${semantic ? 'semantic' : 'text'}');
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const SearchPage(items: [], semantic: false);
    final terms = q.split(RegExp(r'\s+'));

    final scored = <(Lymark, int)>[];
    for (final l in _items) {
      if (l.archived) continue;
      final haystack = [
        l.title,
        l.domain,
        l.note ?? '',
        ...l.bullets,
        ...l.keywords,
      ].join(' ').toLowerCase();

      var score = 0;
      for (final t in terms) {
        if (l.title.toLowerCase().contains(t)) score += 3;
        if (l.keywords.any((k) => k.toLowerCase().contains(t))) score += 2;
        if (haystack.contains(t)) score += 1;
      }
      if (score > 0) scored.add((l, score));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : b.$1.savedAt.compareTo(a.$1.savedAt);
    });
    return SearchPage(
      items: scored.map((e) => e.$1).toList(),
      semantic: semantic && isPro,
    );
  }

  /// Approximation locale du top-3 par cosinus (Knowledge Vault §3) :
  /// recouvrement de mots-clés, bonus si même cluster.
  @override
  Future<List<Lymark>> similar(String id) async {
    final source = _items.where((l) => l.id == id).firstOrNull;
    if (source == null) return const [];
    final keys = source.keywords.map((k) => k.toLowerCase()).toSet();
    final scored = <(Lymark, int)>[];
    for (final l in _items) {
      if (l.id == id || l.status != LymarkStatus.ready) continue;
      var score = l.keywords
          .where((k) => keys.contains(k.toLowerCase()))
          .length;
      if (l.clusterId != null && l.clusterId == source.clusterId) score += 2;
      if (score > 0) scored.add((l, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(3).map((e) => e.$1).toList();
  }

  @override
  Future<MeInfo?> me() async {
    final active = _items.where((l) => !l.archived).length;
    return MeInfo(
      id: 'demo',
      isPro: isPro,
      lymarkCount: active,
      lymarkLimit: isPro ? null : 30,
      createdAt: MockData.profile.memberSince,
      digestOptin: false,
      digestHour: 8,
      tz: 'Europe/Istanbul',
    );
  }

  @override
  Future<void> deleteAccount() async {
    calls.add('deleteAccount');
    _items.clear();
  }

  Lymark _patch(String id, Lymark Function(Lymark) fn) {
    final i = _items.indexWhere((l) => l.id == id);
    if (i == -1) throw StateError('unknown lymark $id');
    _items[i] = fn(_items[i]);
    return _items[i];
  }

  /// Normalisation minimale pour l'anti-doublon local (le serveur calcule le
  /// vrai `url_hash`).
  static String normalizeUrl(String url) {
    final u = Uri.tryParse(url.trim());
    if (u == null || u.host.isEmpty) return url.trim();
    final path = u.path.endsWith('/') && u.path.length > 1
        ? u.path.substring(0, u.path.length - 1)
        : u.path;
    return '${u.scheme.toLowerCase()}://${u.host.toLowerCase()}$path'
        '${u.hasQuery ? '?${u.query}' : ''}';
  }
}
