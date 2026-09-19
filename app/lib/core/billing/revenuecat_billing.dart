import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lymarks/core/billing/billing.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Store réel, via le SDK RevenueCat (`purchases_flutter`, version épinglée).
///
/// La clé est la clé **publique** du SDK, fournie au build ; avec une clé de
/// Test Store, le SDK simule le magasin (feuille d'achat factice,
/// renouvellements accélérés) sans compte développeur — c'est le chemin du
/// Shipaton Next Gen. Le webhook RevenueCat → API alimente `subscriptions`
/// dans les deux cas.
class RevenueCatBilling implements Billing {
  RevenueCatBilling({required this.apiKey});

  final String apiKey;

  /// Entitlement unique (Monetization Spec §2).
  static const String proEntitlement = 'pro';

  bool _configured = false;

  /// Packages de la dernière offre lue, par identifiant : l'UI ne manipule
  /// que des [ProPackage], le type du SDK reste ici.
  final Map<String, Package> _packages = {};

  @override
  bool get isAvailable => apiKey.isNotEmpty;

  @override
  Future<void> identify(String appUserId) async {
    if (!_configured) {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = appUserId,
      );
      _configured = true;
      _trace('configured for $appUserId');
      return;
    }
    if (await Purchases.appUserID != appUserId) {
      await Purchases.logIn(appUserId);
      _trace('switched to $appUserId');
    }
  }

  @override
  Future<void> forget() async {
    if (!_configured || await Purchases.isAnonymous) return;
    await Purchases.logOut();
    _trace('logged out');
  }

  @override
  Future<ProOffer?> offer() async {
    final current = (await Purchases.getOfferings()).current;
    if (current == null) return null;
    final out = <ProPackage>[];
    for (final p in current.availablePackages) {
      final period = switch (p.packageType) {
        PackageType.monthly => ProPeriod.monthly,
        PackageType.annual => ProPeriod.annual,
        _ => null,
      };
      if (period == null) continue;
      _packages[p.identifier] = p;
      out.add(
        ProPackage(
          id: p.identifier,
          period: period,
          priceString: p.storeProduct.priceString,
          price: p.storeProduct.price,
        ),
      );
    }
    return out.isEmpty ? null : ProOffer(out);
  }

  @override
  Future<PurchaseOutcome> purchase(ProPackage package) async {
    final p = _packages[package.id];
    if (p == null) return PurchaseOutcome.failed;
    try {
      final result = await Purchases.purchase(PurchaseParams.package(p));
      final pro = _hasPro(result.customerInfo);
      _trace('purchased ${package.id}, pro=$pro');
      // Payé mais sans droit : le store l'a accepté en différé.
      return pro ? PurchaseOutcome.purchased : PurchaseOutcome.pending;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      _trace('purchase ${package.id}: $code');
      return switch (code) {
        PurchasesErrorCode.purchaseCancelledError => PurchaseOutcome.cancelled,
        PurchasesErrorCode.paymentPendingError => PurchaseOutcome.pending,
        // Déjà abonné sur ce compte store : autant le restaurer.
        PurchasesErrorCode.productAlreadyPurchasedError =>
          await restore() ? PurchaseOutcome.purchased : PurchaseOutcome.failed,
        _ => PurchaseOutcome.failed,
      };
    }
  }

  @override
  Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      final pro = _hasPro(info);
      _trace('restored, pro=$pro');
      return pro;
    } on PlatformException catch (e) {
      _trace('restore: ${PurchasesErrorHelper.getErrorCode(e)}');
      return false;
    }
  }

  static bool _hasPro(CustomerInfo info) =>
      info.entitlements.active.containsKey(proEntitlement);

  void _trace(String message) => debugPrint('[lymarks/billing] $message');
}
