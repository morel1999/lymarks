import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/core/billing/billing.dart';

/// Tient le store au courant de qui est connecté.
///
/// À chaque changement de session, l'utilisateur connu est rattaché au store
/// (`appUserID` = identifiant Clerk, Monetization Spec §2) et la déconnexion
/// le détache. Les appels s'enchaînent dans l'ordre : une connexion suivie
/// d'une déconnexion rapide ne peut pas se croiser.
class BillingLink {
  BillingLink(this.billing, this.session) {
    session.addListener(_sync);
    _sync();
  }

  final Billing billing;
  final AuthSession session;

  String? _current;
  Future<void> _chain = Future<void>.value();

  void _sync() {
    _chain = _chain.then((_) => _apply());
  }

  Future<void> _apply() async {
    final id = session.isSignedIn ? session.user?.id : null;
    if (id == _current) return;
    _current = id;
    try {
      if (id != null) {
        await billing.identify(id);
      } else {
        await billing.forget();
      }
    } on Object catch (e) {
      // Le store est un confort : une panne ne doit jamais empêcher
      // d'utiliser l'app. Le prochain changement de session réessaie.
      _current = null;
      debugPrint('[lymarks/billing] link failed: $e');
    }
  }

  void dispose() => session.removeListener(_sync);
}
