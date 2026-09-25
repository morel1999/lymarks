import 'package:lymarks/core/api/api_models.dart';
import 'package:lymarks/features/capture/capture_queue.dart';
import 'package:lymarks/shared/data/local_search.dart';
import 'package:lymarks/shared/data/lymarks_repository.dart';
import 'package:lymarks/shared/data/mock_data.dart';
import 'package:lymarks/shared/models/knowledge.dart';
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
    this.simulatesServer = false,
  }) : _items = [...seed ?? MockData.lymarks],
       isPro = isPro ?? MockData.profile.isPro,
       _clock = clock ?? DateTime.now;

  final List<Lymark> _items;
  final DateTime Function() _clock;
  bool isPro;

  /// Vrai quand ce depot doit se comporter comme le serveur : terminer le
  /// travail en cours et appliquer le plafond du plan Free.
  ///
  /// C'est le mode demo, et lui seul. Les tests et les rendus de reference le
  /// laissent faux : ils veulent justement voir l'etat `processing` fige, et
  /// choisissent leur plan eux-memes (`setPlan`). Sans ce partage, la demo
  /// montrait une carte qui chargeait indefiniment, et aucun lymark verrouille
  /// puisque `locked` n'arrive normalement que du JSON de l'API.
  final bool simulatesServer;

  /// Ce que le serveur aurait rendu : le pipeline a fini, et le plafond du
  /// plan est applique.
  ///
  /// [settle] est faux pour la liste initiale : la carte en traitement
  /// apparait alors en squelette, puis le premier `fetchAll` la remplit — ce
  /// que decrit la regle 4 de l'UX Bible, et ce que raconte la video.
  List<Lymark> _asServerWould(List<Lymark> items, {required bool settle}) {
    if (!simulatesServer) return items;
    final done = [
      for (final l in items)
        if (settle && l.status == LymarkStatus.processing)
          l.copyWith(status: LymarkStatus.ready)
        else
          l,
    ];
    if (isPro) return [for (final l in done) l.copyWith(locked: false)];
    // Le plafond Free garde ouverts les plus recents. Au-dela, la carte est
    // gardee et fermee, jamais refusee : c'est tout le propos du produit.
    final vivants = [
      for (final l in done)
        if (!l.archived) l,
    ]..sort(Lymark.byRecency);
    final ouverts = {
      for (final l in vivants.take(UserProfile.freeLimit)) l.id,
    };
    return [
      for (final l in done)
        l.copyWith(locked: !l.archived && !ouverts.contains(l.id)),
    ];
  }

  /// Journal des appels, pour les assertions de test.
  final List<String> calls = [];

  @override
  List<Lymark> get initial =>
      List.unmodifiable(_asServerWould(_items, settle: false));

  @override
  Future<List<Lymark>> fetchAll() async {
    calls.add('fetchAll');
    return List.unmodifiable(_asServerWould(_items, settle: true));
  }

  /// Le mock rend la carte **deja remplie**, la ou la vraie API la rend en
  /// `processing` et laisse le pipeline la completer.
  ///
  /// Sans cela le mode demo laissait une carte squelette que rien ne venait
  /// remplir : `processingPollProvider` vaut null hors mode reel, donc
  /// personne ne relit la liste. Or partager un lien est le geste central du
  /// produit, et la premiere chose qu'on essaie.
  ///
  /// Les puces disent ce qu'elles sont. Trois phrases plausibles mais fausses
  /// laisseraient croire que le resume est mauvais ; celles-ci disent qu'il
  /// n'y a pas de serveur dans ce build, ce qui est la verite.
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
    final created = c.toLymark().copyWith(
      status: LymarkStatus.ready,
      bullets: const [
        'Saved without leaving the page you were on.',
        'Demo mode has no server, so these three bullets are canned.',
        'Give the build an API key and the pipeline writes real ones.',
      ],
      keywords: const ['Demo', 'Capture'],
    );
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
    if (query.trim().isEmpty) {
      return const SearchPage(items: [], semantic: false);
    }
    // Même code que la recherche hors-ligne : la démo ne doit rien montrer
    // que l'app ne sache reproduire sans réseau.
    return SearchPage(
      items: localSearch(_items, query),
      semantic: semantic && isPro,
    );
  }

  @override
  Future<List<Lymark>> similar(String id) async => localSimilar(_items, id);

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
  Future<Map<String, dynamic>> export() async {
    calls.add('export');
    return {
      'exportedAt': _clock().toUtc().toIso8601String(),
      'lymarkCount': _items.length,
      'lymarks': [for (final l in _items) lymarkToJson(l)],
    };
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
