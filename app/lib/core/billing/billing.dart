import 'package:flutter/foundation.dart';

/// Achats in-app vus par le reste de l'app (ADR-006, Monetization Spec §2).
///
/// Un seul contrat pour le SDK RevenueCat et pour l'implémentation vide du
/// mode démo / des tests. L'app **affiche** ce que le store lui dit ; le droit
/// Pro, lui, est décidé par le serveur à partir du webhook RevenueCat
/// (Monetization Spec §3) — jamais par ce code.
abstract class Billing {
  /// Vrai quand un store est branché : une clé RevenueCat a été fournie au
  /// build et le SDK est utilisable.
  bool get isAvailable;

  /// Rattache les achats au compte : à appeler dès que l'utilisateur est
  /// connu (identifiant Clerk, Monetization Spec §2). Idempotent.
  Future<void> identify(String appUserId);

  /// Détache les achats du compte à la déconnexion.
  Future<void> forget();

  /// Forfaits Pro proposés (offre courante). Null quand le store n'en a pas.
  Future<ProOffer?> offer();

  Future<PurchaseOutcome> purchase(ProPackage package);

  /// Relie les achats passés au compte. Vrai si `pro` est actif ensuite.
  Future<bool> restore();

  /// Page de gestion de l'abonnement, chez le store qui l'encaisse.
  ///
  /// Résilier ne se fait pas dans l'app : c'est Google Play ou l'App Store
  /// qui détient l'abonnement, et RevenueCat en donne l'adresse. Null quand
  /// l'utilisateur n'a rien à gérer — pas d'abonnement, ou pas de store.
  Future<Uri?> managementUrl();
}

/// Aucun store : mode démo, tests, build sans clé.
class NoBilling implements Billing {
  const NoBilling();

  @override
  bool get isAvailable => false;

  @override
  Future<void> identify(String appUserId) async {}

  @override
  Future<void> forget() async {}

  @override
  Future<ProOffer?> offer() async => null;

  @override
  Future<PurchaseOutcome> purchase(ProPackage package) async =>
      PurchaseOutcome.unavailable;

  @override
  Future<bool> restore() async => false;

  @override
  Future<Uri?> managementUrl() async => null;
}

enum ProPeriod { monthly, annual }

/// Issue d'un achat, du point de vue de l'UI.
enum PurchaseOutcome {
  /// Payé et confirmé par le store.
  purchased,

  /// L'utilisateur a fermé la feuille du store : rien à dire.
  cancelled,

  /// Paiement différé (validation parentale, virement) : Pro viendra plus tard.
  pending,

  /// Erreur du store ou du réseau : rien n'a été débité.
  failed,

  /// Aucun store branché dans ce build.
  unavailable,
}

/// Un forfait Pro tel que le store le vend.
@immutable
class ProPackage {
  const ProPackage({
    required this.id,
    required this.period,
    required this.priceString,
    required this.price,
  });

  /// Identifiant du package RevenueCat (`$rc_monthly`, `$rc_annual`).
  final String id;
  final ProPeriod period;

  /// Prix formaté par le store, devise comprise (« 4,99 € », « $4.99 »).
  final String priceString;

  /// Prix numérique, pour calculer l'économie de l'annuel.
  final double price;
}

/// Offre courante : au plus un mensuel et un annuel.
@immutable
class ProOffer {
  const ProOffer(this.packages);

  /// Prix de la proposition du Monetization Spec §1, affichés en démo (et
  /// dans les rendus de référence) quand aucun store n'est branché.
  static const ProOffer preview = ProOffer([
    ProPackage(
      id: 'preview_monthly',
      period: ProPeriod.monthly,
      priceString: '4,99 €',
      price: 4.99,
    ),
    ProPackage(
      id: 'preview_annual',
      period: ProPeriod.annual,
      priceString: '39,99 €',
      price: 39.99,
    ),
  ]);

  final List<ProPackage> packages;

  ProPackage? get monthly => _byPeriod(ProPeriod.monthly);
  ProPackage? get annual => _byPeriod(ProPeriod.annual);

  ProPackage? _byPeriod(ProPeriod p) {
    for (final pkg in packages) {
      if (pkg.period == p) return pkg;
    }
    return null;
  }

  /// Économie de l'annuel face à douze mensualités, en pourcentage entier ;
  /// null s'il manque un forfait ou si l'annuel ne fait pas économiser.
  int? get annualSavingsPercent {
    final m = monthly;
    final a = annual;
    if (m == null || a == null || m.price <= 0) return null;
    final pct = ((1 - a.price / (12 * m.price)) * 100).round();
    return pct > 0 ? pct : null;
  }
}
