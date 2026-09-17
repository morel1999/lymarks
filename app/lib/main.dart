import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_theme.dart';
import 'package:lymarks/features/capture/capture_sync.dart';
import 'package:lymarks/features/capture/share_app.dart';
import 'package:lymarks/shared/data/providers.dart';

void main() {
  runApp(const ProviderScope(child: LymarksApp()));
}

/// Point d'entrée du moteur Flutter de la feuille de partage.
///
/// Lancé par `ShareActivity.kt` via `getDartEntrypointFunctionName`. Défini
/// ici, dans le fichier cible de la compilation : un point d'entrée dans un
/// fichier jamais importé ne serait pas compilé du tout. `vm:entry-point`
/// empêche ensuite le tree-shaking de le retirer, puisque rien ne l'appelle.
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
  late final GoRouter _router = buildRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Les captures faites depuis le menu de partage attendent dans une file
    // locale : on les récupère au lancement…
    unawaited(ref.read(captureSyncProvider).sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // …et à chaque retour au premier plan, puisque la feuille de partage
    // tourne dans son propre moteur et ne peut pas nous prévenir.
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(captureSyncProvider).sync());
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
