import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre une adresse hors de Lymarks.
///
/// Navigateur en surcouche d'abord (Custom Tabs sur Android,
/// SFSafariViewController sur iOS) : l'utilisateur revient d'un geste, sans
/// passer par le sélecteur d'applications. Un appareil sans navigateur
/// compatible retombe sur l'ouverture externe, et si aucun des deux ne passe,
/// on le dit — jamais un bouton muet (PRD §3 : aucun échec silencieux).
///
/// Côté Android, `AndroidManifest.xml` doit déclarer les intentions `VIEW` :
/// depuis la 11, une app ne voit que les autres applications qu'elle annonce,
/// et sans cette déclaration aucun navigateur n'est trouvé.
abstract final class LyLink {
  /// Vrai si l'adresse a pu être confiée à un navigateur.
  static Future<bool> open(
    BuildContext context,
    Uri uri, {
    String failure = "Couldn't open this link.",
  }) async {
    for (final mode in const [
      LaunchMode.inAppBrowserView,
      LaunchMode.externalApplication,
    ]) {
      try {
        if (await launchUrl(uri, mode: mode)) return true;
      } on PlatformException catch (e) {
        debugPrint('[lymarks/open] ${mode.name}: ${e.code}');
      }
    }
    if (!context.mounted) return false;
    toast(context, failure);
    return false;
  }

  /// Ouvre une adresse donnée sous forme de texte, en refusant ce qui n'en
  /// est pas une plutôt que de tenter le lancement.
  static Future<bool> openRaw(
    BuildContext context,
    String url, {
    String malformed = "This link can't be opened.",
    String failure = "Couldn't open this link.",
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      toast(context, malformed);
      return false;
    }
    return open(context, uri, failure: failure);
  }

  /// Message bref, au ras de l'écran. Public : les surfaces qui ouvrent des
  /// liens ont les mêmes retours à donner.
  static void toast(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}
