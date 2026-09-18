import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/core/api/api_client.dart';
import 'package:lymarks/core/api/api_models.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/core/config/app_config.dart';
import 'package:lymarks/features/capture/capture_queue.dart';
import 'package:lymarks/shared/data/lymarks_repository.dart';
import 'package:lymarks/shared/data/mock_data.dart';
import 'package:lymarks/shared/data/mock_repository.dart';
import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/models/lymark.dart';

/// Thème choisi dans les réglages (Light / Dark / System).
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);

/// Horloge de l'application.
///
/// Tout ce qui affiche « aujourd'hui », une salutation selon l'heure ou une
/// durée depuis une date absolue passe par ici, jamais par `DateTime.now()`
/// directement : les rendus de référence figent cette horloge pour rester
/// stables d'un jour à l'autre.
final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((_) => DateTime.now);

// ── Accès aux données ──────────────────────────────────────────────────────

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(authSessionProvider);
  final client = ApiClient(baseUrl: AppConfig.apiBaseUrl, token: auth.token);
  ref.onDispose(client.close);
  return client;
});

/// Dépôt courant : l'API en mode réel, le mock en mode démo (et dans les
/// tests, qui le surchargent pour contrôler le jeu de données).
final Provider<LymarksRepository> lymarksRepositoryProvider =
    Provider<LymarksRepository>((ref) {
      if (AppConfig.isDemo) return MockLymarksRepository();
      return ApiLymarksRepository(ref.watch(apiClientProvider));
    });

/// Intervalle de rafraîchissement tant qu'un lymark est en `processing`.
/// Null = pas de sondage (mode démo, tests : aucun timer en suspens).
final Provider<Duration?> processingPollProvider = Provider<Duration?>(
  (_) => AppConfig.isLive ? const Duration(seconds: 4) : null,
);

/// État de synchronisation de la bibliothèque, pour l'écran d'accueil.
enum LibrarySync { idle, loading, offline }

class LibrarySyncNotifier extends Notifier<LibrarySync> {
  @override
  LibrarySync build() => LibrarySync.idle;

  // Seul LymarksNotifier écrit ici.
  LibrarySync get value => state;
  set value(LibrarySync v) => state = v;
}

final librarySyncProvider = NotifierProvider<LibrarySyncNotifier, LibrarySync>(
  LibrarySyncNotifier.new,
);

/// Vrai après une capture refusée pour dépassement du plan Free : la Home
/// affiche alors le paywall, jamais la feuille de partage (UX Bible règle 11).
final captureLimitHitProvider = StateProvider<bool>((_) => false);

// ── Bibliothèque ───────────────────────────────────────────────────────────

/// Collection de lymarks, triée antéchronologiquement.
///
/// Cache local des données du dépôt : chaque action est appliquée ici
/// d'abord (l'interface réagit sans attendre), puis envoyée ; le résultat du
/// serveur remplace l'entrée locale quand il arrive. En cas d'échec réseau
/// l'entrée locale reste, le prochain [refresh] remettra les choses d'aplomb.
class LymarksNotifier extends Notifier<List<Lymark>> {
  late LymarksRepository _repo;
  Timer? _poll;
  int _pollRounds = 0;
  static const int _maxPollRounds = 30;

  /// Compteur de modifications locales : un rafraîchissement parti avant
  /// une modification ne doit pas l'écraser avec une réponse déjà périmée.
  int _mutations = 0;

  /// Les appels réseau survivent à la disposition du provider (fin de test,
  /// déconnexion) : leurs continuations ne doivent plus toucher à l'état.
  bool _disposed = false;

  /// Captures encore dans la file (envoi échoué) : affichées comme cartes en
  /// attente, et conservées à travers les rafraîchissements jusqu'à ce que le
  /// serveur les ait acceptées.
  final Set<String> _pending = {};

  @override
  List<Lymark> build() {
    _repo = ref.watch(lymarksRepositoryProvider);
    ref.onDispose(() {
      _disposed = true;
      _poll?.cancel();
    });
    // Différé : un provider ne modifie pas les autres pendant sa construction.
    unawaited(Future<void>.microtask(refresh));
    return _sorted(_repo.initial);
  }

  Lymark? byId(String id) {
    for (final l in state) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Recharge tout depuis le dépôt. Silencieux si déconnecté ou hors-ligne :
  /// la liste locale reste affichée.
  Future<void> refresh() async {
    if (!ref.read(authSessionProvider).isSignedIn) return;
    final sync = ref.read(librarySyncProvider.notifier);
    if (state.isEmpty) sync.value = LibrarySync.loading;
    try {
      final stamp = _mutations;
      final items = await _repo.fetchAll();
      if (_disposed) return;
      if (stamp != _mutations) return refresh();
      final placeholders = state.where((l) => _pending.contains(l.id));
      state = _sorted([...items, ...placeholders]);
      sync.value = LibrarySync.idle;
    } on ApiException catch (e) {
      if (_disposed) return;
      debugPrint('[lymarks/library] refresh failed: $e');
      sync.value = e.isNetwork ? LibrarySync.offline : LibrarySync.idle;
    } on Object catch (e) {
      // Quoi qu'il arrive, on ne laisse jamais l'écran sur un chargement.
      if (_disposed) return;
      debugPrint('[lymarks/library] refresh crashed: $e');
      sync.value = LibrarySync.offline;
    } finally {
      _schedulePoll();
    }
  }

  /// Envoie les captures de la file (menu de partage) et rend celles qu'il
  /// faudra retenter : échec réseau ou serveur. Un refus définitif (URL
  /// invalide, limite du plan) est consommé, jamais rejoué.
  Future<List<PendingCapture>> addCaptures(
    List<PendingCapture> captures,
  ) async {
    final retryLater = <PendingCapture>[];
    for (final c in captures) {
      try {
        final result = await _repo.capture(c);
        // La carte « en attente » d'un envoi précédent laisse la place à
        // l'entrée serveur.
        if (_pending.remove(c.id)) _drop(c.id);
        _upsert(result.lymark);
      } on ApiException catch (e) {
        if (e.isNetwork || e.status >= 500) {
          retryLater.add(c);
          // Hors-ligne : la capture reste visible, en traitement, jusqu'au
          // prochain passage (PRD §3 — l'UX ne change pas sans réseau).
          _pending.add(c.id);
          _upsert(c.toLymark());
          ref.read(librarySyncProvider.notifier).value = LibrarySync.offline;
        } else if (e.isLimitReached) {
          ref.read(captureLimitHitProvider.notifier).state = true;
        } else {
          debugPrint('[lymarks/library] capture dropped: $e');
        }
      }
    }
    _schedulePoll();
    return retryLater;
  }

  /// Suppression réversible : la vue affiche un undo de 5 s (UX Bible
  /// règle 7), d'où le retour de l'élément et de sa position. Côté serveur
  /// l'entrée est archivée tout de suite (réversible) ; la suppression réelle
  /// n'a lieu qu'à [purge], quand la fenêtre d'annulation est passée.
  ({Lymark lymark, int index})? remove(String id) {
    final index = state.indexWhere((l) => l.id == id);
    if (index == -1) return null;
    final removed = state[index];
    _mutations += 1;
    state = [...state]..removeAt(index);
    unawaited(_send(() => _repo.setArchived(id, archived: true)));
    return (lymark: removed, index: index);
  }

  void restore(Lymark lymark, int index) {
    final next = [...state];
    next.insert(index.clamp(0, next.length), lymark);
    _mutations += 1;
    state = next;
    unawaited(_send(() => _repo.setArchived(lymark.id, archived: false)));
  }

  /// Efface définitivement (embedding et événements compris — Privacy §5).
  Future<void> purge(String id) => _send(() => _repo.delete(id));

  void updateNote(String id, String? note) {
    final clean = note == null || note.trim().isEmpty ? '' : note;
    _patch(id, (l) => l.copyWith(note: clean));
    unawaited(_send(() => _repo.updateNote(id, clean.isEmpty ? null : clean)));
  }

  void markOpened(String id) {
    _patch(id, (l) => l.copyWith(lastOpenedAt: ref.read(clockProvider)()));
    unawaited(_send(() => _repo.markOpened(id)));
  }

  void archive(String id) {
    _patch(id, (l) => l.copyWith(archived: true));
    unawaited(_send(() => _repo.setArchived(id, archived: true)));
  }

  /// Relance du pipeline après un échec (PRD §3 : jamais d'échec silencieux).
  void retry(String id) {
    _patch(
      id,
      (l) => l.copyWith(status: LymarkStatus.processing, failureReason: null),
    );
    unawaited(
      _send(() async {
        _upsert(await _repo.retry(id));
        _schedulePoll();
      }),
    );
  }

  // ── Interne ────────────────────────────────────────────────────────────

  static List<Lymark> _sorted(Iterable<Lymark> items) =>
      [...items]..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  void _upsert(Lymark lymark) {
    if (_disposed) return;
    _mutations += 1;
    final i = state.indexWhere((l) => l.id == lymark.id);
    if (i == -1) {
      state = _sorted([lymark, ...state]);
    } else {
      final next = [...state];
      next[i] = lymark;
      state = next;
    }
  }

  void _drop(String id) {
    if (_disposed) return;
    _mutations += 1;
    state = [
      for (final l in state)
        if (l.id != id) l,
    ];
  }

  void _patch(String id, Lymark Function(Lymark) fn) {
    if (_disposed) return;
    _mutations += 1;
    state = [
      for (final l in state)
        if (l.id == id) fn(l) else l,
    ];
  }

  /// Exécute un appel au dépôt sans jamais propager l'erreur : l'état local
  /// a déjà changé, et l'utilisateur ne doit pas être bloqué par le réseau.
  Future<void> _send(Future<void> Function() call) async {
    try {
      await call();
    } on ApiException catch (e) {
      if (_disposed) return;
      debugPrint('[lymarks/library] write failed: $e');
      if (e.isNetwork) {
        ref.read(librarySyncProvider.notifier).value = LibrarySync.offline;
      }
    }
  }

  /// Tant qu'une carte est en traitement, on redemande la liste à intervalle
  /// régulier : le pipeline IA remplit la carte sans que l'utilisateur ne
  /// fasse rien (UX Bible règle 4). Borné, pour ne pas tourner à vide.
  void _schedulePoll() {
    if (_disposed) return;
    final interval = ref.read(processingPollProvider);
    if (interval == null) return;
    // Hors-ligne, sonder ne sert à rien (constaté sur device : 30 appels
    // pour rien). Le retour au premier plan et la prochaine capture
    // relancent un `refresh()`, qui réarme le sondage une fois en ligne.
    if (ref.read(librarySyncProvider) == LibrarySync.offline) {
      _poll?.cancel();
      return;
    }
    final busy = state.any((l) => l.status == LymarkStatus.processing);
    if (!busy) {
      _pollRounds = 0;
      _poll?.cancel();
      return;
    }
    if (_pollRounds >= _maxPollRounds) return;
    _poll?.cancel();
    _poll = Timer(interval, () {
      _pollRounds += 1;
      unawaited(refresh());
    });
  }
}

final lymarksProvider = NotifierProvider<LymarksNotifier, List<Lymark>>(
  LymarksNotifier.new,
);

final Provider<Lymark?> Function(String) lymarkByIdProvider =
    Provider.family<Lymark?, String>((ref, id) {
      for (final l in ref.watch(lymarksProvider)) {
        if (l.id == id) return l;
      }
      return null;
    });

/// Lymarks liés : top-3 par cosinus côté serveur (Knowledge Vault §3), ou
/// recouvrement de mots-clés dans le mock.
final FutureProvider<List<Lymark>> Function(String) relatedLymarksProvider =
    FutureProvider.family<List<Lymark>, String>((ref, id) {
      // Dépend de la liste pour se recalculer quand un lymark devient `ready`.
      ref.watch(lymarksProvider);
      return ref.watch(lymarksRepositoryProvider).similar(id);
    });

// ── Profil ─────────────────────────────────────────────────────────────────

/// Plan et compteurs côté serveur (`GET /me`).
final FutureProvider<MeInfo?> meProvider = FutureProvider<MeInfo?>((ref) async {
  if (!ref.watch(authSessionProvider).isSignedIn) return null;
  try {
    return await ref.watch(lymarksRepositoryProvider).me();
  } on ApiException catch (e) {
    debugPrint('[lymarks/profile] me failed: $e');
    return null;
  }
});

/// Profil affiché : identité Clerk + plan serveur + compteurs locaux.
///
/// [setPlan] n'existe que pour la démo du paywall : en production la source
/// de vérité est la table `subscriptions`, alimentée par le webhook
/// RevenueCat (Core Principles §3) — un plan « forcé » ici est écrasé au
/// prochain `GET /me`.
class ProfileNotifier extends Notifier<UserProfile> {
  UserPlan? _forcedPlan;

  @override
  UserProfile build() {
    final user = ref.watch(authSessionProvider).user;
    final me = ref.watch(meProvider).valueOrNull;
    final lymarks = ref.watch(lymarksProvider);
    final fallback = MockData.profile;

    final plan =
        _forcedPlan ??
        (me == null
            ? fallback.plan
            : (me.isPro ? UserPlan.pro : UserPlan.free));
    return UserProfile(
      name: user?.displayName ?? fallback.name,
      email: user?.email ?? fallback.email,
      plan: plan,
      lymarkCount: lymarks.where((l) => !l.archived).length,
      noteCount: lymarks.where((l) => l.hasNote).length,
      memberSince: me?.createdAt ?? user?.createdAt ?? fallback.memberSince,
    );
  }

  void setPlan(UserPlan plan) {
    _forcedPlan = plan;
    state = UserProfile(
      name: state.name,
      email: state.email,
      plan: plan,
      lymarkCount: state.lymarkCount,
      noteCount: state.noteCount,
      memberSince: state.memberSince,
    );
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

// ── Connaissances (mock tant que le serveur ne les calcule pas) ────────────

final categoriesProvider = Provider<List<KnowledgeCategory>>(
  (_) => MockData.categories,
);

final Provider<KnowledgeCategory?> Function(String) categoryByIdProvider =
    Provider.family<KnowledgeCategory?, String>(
      (ref, id) {
        for (final c in ref.watch(categoriesProvider)) {
          if (c.id == id) return c;
        }
        return null;
      },
    );

/// Lymarks d'un cluster donné.
final Provider<List<Lymark>> Function(String) clusterLymarksProvider =
    Provider.family<List<Lymark>, String>(
      (ref, clusterId) => ref
          .watch(lymarksProvider)
          .where((l) => l.clusterId == clusterId)
          .toList(),
    );

/// Entrées du Daily Digest résolues en lymarks.
final digestProvider = Provider<List<({Lymark lymark, String reason})>>((ref) {
  final all = ref.watch(lymarksProvider);
  final out = <({Lymark lymark, String reason})>[];
  for (final entry in MockData.digest) {
    final match = all.where((l) => l.id == entry.lymarkId).firstOrNull;
    if (match != null && !match.archived) {
      out.add((lymark: match, reason: entry.reason));
    }
  }
  return out;
});

// ── Recherche ──────────────────────────────────────────────────────────────

/// Requête courante. Conservée dans le provider pour que la recherche et sa
/// position soient restaurées au retour d'un détail (UX Bible règle 10).
final searchQueryProvider = StateProvider<String>((_) => '');

/// Une requête en langage naturel (plusieurs mots) part en sémantique.
/// L'utilisateur ne choisit jamais le mode (wireframe 05 §Principe).
bool looksSemantic(String q) =>
    q.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length >= 3;

@immutable
class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.loading = false,
    this.semantic = false,
    this.error,
  });

  final String query;
  final List<Lymark> results;
  final bool loading;

  /// Mode réellement servi par le dépôt.
  final bool semantic;
  final String? error;

  SearchState copyWith({
    String? query,
    List<Lymark>? results,
    bool? loading,
    bool? semantic,
    String? error,
  }) => SearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    loading: loading ?? this.loading,
    semantic: semantic ?? this.semantic,
    error: error,
  );
}

/// Exécute la recherche à chaque changement de requête. Les réponses en
/// retard (requête déjà remplacée) sont ignorées.
///
/// V1.0 Free = plein texte sur titre, note, puces et mots-clés (PRD F4). Le
/// mode sémantique (F8) n'est demandé que si le plan le permet : le serveur
/// le refuserait de toute façon (Monetization §3).
class SearchNotifier extends Notifier<SearchState> {
  int _seq = 0;

  @override
  SearchState build() {
    ref.listen(searchQueryProvider, (_, q) => unawaited(run(q)));
    return const SearchState();
  }

  Future<void> run(String query) async {
    final q = query.trim();
    final seq = ++_seq;
    if (q.isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(query: q, loading: true);
    final semantic = looksSemantic(q) && ref.read(profileProvider).isPro;
    try {
      final page = await ref
          .read(lymarksRepositoryProvider)
          .search(q, semantic: semantic);
      if (seq != _seq) return;
      state = SearchState(
        query: q,
        results: page.items,
        semantic: page.semantic,
      );
    } on ApiException catch (e) {
      if (seq != _seq) return;
      state = SearchState(query: q, error: e.message);
    }
  }
}

final searchStateProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

/// Résultats de la requête courante.
final Provider<List<Lymark>> searchResultsProvider = Provider<List<Lymark>>(
  (ref) => ref.watch(searchStateProvider).results,
);

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => MockData.recentSearches;

  void push(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    state = [
      q,
      ...state.where((s) => s.toLowerCase() != q.toLowerCase()),
    ].take(5).toList();
  }

  void clear() => state = const [];
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
      RecentSearchesNotifier.new,
    );
