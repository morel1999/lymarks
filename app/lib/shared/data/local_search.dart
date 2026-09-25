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
///
/// Elle écarte en revanche les mots vides, et exige une frontière de mot.
/// Sans cela, une phrase entière remontait toute la bibliothèque : « the
/// thing that lets a model call external systems » rendait 54 lymarks sur
/// 54, puisque « a » se trouve dans n'importe quel résumé. Ça compte plus
/// ici qu'ailleurs — c'est le mode démo et le mode hors-ligne, et on y
/// invite justement à *décrire* ce qu'on cherche.

/// Mots trop communs pour trier quoi que ce soit : ils figurent dans presque
/// chaque résumé. Les deux langues que l'app croise — l'anglais des pages
/// sauvegardées, le français de qui s'en sert. On n'y met que des mots qui
/// ne portent jamais de sens seuls : « car » et « son », ambigus en
/// français, n'y sont pas.
const Set<String> _motsVides = {
  'a', 'about', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'can', 'do',
  'does', 'for', 'from', 'how', 'i', 'in', 'into', 'is', 'it', 'me', 'more',
  'my', 'of', 'on', 'one', 'or', 'out', 'own', 'so', 'than', 'that', 'the',
  'this', 'to', 'up', 'was', 'were', 'what', 'why', 'will', 'with',
  'au', 'aux', 'avec', 'ce', 'cette', 'comme', 'dans', 'de', 'des', 'du',
  'elle', 'en', 'est', 'et', 'il', 'je', 'la', 'le', 'les', 'ma', 'mes',
  'mon', 'ne', 'ou', 'par', 'pas', 'plus', 'pour', 'que', 'qui', 'sans',
  'sont', 'sous', 'sur', 'tous', 'tout', 'un', 'une', 'vers',
};

/// Un terme cherché en début de mot : « embed » trouve « embeddings », mais
/// « bed » ne le trouve plus.
///
/// L'ancre ne vaut que devant un caractère de mot au sens ASCII, seul sens
/// que Dart lui donne. Devant « é » elle empêcherait toute correspondance :
/// un terme qui commence par un accent garde donc l'ancienne recherche par
/// sous-chaîne.
RegExp _ancre(String terme) {
  final motif = RegExp.escape(terme);
  final ancrable = RegExp('^[0-9a-z]').hasMatch(terme);
  return RegExp(ancrable ? r'\b' + motif : motif);
}

/// Lymarks correspondant à [query], du plus pertinent au plus récent.
///
/// Le titre pèse trois fois, un mot-clé deux : ce dont on se souvient d'un
/// lien, c'est son titre. Les archivés sortent, comme côté serveur.
List<Lymark> localSearch(Iterable<Lymark> items, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final tous = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tous.isEmpty) return const [];

  // Une requête qui n'est faite que de mots vides reste cherchée telle
  // quelle : taper « how to » doit rendre quelque chose plutôt que rien.
  final retenus = tous.where((t) => !_motsVides.contains(t)).toList();
  final terms = [for (final t in retenus.isEmpty ? tous : retenus) _ancre(t)];

  final scored = <(Lymark, int)>[];
  for (final l in items) {
    if (l.archived) continue;
    final titre = l.title.toLowerCase();
    final motsCles = [for (final k in l.keywords) k.toLowerCase()];
    final haystack = [
      l.title,
      l.domain,
      l.note ?? '',
      ...l.bullets,
      ...l.keywords,
    ].join(' ').toLowerCase();

    var score = 0;
    for (final t in terms) {
      if (t.hasMatch(titre)) score += 3;
      if (motsCles.any(t.hasMatch)) score += 2;
      if (t.hasMatch(haystack)) score += 1;
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
