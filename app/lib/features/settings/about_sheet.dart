import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/core/utils/open_link.dart';
import 'package:lymarks/shared/widgets/mascot.dart';

/// Carte d'identité de l'app.
///
/// Une feuille, pas une page : rien ici ne mérite qu'on quitte les réglages
/// (UX Bible règle 9). La mascotte y figure parce que c'est le seul écran qui
/// parle de Lymarks lui-même — ailleurs elle n'accompagne que le vide et
/// l'échec (`02-ux/03-mascotte.md`).
abstract final class AboutSheet {
  /// Tenue à la main avec `pubspec.yaml`. Lire la vraie version du paquet
  /// demanderait une dépendance de plus pour une ligne de texte.
  static const String version = '1.0.0';

  static final Uri repoUrl = Uri.parse('https://github.com/morel1999/lymarks');
  static final Uri issuesUrl = Uri.parse(
    'https://github.com/morel1999/lymarks/issues',
  );

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LySpace.xl,
          LySpace.l,
          LySpace.xl,
          LySpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: MascotFigure(pose: MascotPose.idle, height: 120),
            ),
            const SizedBox(height: LySpace.l),
            Text('Lymarks', style: sheetContext.texts.headlineSmall),
            const SizedBox(height: 2),
            Text(
              'Version $version',
              style: sheetContext.texts.bodySmall?.copyWith(
                color: sheetContext.ly.textSecondary,
              ),
            ),
            const SizedBox(height: LySpace.m),
            Text(
              'Turn forgotten links into a memory you can search. '
              'Save anything in under two seconds; Lymarks reads it, '
              'summarises it and files it for you.',
              style: sheetContext.texts.bodyMedium?.copyWith(
                color: sheetContext.ly.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: LySpace.xl),
            _AboutRow(
              icon: LyIcons.openExternal,
              label: 'Source code',
              onTap: () => unawaited(LyLink.open(sheetContext, repoUrl)),
            ),
            _AboutRow(
              icon: LyIcons.note,
              label: 'Open-source licenses',
              onTap: () {
                Navigator.of(sheetContext).pop();
                showLicensePage(
                  context: context,
                  applicationName: 'Lymarks',
                  applicationVersion: version,
                  applicationIcon: const Padding(
                    padding: EdgeInsets.only(bottom: LySpace.m),
                    child: MascotFigure(
                      pose: MascotPose.idle,
                      height: 84,
                      glow: false,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return InkWell(
      onTap: onTap,
      borderRadius: LyRadius.cardR,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LySpace.m),
        child: Row(
          children: [
            Icon(icon, size: LyIconSize.regular, color: ly.primary),
            const SizedBox(width: LySpace.m),
            Expanded(
              child: Text(label, style: context.texts.bodyLarge),
            ),
            Icon(LyIcons.forward, size: 18, color: ly.textSecondary),
          ],
        ),
      ),
    );
  }
}
