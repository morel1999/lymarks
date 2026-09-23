import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/core/api/api_models.dart';
import 'package:lymarks/core/config/app_config.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:path_provider/path_provider.dart';

/// Ce que l'app sait de la bibliothèque quand elle n'a pas le réseau.
@immutable
class CachedLibrary {
  const CachedLibrary({
    required this.userId,
    required this.lymarks,
    required this.syncedAt,
    this.me,
  });

  /// Identifiant Clerk du compte à qui appartient ce cache. Un téléphone
  /// change de main : on ne montre jamais la bibliothèque d'un autre.
  final String userId;
  final List<Lymark> lymarks;

  /// Plan et compteurs du dernier `GET /me` réussi.
  final MeInfo? me;

  /// Date du dernier échange réussi avec le serveur.
  final DateTime syncedAt;
}

/// Bibliothèque du dernier passage, écrite sur le disque du téléphone.
///
/// Sans elle, ouvrir Lymarks dans le métro donne une liste vide : la session
/// Clerk est restaurée, mais la bibliothèque ne vit qu'en mémoire et repart
/// de zéro à chaque lancement. Ce fichier est le seul endroit où elle
/// survit à la fermeture de l'app.
///
/// Ce n'est pas une base de données : pas d'index, pas de requêtes, pas de
/// fusion. C'est une **photographie de ce que le serveur a dit en dernier**,
/// réécrite en entier à chaque échange réussi. La lecture hors-ligne s'en
/// contente, et l'écriture reste une opération atomique unique.
///
/// Ce qu'elle ne fait pas, volontairement : elle ne garde pas les
/// modifications faites hors-ligne (une note écrite sans réseau reste en
/// mémoire et repart au prochain lancement). Ce serait une file d'écritures
/// à rejouer, avec ses conflits — un autre sujet que « lire ses lymarks sans
/// réseau ».
///
/// Écriture atomique (fichier temporaire puis renommage) comme la file de
/// captures : l'app peut être tuée pendant l'écriture, une lecture ne verra
/// jamais un fichier à moitié écrit.
class LibraryCache {
  LibraryCache(this.directory);

  final Directory directory;

  /// Version du format. Une lecture d'un format inconnu est ignorée plutôt
  /// que devinée : le prochain passage en ligne réécrit tout.
  static const int format = 1;

  File get _file => File(
    '${directory.path}${Platform.pathSeparator}library.json',
  );

  /// La bibliothèque en cache si elle appartient à [userId], sinon null.
  /// Ne lève jamais : un cache illisible vaut pas de cache.
  Future<CachedLibrary?> read({required String userId}) async {
    try {
      if (!_file.existsSync()) return null;
      final raw = await _file.readAsString();
      if (raw.trim().isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['format'] != format) return null;
      if (json['userId'] != userId) return null;
      final items = (json['lymarks'] as List<dynamic>? ?? const [])
          .map((e) => lymarkFromJson(e as Map<String, dynamic>))
          .toList();
      final me = json['me'];
      return CachedLibrary(
        userId: userId,
        lymarks: items,
        me: me == null ? null : meFromJson(me as Map<String, dynamic>),
        syncedAt:
            DateTime.tryParse(json['syncedAt'] as String? ?? '')?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } on Object catch (e) {
      // Fichier tronqué, champ manquant, format changé : on repart du
      // réseau. Rien n'est perdu, c'est un cache.
      debugPrint('[lymarks/cache] unreadable: $e');
      return null;
    }
  }

  /// Écritures en cours, mises à la queue leu leu.
  Future<void> _queue = Future<void>.value();

  /// Remplace le cache. [me] nul conserve celui déjà écrit : `GET /me` et la
  /// liste ne réussissent pas toujours ensemble, et perdre le plan connu
  /// ferait réapparaître un compte Pro en Free hors-ligne.
  ///
  /// Les appels se suivent au lieu de se chevaucher : ils partagent le même
  /// fichier temporaire, et deux écritures simultanées — une note envoyée
  /// pendant un rafraîchissement, par exemple — se marcheraient dessus.
  Future<void> write({
    required String userId,
    required List<Lymark> lymarks,
    required DateTime syncedAt,
    MeInfo? me,
  }) {
    final done = _queue.then(
      (_) => _write(
        userId: userId,
        lymarks: lymarks,
        syncedAt: syncedAt,
        me: me,
      ),
    );
    // Une écriture ratée ne doit pas empoisonner les suivantes.
    _queue = done.catchError((Object _) {});
    return done;
  }

  Future<void> _write({
    required String userId,
    required List<Lymark> lymarks,
    required DateTime syncedAt,
    MeInfo? me,
  }) async {
    try {
      final kept = me ?? (await read(userId: userId))?.me;
      if (!directory.existsSync()) await directory.create(recursive: true);
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsString(
        jsonEncode({
          'format': format,
          'userId': userId,
          'syncedAt': syncedAt.toUtc().toIso8601String(),
          'me': kept == null ? null : meToJson(kept),
          'lymarks': [for (final l in lymarks) lymarkToApiJson(l)],
        }),
        flush: true,
      );
      try {
        await tmp.rename(_file.path);
      } on FileSystemException {
        // Windows refuse de renommer par-dessus un fichier existant, là où
        // Android l'accepte et rend l'opération atomique. On garde le chemin
        // atomique là où il existe, et on retombe sur effacer-puis-renommer
        // ailleurs — c'est un cache, une fenêtre sans fichier ne coûte qu'un
        // aller-retour réseau de plus.
        if (_file.existsSync()) await _file.delete();
        await tmp.rename(_file.path);
      }
    } on FileSystemException catch (e) {
      // Disque plein, dossier verrouillé : l'app continue, sans cache.
      debugPrint('[lymarks/cache] write failed: ${e.message}');
    }
  }

  /// Efface le cache. Appelé à la déconnexion : la bibliothèque d'un compte
  /// ne reste pas sur l'appareil après son départ (Privacy §5).
  Future<void> clear() async {
    try {
      if (_file.existsSync()) await _file.delete();
    } on FileSystemException catch (e) {
      debugPrint('[lymarks/cache] clear failed: ${e.message}');
    }
  }
}

/// Cache disque de la bibliothèque, ou null quand il n'y a rien à cacher.
///
/// Null en mode démo — le jeu de données est déjà dans le binaire — et sur
/// une plateforme sans stockage local (tests, web) : `path_provider` n'y
/// répond pas. Les tests qui veulent l'exercer le surchargent avec un
/// dossier temporaire, comme pour la file de captures.
final FutureProvider<LibraryCache?> libraryCacheProvider =
    FutureProvider<LibraryCache?>((_) async {
      if (AppConfig.isDemo) return null;
      try {
        return LibraryCache(await getApplicationSupportDirectory());
      } on MissingPluginException {
        return null;
      } on Object catch (e) {
        debugPrint('[lymarks/cache] unavailable: $e');
        return null;
      }
    });
