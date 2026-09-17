import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_theme.dart';
import 'package:lymarks/features/capture/share_sheet_view.dart';

/// Coquille minimale du moteur Flutter de la feuille de partage.
///
/// Pas de routeur, pas de données de démo, pas d'onglets — rien qui
/// ralentisse le chemin « tap → fermeture ». Fond transparent : l'activité
/// native est translucide et c'est la feuille elle-même qui dessine son
/// voile.
class ShareApp extends StatelessWidget {
  const ShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lymarks',
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      theme: LyTheme.light().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      darkTheme: LyTheme.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const ShareSheetView(),
    );
  }
}
