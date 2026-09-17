import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/features/capture/capture_queue.dart';
import 'package:path_provider/path_provider.dart';

/// Ce que l'activité native nous a transmis, brut.
class SharedPayload {
  const SharedPayload({this.text, this.subject});

  final String? text;
  final String? subject;

  bool get isEmpty => (text ?? '').trim().isEmpty;
}

/// Pont vers l'activité de partage native.
///
/// Abstrait pour que la feuille de capture se teste sans Android : les tests
/// injectent un hôte factice via [shareHostProvider].
abstract class ShareHost {
  /// Contenu partagé, ou `null` si l'activité n'a pas été lancée par un
  /// partage.
  Future<SharedPayload?> shared();

  /// Ferme l'activité et rend la durée écoulée depuis son ouverture, en
  /// millisecondes, pour vérifier le budget « tap → fermeture < 2 s ».
  Future<int?> close();
}

/// Implémentation réelle : `ShareActivity.kt`, canal `app.lymarks/share`.
class MethodChannelShareHost implements ShareHost {
  static const MethodChannel _channel = MethodChannel('app.lymarks/share');

  @override
  Future<SharedPayload?> shared() async {
    final raw = await _channel.invokeMapMethod<String, dynamic>('getShared');
    if (raw == null) return null;
    return SharedPayload(
      text: raw['text'] as String?,
      subject: raw['subject'] as String?,
    );
  }

  @override
  Future<int?> close() => _channel.invokeMethod<int>('close');
}

final Provider<ShareHost> shareHostProvider =
    Provider<ShareHost>((_) => MethodChannelShareHost());

/// File de captures dans le dossier de support de l'app, partagé par les
/// deux moteurs Flutter (feuille et app) puisqu'ils vivent dans le même
/// processus Android.
final FutureProvider<CaptureQueue> captureQueueProvider =
    FutureProvider<CaptureQueue>((_) async {
  final dir = await getApplicationSupportDirectory();
  return CaptureQueue(dir);
});
