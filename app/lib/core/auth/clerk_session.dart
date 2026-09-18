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

  void _trace(String message) {
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    oauthTrace.value = [...oauthTrace.value, '$stamp $message'];
    debugPrint('[lymarks/auth] $message');
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
  Future<void> handleDeepLink(Uri uri) async {
    _trace('handler entered (${uri.scheme}://${uri.host}${uri.path})');
    try {
      if (uri.scheme != 'lymarks' || uri.host != 'oauth') {
        _trace('deep link ignored');
        return;
      }
      final nonce = uri.queryParameters['rotating_token_nonce'];
      _trace('nonce=${nonce != null}');
      final signIn = state.signIn;
      final signUp = state.signUp;
      _trace(
        'signIn=${signIn?.status}/${signIn?.verification?.status} '
        'signUp=${signUp?.status}',
      );
      if (nonce != null && (signIn != null || signUp != null)) {
        _trace('completeOAuthSignIn…');
        await state.completeOAuthSignIn(token: nonce);
        _trace('token exchanged: signedIn=${state.isSignedIn}');
      } else {
        _trace('refreshClient…');
        await state.refreshClient();
        _trace('client refreshed: signedIn=${state.isSignedIn}');
      }
      final transferable =
          state.signIn?.isTransferable == true ||
          state.signUp?.isTransferable == true;
      _trace(
        'after: signIn=${state.signIn?.status}/'
        '${state.signIn?.verification?.status} '
        'signUp=${state.signUp?.status} transferable=$transferable',
      );
      if (transferable) {
        _trace('transfer…');
        await state.transfer();
        _trace('transferred: signedIn=${state.isSignedIn}');
      }
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

  @override
  void dispose() {
    state.removeListener(notifyListeners);
    oauthTrace.dispose();
    super.dispose();
  }
}
