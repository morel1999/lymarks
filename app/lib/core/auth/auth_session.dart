import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identité affichée dans l'app. Vient de Clerk (ADR-002) ; l'API, elle, ne
/// connaît que l'identifiant Clerk porté par le jeton.
@immutable
class AuthUser {
  const AuthUser({
    required this.email,
    this.name,
    this.avatarUrl,
    this.createdAt,
  });

  final String email;
  final String? name;
  final String? avatarUrl;
  final DateTime? createdAt;

  /// Nom à afficher : prénom + nom, sinon la partie locale de l'e-mail.
  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }
}

/// Session d'authentification vue par le reste de l'app.
///
/// Un seul contrat pour la session Clerk réelle et la session factice du mode
/// démo / des tests. C'est un [Listenable] : le routeur s'y abonne pour
/// rediriger à la connexion et à la déconnexion.
abstract class AuthSession implements Listenable {
  bool get isSignedIn;
  AuthUser? get user;

  /// JWT de session à présenter à l'API, ou null si déconnecté. Ne lève
  /// jamais : un échec de rafraîchissement vaut « pas de jeton ».
  Future<String?> token();

  Future<void> signOut();
}

/// Session du mode démo : toujours connectée, jeton factice.
class DemoAuthSession extends ChangeNotifier implements AuthSession {
  DemoAuthSession({
    this.signedIn = true,
    this.user = const AuthUser(
      email: 'morel@lymarks.app',
      name: 'Morel Herval',
    ),
  });

  bool signedIn;

  @override
  final AuthUser? user;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<String?> token() async => signedIn ? 'demo-token' : null;

  @override
  Future<void> signOut() async {
    signedIn = false;
    notifyListeners();
  }

  /// Pour les tests : reconnecte sans passer par une UI.
  void signIn() {
    signedIn = true;
    notifyListeners();
  }
}

/// Session courante. Surchargée à la racine par `main()` en mode réel
/// (Clerk) ; la valeur par défaut est la session démo.
final Provider<AuthSession> authSessionProvider = Provider<AuthSession>(
  (_) => DemoAuthSession(),
);
