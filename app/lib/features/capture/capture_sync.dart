import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/features/capture/share_host.dart';
import 'package:lymarks/shared/data/providers.dart';

/// Vide la file de captures dans la bibliothèque.
///
/// Chaque capture est envoyée à l'API (`POST /bookmarks`) et apparaît en
/// `processing` : la carte squelette se remplira quand le pipeline IA aura
/// répondu (UX Bible règle 4). Ce qui n'a pas pu partir — réseau absent,
/// serveur en panne — reste dans la file pour le prochain passage : c'est la
/// file hors-ligne du PRD §3. Déconnecté, on ne touche à rien.
class CaptureSync {
  CaptureSync(this._ref);

  final Ref _ref;
  bool _running = false;

  /// Rend le nombre de captures intégrées. Ne lève jamais : la file est un
  /// service de confort, une plateforme sans stockage local (web, tests) ou
  /// un fichier illisible ne doivent pas empêcher l'app de s'ouvrir.
  Future<int> sync() async {
    // Un lancement et un retour au premier plan peuvent se suivre de près.
    if (_running) return 0;
    _running = true;
    try {
      if (!_ref.read(authSessionProvider).isSignedIn) return 0;
      final queue = await _ref.read(captureQueueProvider.future);
      final pending = await queue.peek();
      if (pending.isEmpty) return 0;

      final retryLater = await _ref
          .read(lymarksProvider.notifier)
          .addCaptures(pending);
      final keep = retryLater.map((c) => c.id).toSet();
      await queue.remove(
        pending.map((c) => c.id).where((id) => !keep.contains(id)),
      );
      return pending.length - retryLater.length;
    } on MissingPluginException {
      // Pas de path_provider sur cette plateforme : rien à synchroniser.
      return 0;
    } on FileSystemException catch (e) {
      debugPrint('[lymarks/capture] queue unreadable: ${e.message}');
      return 0;
    } on Object catch (e) {
      // Une erreur inattendue ne doit ni planter l'app ni vider la file.
      debugPrint('[lymarks/capture] sync failed: $e');
      return 0;
    } finally {
      _running = false;
    }
  }
}

final Provider<CaptureSync> captureSyncProvider = Provider<CaptureSync>(
  CaptureSync.new,
);
