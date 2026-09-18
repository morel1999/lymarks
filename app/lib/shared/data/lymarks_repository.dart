import 'package:lymarks/core/api/api_client.dart';
import 'package:lymarks/core/api/api_models.dart';
import 'package:lymarks/features/capture/capture_queue.dart';
import 'package:lymarks/shared/models/lymark.dart';

/// Source des lymarks vue par les notifiers.
///
/// Deux implémentations : l'API (mode réel) et le mock (mode démo, tests,
/// rendus de référence). Les notifiers ne savent pas laquelle ils tiennent —
/// c'est ce qui permet de tester toute la logique d'état sans réseau.
abstract class LymarksRepository {
  /// Liste disponible immédiatement, avant tout appel réseau (vide pour
  /// l'API, jeu de démo pour le mock).
  List<Lymark> get initial;

  Future<List<Lymark>> fetchAll();
  Future<CaptureResult> capture(PendingCapture capture);
  Future<Lymark> updateNote(String id, String? note);
  Future<Lymark> setArchived(String id, {required bool archived});
  Future<void> delete(String id);
  Future<void> markOpened(String id);
  Future<Lymark> retry(String id);
  Future<SearchPage> search(String query, {required bool semantic});
  Future<List<Lymark>> similar(String id);
  Future<MeInfo?> me();
  Future<void> deleteAccount();
}

/// Mode réel : tout passe par l'API, rien n'est calculé localement.
class ApiLymarksRepository implements LymarksRepository {
  ApiLymarksRepository(this._api);

  final ApiClient _api;

  @override
  List<Lymark> get initial => const [];

  @override
  Future<List<Lymark>> fetchAll() async {
    // Une page suffit pour la V1 (Free = 30 lymarks, Pro rarement > 100 au
    // lancement) ; la pagination par curseur existe côté API pour la suite.
    final page = await _api.listBookmarks();
    return page.items;
  }

  @override
  Future<CaptureResult> capture(PendingCapture c) =>
      _api.createBookmark(url: c.url, note: c.note, title: c.title);

  @override
  Future<Lymark> updateNote(String id, String? note) =>
      _api.patchBookmark(id, note: note);

  @override
  Future<Lymark> setArchived(String id, {required bool archived}) =>
      _api.patchBookmark(id, archived: archived);

  @override
  Future<void> delete(String id) => _api.deleteBookmark(id);

  @override
  Future<void> markOpened(String id) => _api.markOpened(id);

  @override
  Future<Lymark> retry(String id) => _api.retryBookmark(id);

  @override
  Future<SearchPage> search(String query, {required bool semantic}) =>
      _api.search(query, semantic: semantic);

  @override
  Future<List<Lymark>> similar(String id) => _api.similar(id);

  @override
  Future<MeInfo?> me() => _api.me();

  @override
  Future<void> deleteAccount() => _api.deleteAccount();
}
