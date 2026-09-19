/// Configuration de build, injectée par `--dart-define` (jamais lue d'un
/// fichier embarqué : Security §2, zéro secret dans l'app).
///
/// Sans clé Clerk, l'app tourne en **mode démo** : données locales, session
/// factice, aucun réseau. C'est le mode des tests et des rendus de
/// référence. La CI fournit toujours la clé pour les APK (`android.yml`).
abstract final class AppConfig {
  /// URL de base de l'API (Workers). Surchargeable pour une branche de test.
  static const String apiBaseUrl = String.fromEnvironment(
    'LYMARKS_API_URL',
    defaultValue: 'https://lymarks-api.lymarks.workers.dev',
  );

  /// Publishable key Clerk (`pk_test_…` / `pk_live_…`) — publique par design.
  static const String clerkPublishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
  );

  /// Clé publique du SDK RevenueCat (Test Store pendant le Shipaton, clé
  /// Play ensuite) — jamais la clé secrète REST, qui reste côté API. Vide :
  /// pas d'achats dans ce build, le paywall le dit.
  static const String revenuecatPublicKey = String.fromEnvironment(
    'REVENUECAT_PUBLIC_KEY',
  );

  /// Vrai quand une clé Clerk est fournie : auth réelle + API réelle.
  static bool get isLive => clerkPublishableKey.isNotEmpty;

  /// Vrai quand un store est branché (mode réel et clé RevenueCat fournie).
  static bool get hasPurchases => isLive && revenuecatPublicKey.isNotEmpty;

  /// Mode démo : mock local, session factice.
  static bool get isDemo => !isLive;
}
