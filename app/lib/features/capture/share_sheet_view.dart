import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/features/capture/capture_queue.dart';
import 'package:lymarks/features/capture/share_host.dart';
import 'package:lymarks/features/capture/shared_link.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/widgets/source_avatar.dart';

/// Feuille de capture du menu de partage (Design System §ShareSheetView).
///
/// La plus légère possible : source détectée, champ note d'une ligne, un seul
/// bouton. Aucune image, aucune liste, aucune décision imposée (UX Bible
/// règles 1 à 3). Elle se ferme dès l'enregistrement, avant tout traitement.
class ShareSheetView extends ConsumerStatefulWidget {
  const ShareSheetView({super.key});

  @override
  ConsumerState<ShareSheetView> createState() => _ShareSheetViewState();
}

enum _Phase { loading, ready, noLink, saving }

class _ShareSheetViewState extends ConsumerState<ShareSheetView> {
  final TextEditingController _note = TextEditingController();
  _Phase _phase = _Phase.loading;
  SharedLink? _link;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final payload = await ref.read(shareHostProvider).shared();
    if (!mounted) return;
    final link = payload == null
        ? null
        : SharedLink.parse(text: payload.text, subject: payload.subject);
    setState(() {
      _link = link;
      _phase = link == null ? _Phase.noLink : _Phase.ready;
    });
  }

  Future<void> _save() async {
    final link = _link;
    if (link == null || _phase == _Phase.saving) return;
    setState(() => _phase = _Phase.saving);

    final queue = await ref.read(captureQueueProvider.future);
    final note = _note.text.trim();
    await queue.enqueue(
      PendingCapture(
        id: 'cap-${DateTime.now().microsecondsSinceEpoch}',
        url: link.url,
        title: link.title,
        note: note.isEmpty ? null : note,
        capturedAt: DateTime.now(),
      ),
    );
    await _close();
  }

  Future<void> _close() async {
    final elapsed = await ref.read(shareHostProvider).close();
    // Budget « tap → fermeture < 2 s » (08-qualite/02-performance-budget).
    if (elapsed != null) debugPrint('[lymarks/share] closed after $elapsed ms');
  }

  /// Vrai quand ce partage sera gardé mais fermé : plan Free ayant atteint
  /// sa limite. La règle reste serveur (Monetization §3) ; ici on ne fait que
  /// prévenir avec ce que le profil sait déjà.
  bool _willLock() {
    final profile = ref.read(profileProvider);
    return !profile.isPro && profile.lymarkCount >= UserProfile.freeLimit;
  }

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Voile : un tap dehors annule, comme un bottom sheet natif.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedPadding(
              duration: LyMotion.micro,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Material(
                color: ly.card,
                borderRadius: LyRadius.sheetR,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      LySpace.xl,
                      LySpace.m,
                      LySpace.xl,
                      LySpace.xl,
                    ),
                    child: switch (_phase) {
                      _Phase.loading => const _Loading(),
                      _Phase.noLink => _NoLink(onClose: _close),
                      _Phase.ready || _Phase.saving => _Capture(
                        link: _link!,
                        note: _note,
                        saving: _phase == _Phase.saving,
                        // Dit avant d'enregistrer, pas apres coup : le
                        // profil connait deja le plan et le compte, aucune
                        // raison d'attendre le serveur pour prevenir.
                        willLock: _willLock(),
                        onSave: _save,
                      ),
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: LySpace.l),
        decoration: BoxDecoration(
          color: context.ly.cardBorder,
          borderRadius: LyRadius.pillR,
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Handle(),
        SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ],
    );
  }
}

class _Capture extends StatelessWidget {
  const _Capture({
    required this.link,
    required this.note,
    required this.saving,
    required this.willLock,
    required this.onSave,
  });

  final SharedLink link;
  final TextEditingController note;
  final bool saving;

  /// Le compte Free a atteint sa limite : le lien sera garde, mais ferme.
  final bool willLock;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Handle(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SourceAvatar(
              domain: link.domain,
              accent: ly.accentFor(link.domain),
              size: 48,
            ),
            const SizedBox(width: LySpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(link.domain, style: context.texts.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    link.title,
                    style: context.texts.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (link.ignoredUrlCount > 0) ...[
          const SizedBox(height: LySpace.s),
          Text(
            link.ignoredUrlCount == 1
                ? 'One more link in this share. Saving the first.'
                : '${link.ignoredUrlCount} more links in this share. '
                      'Saving the first.',
            style: context.texts.labelSmall,
          ),
        ],
        if (willLock) ...[
          const SizedBox(height: LySpace.m),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LyIcons.security,
                size: LyIconSize.small,
                color: ly.textSecondary,
              ),
              const SizedBox(width: LySpace.s),
              Expanded(
                child: Text(
                  'Your free plan is full. This link is kept anyway, '
                  'locked until you go Pro.',
                  style: context.texts.labelSmall?.copyWith(
                    color: ly.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: LySpace.l),
        TextField(
          controller: note,
          enabled: !saving,
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSave(),
          style: context.texts.bodyLarge,
          cursorColor: ly.primary,
          decoration: InputDecoration(
            hintText: 'Add a note (optional)',
            hintStyle: context.texts.bodyLarge?.copyWith(
              color: ly.textTertiary,
            ),
            filled: true,
            fillColor: ly.chipFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: LySpace.l,
              vertical: LySpace.m,
            ),
            border: _border(ly.chipFill),
            enabledBorder: _border(ly.chipFill),
            focusedBorder: _border(ly.primary, width: 1.5),
          ),
        ),
        const SizedBox(height: LySpace.l),
        FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LyIcons.bookmark, size: LyIconSize.regular),
          label: Text(saving ? 'Saving' : 'Save to Lymarks'),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: LyRadius.cardR,
        borderSide: BorderSide(color: color, width: width),
      );
}

class _NoLink extends StatelessWidget {
  const _NoLink({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Handle(),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ly.yellow.fill,
                borderRadius: LyRadius.tileR,
              ),
              child: Icon(LyIcons.warning, size: 20, color: ly.yellow.onFill),
            ),
            const SizedBox(width: LySpace.m),
            Expanded(
              child: Text(
                'No link in what you shared.',
                style: context.texts.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: LySpace.s),
        Text(
          'Lymarks saves links. Share a page, a post or a video '
          'and it will remember the context for you.',
          style: context.texts.bodySmall?.copyWith(color: ly.textSecondary),
        ),
        const SizedBox(height: LySpace.l),
        OutlinedButton(onPressed: onClose, child: const Text('Close')),
      ],
    );
  }
}
