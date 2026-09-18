import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/core/auth/clerk_session.dart';
import 'package:lymarks/core/config/app_config.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_theme.dart';
import 'package:lymarks/features/capture/capture_sync.dart';
import 'package:lymarks/features/capture/share_app.dart';
import 'package:lymarks/shared/data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mode démo (aucune clé Clerk fournie au build) : session factice, données
  // locales — voir AppConfig.
  if (AppConfig.isDemo) {
    runApp(const ProviderScope(child: LymarksApp()));
    return;
  }

  // Mode réel : le SDK Clerk restaure la session persistée avant le premier
  // rendu, pour que le routeur parte directement sur la bonne route.
  final clerk = await ClerkAuthState.create(
    config: ClerkAuthConfig(publishableKey: AppConfig.clerkPublishableKey),
  );
  final session = ClerkAuthSession(clerk);
  runApp(
    ProviderScope(
      overrides: [authSessionProvider.overrideWithValue(session)],
      child: ClerkAuth(authState: clerk, child: const LymarksApp()),
    ),
  );
}

/// Point d'entrée du moteur Flutter de la feuille de partage.
///
/// Lancé par `ShareActivity.kt` via `getDartEntrypointFunctionName`. Défini
/// ici, dans le fichier cible de la compilation : un point d'entrée dans un
/// fichier jamais importé ne serait pas compilé du tout. `vm:entry-point`
/// empêche ensuite le tree-shaking de le retirer, puisque rien ne l'appelle.
/// La feuille n'a besoin ni d'auth ni de réseau : elle écrit dans la file.
@pragma('vm:entry-point')
void shareMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ShareApp()));
}

/// Racine de l'application.
///
/// Le mode sombre suit le système par défaut (Design System : dark natif dès
/// la V1.0) et reste surchargeable depuis les réglages.
class LymarksApp extends ConsumerStatefulWidget {
  const LymarksApp({super.key});

  @override
  ConsumerState<LymarksApp> createState() => _LymarksAppState();
}

class _LymarksAppState extends ConsumerState<LymarksApp>
    with WidgetsBindingObserver {
  late final AuthSession _auth = ref.read(authSessionProvider);
  late final GoRouter _router = buildRouter(auth: _auth);
  late bool _wasSignedIn = _auth.isSignedIn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_onAuthChanged);
    // Les captures faites depuis le menu de partage attendent dans une file
    // locale : on les récupère au lancement…
    unawaited(ref.read(captureSyncProvider).sync());
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  /// Connexion ou déconnexion : les données de l'ancien utilisateur ne
  /// doivent pas survivre. Tout ce qui dérive de la session est reconstruit,
  /// puis la file de captures est envoyée si on vient de se connecter.
  void _onAuthChanged() {
    final signedIn = _auth.isSignedIn;
    if (signedIn == _wasSignedIn) return;
    _wasSignedIn = signedIn;
    ref
      ..invalidate(lymarksProvider)
      ..invalidate(meProvider)
      ..invalidate(searchStateProvider);
    if (signedIn) unawaited(ref.read(captureSyncProvider).sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // …et à chaque retour au premier plan, puisque la feuille de partage
    // tourne dans son propre moteur et ne peut pas nous prévenir. La liste
    // est rafraîchie au passage : le pipeline a pu finir pendant l'absence.
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(captureSyncProvider).sync());
      unawaited(ref.read(lymarksProvider.notifier).refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lymarks',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: LyTheme.light(),
      darkTheme: LyTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      // L'i18n est branchée dès le départ (coding standards §2). Les chaînes
      // seront extraites vers des ARB FR+EN à l'étape suivante.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr')],
    );
  }
}
