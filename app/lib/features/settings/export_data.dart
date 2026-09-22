import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/core/utils/open_link.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Export JSON de tout ce que le compte contient (Privacy Spec §5).
///
/// Disponible sur tous les plans, Free compris : le RGPD (art. 20) fait de la
/// portabilité un droit, pas une option payante. Le fichier part par la
/// feuille de partage du système — l'utilisateur choisit où il atterrit, et
/// rien ne traîne dans un dossier qu'il ne trouvera jamais.
Future<void> exportMyData(BuildContext context, WidgetRef ref) async {
  LyLink.toast(context, 'Preparing your export…');

  try {
    final data = await ref.read(lymarksRepositoryProvider).export();
    final file = await _write(data);

    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        fileNameOverrides: [_fileName()],
        subject: 'Lymarks export',
      ),
    );
  } on Object catch (e) {
    debugPrint('[lymarks/export] $e');
    if (!context.mounted) return;
    LyLink.toast(context, "Couldn't prepare the export. Try again.");
  }
}

/// Le JSON est indenté : un export qu'on ne peut pas lire soi-même ne vaut
/// pas grand-chose comme preuve de portabilité.
Future<File> _write(Map<String, dynamic> data) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${_fileName()}');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(data),
    flush: true,
  );
  return file;
}

String _fileName() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return 'lymarks-export-${now.year}-$month-$day.json';
}
