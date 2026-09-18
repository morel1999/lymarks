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
    if (uri.scheme != 'lymarks' || uri.host != 'oauth') return;
    final nonce = uri.queryParameters['rotating_token_nonce'];
    try {
      if (nonce != null && (state.signIn != null || state.signUp != null)) {
        await state.completeOAuthSignIn(token: nonce);
      } else {
        await state.refreshClient();
      }
      if (state.signIn?.isTransferable == true ||
          state.signUp?.isTransferable == true) {
        await state.transfer();
      }
      debugPrint(
        '[lymarks/auth] oauth return handled, signedIn=${state.isSignedIn}',
      );
    } on Object catch (e) {
      debugPrint('[lymarks/auth] oauth return failed: $e');
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
    super.dispose();
  }
}
