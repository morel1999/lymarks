import 'package:intl/intl.dart';

/// Formatage temporel du produit.
///
/// Ton du produit : concret et sobre, jamais culpabilisant (UX Bible §Ton).
/// « Saved 2 days ago », pas « il y a 47 jours que vous n'avez pas lu ».
abstract final class LyTime {
  /// « just now », « 2 days ago », « 3 weeks ago », « 2 months ago ».
  static String relative(DateTime when, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final d = ref.difference(when);

    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return _plural(d.inMinutes, 'minute');
    if (d.inHours < 24) return _plural(d.inHours, 'hour');
    if (d.inDays == 1) return 'yesterday';
    if (d.inDays < 7) return _plural(d.inDays, 'day');
    if (d.inDays < 30) return _plural(d.inDays ~/ 7, 'week');
    if (d.inDays < 365) return _plural(d.inDays ~/ 30, 'month');
    return _plural(d.inDays ~/ 365, 'year');
  }

  /// Préfixé, pour les cartes : « Saved 2 days ago ».
  static String savedAgo(DateTime when, {DateTime? now}) {
    final r = relative(when, now: now);
    return r == 'yesterday' || r == 'just now' ? 'Saved $r' : 'Saved $r';
  }

  /// « Tuesday, August 25 » — en-tête éditorial du Daily Digest.
  static String digestHeading(DateTime day) =>
      DateFormat('EEEE, MMMM d').format(day);

  /// Nombre de jours écoulés, pour l'algorithme de re-surfaçage.
  static int daysSince(DateTime when, {DateTime? now}) =>
      (now ?? DateTime.now()).difference(when).inDays;

  static String _plural(int n, String unit) =>
      n == 1 ? '1 $unit ago' : '$n ${unit}s ago';
}
