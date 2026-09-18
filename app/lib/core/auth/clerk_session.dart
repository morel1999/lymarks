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

  @override
  void dispose() {
    state.removeListener(notifyListeners);
    super.dispose();
  }
}
