import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_theme.dart';
import 'package:lymarks/shared/data/providers.dart';

void main() {
  runApp(const ProviderScope(child: LymarksApp()));
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

class _LymarksAppState extends ConsumerState<LymarksApp> {
  late final GoRouter _router = buildRouter();

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
