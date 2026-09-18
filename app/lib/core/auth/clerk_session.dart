import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:lymarks/core/auth/auth_session.dart';

/// Session réelle, adossée au SDK Clerk (beta, version épinglée — ADR-010).
///
/// [ClerkAuthState] est déjà un [ChangeNotifier] : on relaie ses
/// notifications telles quelles, le routeur et le profil suivent.
class ClerkAuthSession extends ChangeNotifier implements AuthSession {
  ClerkAuthSession(this.state) {
    state.addListener(notifyListeners);
  }

  final ClerkAuthState state;

  /// Journal du dernier retour OAuth, affiché sur l'écran de connexion
  /// (diagnostic sur device : les traces logcat ne suffisent pas).
  final ValueNotifier<List<String>> oauthTrace = ValueNotifier(const []);

  /// Note une étape à l'écran, sans passer par logcat.
  void note(String message) {
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    oauthTrace.value = [...oauthTrace.value, '$stamp $message'];
  }

  void _trace(String message) {
    note(message);
    // Sur device, l'exécution semble s'arrêter après un `debugPrint` dans ce
    // chemin : on l'isole pour que la trace écran survive dans tous les cas.
    try {
      debugPrint('[lymarks/auth] $message');
    } on Object catch (e) {
      note('debugPrint threw: $e');
    }
  }

  @override
  bool get isSignedIn => state.isSignedIn;

  @override
  AuthUser? get user {
    final u = state.user;
    if (u == null) return null;
    final email = u.email ?? '';
    final name = [u.firstName, u.lastName]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    return AuthUser(
      email: email,
      name: name.isEmpty ? null : name,
      avatarUrl: u.imageUrl,
      createdAt: u.createdAt,
    );
  }

  @override
  Future<String?> token() async {
    if (!state.isSignedIn) return null;
    try {
      return (await state.sessionToken()).jwt;
    } on clerk.ClerkError catch (e) {
      debugPrint('[lymarks/auth] no session token: ${e.message}');
      return null;
    }
  }

  @override
  Future<void> signOut() => state.signOut();

  /// Termine une connexion OAuth revenue du navigateur par lien profond
  /// (`lymarks://oauth/<stratégie>?rotating_token_nonce=…`).
  ///
  /// Pris en charge ici plutôt que par `deepLinkStream` du SDK : sa version
  /// 0.0.18 s'arrête après `completeOAuthSignIn` et ne fait jamais le
  /// **transfert** — quand le compte Google ne correspond à aucun utilisateur
  /// (connexion → inscription) ou l'inverse (inscription → connexion). Sur le
  /// web, Clerk le fait d'office ; sans lui, l'utilisateur reste sur l'écran
  /// de connexion sans message (constaté sur device le 18/09, ADR-010).
  ///
  /// Les appels passent par `fetchApiResponse` (API bas niveau publique du
  /// SDK) plutôt que par `completeOAuthSignIn` : ce dernier ne fait rien, sans
  /// erreur, quand aucune tentative n'est en cours, et cache le statut HTTP.
  /// `fetchApiResponse` pose les en-têtes, met à jour le jeton client rotatif
  /// et applique la réponse au `Client` du SDK.
  Future<void> handleDeepLink(Uri uri) async {
    _trace('handler entered (${uri.scheme}://${uri.host}${uri.path})');
    try {
      if (uri.scheme != 'lymarks' || uri.host != 'oauth') {
        _trace('deep link ignored');
        return;
      }
      final nonce = uri.queryParameters['rotating_token_nonce'];
      final attempt = state.signIn ?? state.signUp;
      _trace(
        'params=${uri.queryParameters.keys.join(',')} '
        'signIn=${state.signIn?.status}/${state.signIn?.verification?.status} '
        'signUp=${state.signUp?.status}',
      );
      if (nonce != null && attempt != null) {
        // Échange du nonce : le Client revient avec la tentative avancée
        // (complète, ou `transferable` si le compte n'existe pas encore).
        final r = await state.fetchApiResponse(
          '/client/${attempt.urlType}/${attempt.id}',
          method: clerk.HttpMethod.get,
          params: {'rotating_token_nonce': nonce},
        );
        _trace('exchange: ${_describe(r)}');
      } else {
        // Sans nonce (pas de session créée : compte inconnu → transfert à
        // faire), on relit le Client. Pas via `refreshClient()` : le SDK y
        // rejette tout client dont `updated_at` n'a pas bougé, or Clerk ne
        // l'avance pas quand une tentative progresse — la réponse serait
        // jetée et la tentative resterait « unverified » (constaté 18/09).
        final r = await state.fetchApiResponse(
          '/client',
          method: clerk.HttpMethod.get,
        );
        _trace('client fetched: ${_describe(r)}');
      }
      _trace(
        'after: signIn=${state.signIn?.status}/'
        '${state.signIn?.verification?.status} '
        'signUp=${state.signUp?.status}',
      );
      if (state.signIn?.isTransferable == true) {
        final r = await state.fetchApiResponse(
          '/client/sign_ups',
          params: {'transfer': true},
        );
        _trace('transfer → sign-up: ${_describe(r)}');
      } else if (state.signUp?.isTransferable == true) {
        final r = await state.fetchApiResponse(
          '/client/sign_ins',
          params: {'transfer': true},
        );
        _trace('transfer → sign-in: ${_describe(r)}');
      }
      state.update();
      _trace('done: signedIn=${state.isSignedIn}');
    } on Object catch (e) {
      final text = '$e';
      _trace(
        'failed: ${text.length > 200 ? text.substring(0, 200) : text}',
      );
      // Remonte à l'écran de connexion (ClerkErrorListener) s'il écoute ;
      // sinon le SDK relance l'erreur, qu'on ne laisse pas planter l'app.
      try {
        state.handleError(e);
      } on Object catch (_) {}
    }
  }

  String _describe(clerk.ApiResponse r) =>
      'status=${r.status}'
      '${r.isError ? ' error=${r.errorCollection.errorMessage}' : ''}'
      ' signedIn=${state.isSignedIn}';

  @override
  void dispose() {
    state.removeListener(notifyListeners);
    oauthTrace.dispose();
    super.dispose();
  }
}
