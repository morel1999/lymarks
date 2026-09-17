import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/features/capture/capture_queue.dart';
import 'package:lymarks/features/capture/capture_sync.dart';
import 'package:lymarks/shared/data/mock_data.dart';
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

/// Profil et plan.
///
/// Le plan est modifiable ici **uniquement pour la démo** : en production, la
/// source de vérité est la table `subscriptions` côté serveur, alimentée par
/// le webhook RevenueCat (Core Principles §3).
class ProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => MockData.profile;

  void setPlan(UserPlan plan) => state = UserProfile(
        name: state.name,
        email: state.email,
        plan: plan,
        lymarkCount: state.lymarkCount,
        noteCount: state.noteCount,
        memberSince: state.memberSince,
      );
}

final profileProvider =
    NotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);

/// Collection de lymarks, triée antéchronologiquement.
class LymarksNotifier extends Notifier<List<Lymark>> {
  @override
  List<Lymark> build() {
    final list = [...MockData.lymarks]
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  Lymark? byId(String id) {
    for (final l in state) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Suppression réversible : la vue affiche un undo de 5 s
  /// (UX Bible règle 7), d'où le retour de l'élément et de sa position.
  ({Lymark lymark, int index})? remove(String id) {
    final index = state.indexWhere((l) => l.id == id);
    if (index == -1) return null;
    final removed = state[index];
    state = [...state]..removeAt(index);
    return (lymark: removed, index: index);
  }

  void restore(Lymark lymark, int index) {
    final next = [...state];
    next.insert(index.clamp(0, next.length), lymark);
    state = next;
  }

  void updateNote(String id, String? note) {
    final clean = note == null || note.trim().isEmpty ? '' : note;
    _patch(id, (l) => l.copyWith(note: clean));
  }

  /// Intègre des captures venues du menu de partage, en tête de liste.
  ///
  /// Doublon d'URL (PRD §3) : pas de second lymark ; `saved_count` +1 et la
  /// note remplacée si la capture en apporte une. L'URL est comparée après
  /// normalisation légère (schéma et hôte en minuscules, sans `/` final),
  /// en attendant le `url_hash` calculé côté serveur.
  void addCaptures(List<PendingCapture> captures) {
    if (captures.isEmpty) return;
    var next = [...state];

    for (final c in captures) {
      final key = normalizeUrl(c.url);
      final i = next.indexWhere((l) => normalizeUrl(l.url) == key);
      if (i == -1) {
        next.insert(0, c.toLymark());
        continue;
      }
      final existing = next[i];
      next[i] = existing.copyWith(
        savedCount: existing.savedCount + 1,
        note: c.note ?? existing.note,
      );
    }

    next = next..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    state = next;
  }

  /// Normalisation minimale pour l'anti-doublon local.
  static String normalizeUrl(String url) {
    final u = Uri.tryParse(url.trim());
    if (u == null || u.host.isEmpty) return url.trim();
    final path = u.path.endsWith('/') && u.path.length > 1
        ? u.path.substring(0, u.path.length - 1)
        : u.path;
    return '${u.scheme.toLowerCase()}://${u.host.toLowerCase()}$path'
        '${u.hasQuery ? '?${u.query}' : ''}';
  }

  void markOpened(String id) =>
      _patch(id, (l) => l.copyWith(lastOpenedAt: DateTime.now()));

  void archive(String id) => _patch(id, (l) => l.copyWith(archived: true));

  /// Relance du pipeline après un échec (PRD §3 : jamais d'échec silencieux).
  void retry(String id) {
    _patch(id, (l) => l.copyWith(status: LymarkStatus.processing));
    Future<void>.delayed(const Duration(seconds: 3), () {
      _patch(
        id,
        (l) => l.copyWith(
          status: LymarkStatus.ready,
          bullets: const [
            'Evaluation needs a fixed question set before it needs a model.',
            'Measure retrieval and generation separately.',
            'Human review stays the tie-breaker on ambiguous answers.',
          ],
          keywords: const ['AI', 'Evaluation', 'Retrieval'],
        ),
      );
    });
  }

  void _patch(String id, Lymark Function(Lymark) fn) {
    state = [
      for (final l in state)
        if (l.id == id) fn(l) else l,
    ];
  }
}

final lymarksProvider =
    NotifierProvider<LymarksNotifier, List<Lymark>>(LymarksNotifier.new);

final Provider<Lymark?> Function(String) lymarkByIdProvider =
    Provider.family<Lymark?, String>((ref, id) {
  for (final l in ref.watch(lymarksProvider)) {
    if (l.id == id) return l;
  }
  return null;
});

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

/// Lymarks liés : approximation locale du top-3 par cosinus (Knowledge Vault
/// §3). Ici, recouvrement de mots-clés — le serveur fera le vrai calcul.
final Provider<List<Lymark>> Function(String) relatedLymarksProvider =
    Provider.family<List<Lymark>, String>(
  (ref, id) {
    final all = ref.watch(lymarksProvider);
    final source = all.where((l) => l.id == id).firstOrNull;
    if (source == null) return const [];
    final keys = source.keywords.map((k) => k.toLowerCase()).toSet();

    final scored = <(Lymark, int)>[];
    for (final l in all) {
      if (l.id == id || l.status != LymarkStatus.ready) continue;
      var score = l.keywords
          .where((k) => keys.contains(k.toLowerCase()))
          .length;
      if (l.clusterId != null && l.clusterId == source.clusterId) score += 2;
      if (score > 0) scored.add((l, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(3).map((e) => e.$1).toList();
  },
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

/// Requête courante. Conservée dans le provider pour que la recherche et sa
/// position soient restaurées au retour d'un détail (UX Bible règle 10).
final searchQueryProvider = StateProvider<String>((_) => '');

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => MockData.recentSearches;

  void push(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    state = [q, ...state.where((s) => s.toLowerCase() != q.toLowerCase())]
        .take(5)
        .toList();
  }

  void clear() => state = const [];
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
  RecentSearchesNotifier.new,
);

/// Résultats de recherche.
///
/// V1.0 Free = plein texte sur titre, note, puces et mots-clés (PRD F4).
/// Le mode sémantique Pro (F8) est simulé : même corpus, mais le libellé et
/// le paywall suivent le plan réel de l'utilisateur.
final searchResultsProvider = Provider<List<Lymark>>((ref) {
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (q.isEmpty) return const [];
  final terms = q.split(RegExp(r'\s+'));

  final scored = <(Lymark, int)>[];
  for (final l in ref.watch(lymarksProvider)) {
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
  return scored.map((e) => e.$1).toList();
});
