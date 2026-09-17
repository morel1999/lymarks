import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/features/capture/capture_queue.dart';
import 'package:lymarks/features/capture/share_host.dart';
import 'package:lymarks/features/capture/shared_link.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/lymark.dart';

/// Vide la file de captures dans la bibliothèque.
///
/// Chaque capture devient un lymark en `processing` : la carte squelette se
/// remplira quand le pipeline IA aura répondu (UX Bible règle 4). Tant que
/// l'API n'est pas branchée, elle reste en traitement — ce qui suffit à
/// valider le geste de capture et son chrono, indépendamment du backend.
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
      final queue = await _ref.read(captureQueueProvider.future);
      final pending = await queue.drain();
      if (pending.isEmpty) return 0;
      _ref.read(lymarksProvider.notifier).addCaptures(pending);
      return pending.length;
    } on MissingPluginException {
      // Pas de path_provider sur cette plateforme : rien à synchroniser.
      return 0;
    } on FileSystemException catch (e) {
      debugPrint('[lymarks/capture] queue unreadable: ${e.message}');
      return 0;
    } finally {
      _running = false;
    }
  }
}

final Provider<CaptureSync> captureSyncProvider =
    Provider<CaptureSync>(CaptureSync.new);

/// Conversion d'une capture en lymark, partagée entre le notifier et les
/// tests.
extension PendingCaptureX on PendingCapture {
  Lymark toLymark() => Lymark(
        id: id,
        url: url,
        domain: SharedLink.domainOf(url),
        title: title,
        savedAt: capturedAt,
        status: LymarkStatus.processing,
        note: note,
        source: _sourceOf(url),
      );

  static LymarkSource _sourceOf(String url) {
    final host = SharedLink.domainOf(url);
    if (host == 'x.com' || host == 'twitter.com') return LymarkSource.x;
    if (host.endsWith('youtube.com') || host == 'youtu.be') {
      return LymarkSource.youtube;
    }
    if (host.endsWith('linkedin.com')) return LymarkSource.linkedin;
    return LymarkSource.web;
  }
}
