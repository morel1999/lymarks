import 'package:lymarks/shared/models/lymark.dart';

/// Recherche et voisinage calculés sur l'appareil.
///
/// Deux appelants, une seule implémentation : le mode démo, qui n'a pas
/// d'API derrière lui, et le mode hors-ligne, qui ne peut pas l'atteindre.
/// Les deux doivent se comporter pareil — sans quoi la démo montrerait une
/// recherche que l'app ne sait pas rendre quand le réseau manque.
///
/// C'est une approximation du plein texte servi par Postgres (`fts`), pas sa
/// copie : pas de racinisation, pas de pondération par la longueur du champ.
/// Elle suffit à retrouver ce qu'on a soi-même enregistré, et ne prétend pas
/// remplacer la recherche sémantique — celle-là demande un embedding, donc
/// le réseau.

/// Lymarks correspondant à [query], du plus pertinent au plus récent.
///
/// Le titre pèse trois fois, un mot-clé deux : ce dont on se souvient d'un
/// lien, c'est son titre. Les archivés sortent, comme côté serveur.
List<Lymark> localSearch(Iterable<Lymark> items, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final terms = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (terms.isEmpty) return const [];

  final scored = <(Lymark, int)>[];
  for (final l in items) {
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
    return byScore != 0 ? byScore : Lymark.byRecency(a.$1, b.$1);
  });
  return [for (final e in scored) e.$1];
}

/// Approximation locale du top-3 par cosinus (Knowledge Vault §3) :
/// recouvrement de mots-clés, bonus si même catégorie.
///
/// Les lymarks encore en traitement n'ont pas de mots-clés : ils ne peuvent
/// ni être voisins ni en avoir.
List<Lymark> localSimilar(Iterable<Lymark> items, String id, {int take = 3}) {
  final source = items.where((l) => l.id == id).firstOrNull;
  if (source == null) return const [];
  final keys = source.keywords.map((k) => k.toLowerCase()).toSet();
  final scored = <(Lymark, int)>[];
  for (final l in items) {
    if (l.id == id || l.archived || l.status != LymarkStatus.ready) continue;
    var score = l.keywords.where((k) => keys.contains(k.toLowerCase())).length;
    if (l.categoryId != null && l.categoryId == source.categoryId) score += 2;
    if (score > 0) scored.add((l, score));
  }
  scored.sort((a, b) {
    final byScore = b.$2.compareTo(a.$2);
    return byScore != 0 ? byScore : Lymark.byRecency(a.$1, b.$1);
  });
  return [for (final e in scored.take(take)) e.$1];
}
