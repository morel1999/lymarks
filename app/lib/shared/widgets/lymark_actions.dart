import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:url_launcher/url_launcher.dart';

/// Surfaces secondaires d'un lymark : menu ⋯, édition de la note,
/// confirmation de suppression.
///
/// Aucune action simple n'ouvre une page entière (UX Bible règle 9) et toute
/// suppression reste réversible 5 secondes (règle 7).
abstract final class LymarkActions {
  /// Ouvre la page d'origine.
  ///
  /// Navigateur en surcouche d'abord (Custom Tabs sur Android,
  /// SFSafariViewController sur iOS) : l'utilisateur revient à Lymarks d'un
  /// geste, sans passer par le sélecteur d'applications. Un appareil sans
  /// navigateur compatible retombe sur l'ouverture externe, et un lien
  /// qu'aucun des deux ne sait ouvrir le dit — jamais un bouton muet
  /// (PRD §3 : aucun échec silencieux).
  static Future<void> openOriginal(BuildContext context, Lymark lymark) async {
    final uri = Uri.tryParse(lymark.url);
    if (uri == null || !uri.hasScheme) {
      _toast(context, "This link can't be opened.");
      return;
    }

    for (final mode in const [
      LaunchMode.inAppBrowserView,
      LaunchMode.externalApplication,
    ]) {
      try {
        if (await launchUrl(uri, mode: mode)) return;
      } on PlatformException catch (e) {
        debugPrint('[lymarks/open] ${mode.name}: ${e.code}');
      }
    }
    if (!context.mounted) return;
    _toast(context, "Couldn't open this link.");
  }

  /// Menu ⋯ d'une carte ou d'une fiche.
  static Future<void> showMenu(
    BuildContext context,
    WidgetRef ref,
    Lymark lymark, {
    VoidCallback? onDeleted,
  }) async {
    final ly = context.ly;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.xl,
                LySpace.s,
                LySpace.xl,
                LySpace.l,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lymark.title,
                      style: context.texts.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            _MenuTile(
              icon: LyIcons.openExternal,
              label: 'Open original',
              onTap: () {
                // La feuille se ferme d'abord : le navigateur revient sur la
                // fiche, pas sur un menu reste ouvert dessous.
                Navigator.of(sheetContext).pop();
                unawaited(openOriginal(context, lymark));
              },
            ),
            _MenuTile(
              icon: LyIcons.copy,
              label: 'Copy link',
              onTap: () {
                unawaited(
                  Clipboard.setData(ClipboardData(text: lymark.url)),
                );
                Navigator.of(sheetContext).pop();
                _toast(context, 'Link copied');
              },
            ),
            _MenuTile(
              icon: LyIcons.edit,
              label: lymark.hasNote ? 'Edit note' : 'Add a note',
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(editNote(context, ref, lymark));
              },
            ),
            _MenuTile(
              icon: LyIcons.delete,
              label: 'Delete',
              color: ly.danger,
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(
                  confirmDelete(context, ref, lymark, onDeleted: onDeleted),
                );
              },
            ),
            const SizedBox(height: LySpace.s),
          ],
        ),
      ),
    );
  }

  /// Édition de la note dans un bottom sheet, jamais dans une page dédiée
  /// (wireframe 04 §Your Note).
  static Future<void> editNote(
    BuildContext context,
    WidgetRef ref,
    Lymark lymark,
  ) async {
    final controller = TextEditingController(text: lymark.note ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: LySpace.xl,
          right: LySpace.xl,
          top: LySpace.s,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + LySpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your note', style: context.texts.headlineSmall),
            const SizedBox(height: LySpace.s),
            Text(
              'Why you saved this. Only you can see it.',
              style: context.texts.bodySmall?.copyWith(
                color: context.ly.textSecondary,
              ),
            ),
            const SizedBox(height: LySpace.l),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              style: context.texts.bodyLarge,
              cursorColor: context.ly.primary,
              decoration: InputDecoration(
                hintText: 'This could be useful for...',
                filled: true,
                fillColor: context.ly.chipFill,
                border: OutlineInputBorder(
                  borderRadius: LyRadius.cardR,
                  borderSide: BorderSide(color: context.ly.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: LyRadius.cardR,
                  borderSide: BorderSide(color: context.ly.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: LyRadius.cardR,
                  borderSide: BorderSide(color: context.ly.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: LySpace.l),
            FilledButton(
              onPressed: () {
                ref
                    .read(lymarksProvider.notifier)
                    .updateNote(lymark.id, controller.text);
                Navigator.of(sheetContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
  }

  /// Confirmation explicite, puis suppression avec undo de 5 s.
  static Future<void> confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Lymark lymark, {
    VoidCallback? onDeleted,
  }) async {
    final ly = context.ly;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Lymark?'),
        content: Text('“${lymark.title}” will be removed from your memory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ly.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: TextStyle(color: ly.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final removed = ref.read(lymarksProvider.notifier).remove(lymark.id);
    if (removed == null) return;
    onDeleted?.call();

    if (!context.mounted) return;
    final notifier = ref.read(lymarksProvider.notifier);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('Lymark deleted'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => notifier.restore(removed.lymark, removed.index),
        ),
      ),
    );
    // Fenêtre d'annulation passée sans « Undo » : suppression définitive
    // côté serveur (jusque-là, l'entrée n'était qu'archivée).
    unawaited(
      controller.closed.then((reason) {
        if (reason != SnackBarClosedReason.action) {
          unawaited(notifier.purge(lymark.id));
        }
      }),
    );
  }

  static void _toast(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.ly.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: LyIconSize.regular, color: fg),
      title: Text(
        label,
        style: context.texts.bodyLarge?.copyWith(color: fg),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: LySpace.xl),
    );
  }
}
