import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Une capture en attente d'envoi.
///
/// Écrite par la feuille de partage, lue par l'app principale au lancement
/// et à chaque retour au premier plan. C'est la file locale du PRD §3
/// (« hors-ligne à la capture ») : l'UX de capture est identique avec ou
/// sans réseau, l'envoi se fait après.
@immutable
class PendingCapture {
  const PendingCapture({
    required this.id,
    required this.url,
    required this.title,
    required this.capturedAt,
    this.note,
  });

  factory PendingCapture.fromJson(Map<String, dynamic> json) => PendingCapture(
        id: json['id'] as String,
        url: json['url'] as String,
        title: json['title'] as String,
        note: json['note'] as String?,
        capturedAt: DateTime.parse(json['capturedAt'] as String),
      );

  final String id;
  final String url;
  final String title;
  final String? note;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'note': note,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
      };
}

/// File de captures persistée dans un fichier JSON.
///
/// Deux moteurs Flutter peuvent y accéder (celui de la feuille de partage,
/// celui de l'app), jamais en même temps en pratique : la feuille écrit puis
/// se ferme, l'app lit au retour au premier plan. L'écriture est atomique
/// (fichier temporaire puis renommage) pour qu'une lecture ne voie jamais un
/// fichier à moitié écrit.
class CaptureQueue {
  CaptureQueue(this.directory);

  final Directory directory;

  File get _file => File('${directory.path}${Platform.pathSeparator}'
      'capture_queue.json');

  Future<List<PendingCapture>> peek() async {
    if (!_file.existsSync()) return const [];
    try {
      final raw = await _file.readAsString();
      if (raw.trim().isEmpty) return const [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PendingCapture.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      // Un fichier corrompu ne doit jamais bloquer une capture : on repart
      // de zéro. Le contenu perdu se limite aux captures non encore lues.
      return const [];
    }
  }

  Future<void> enqueue(PendingCapture capture) async {
    final current = await peek();
    await _write([...current, capture]);
  }

  /// Rend toutes les captures et vide la file.
  Future<List<PendingCapture>> drain() async {
    final all = await peek();
    if (_file.existsSync()) await _file.delete();
    return all;
  }

  Future<void> _write(List<PendingCapture> captures) async {
    if (!directory.existsSync()) await directory.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode(captures.map((c) => c.toJson()).toList()),
      flush: true,
    );
    await tmp.rename(_file.path);
  }
}
