import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/widgets/ly_card.dart';
import 'package:lymarks/shared/widgets/mascot.dart';

/// Explique pourquoi des lymarks sont là sans être lisibles.
///
/// Posée au-dessus du groupe verrouillé, une seule fois : répéter le message
/// sur chaque carte le transformerait en bruit. Elle dit trois choses dans
/// cet ordre — **tes liens sont bien arrivés**, voici pourquoi ils sont
/// fermés, voici comment les ouvrir. La rassurance d'abord : la peur de
/// l'utilisateur est d'avoir perdu quelque chose.
///
/// La mascotte dort : les liens ne sont ni perdus ni en échec, ils attendent.
class LockedNotice extends StatelessWidget {
  const LockedNotice({required this.count, required this.onUpgrade, super.key});

  /// Nombre de lymarks gardés hors d'atteinte.
  final int count;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final accent = ly.yellow;

    return LyCard(
      color: accent.fill,
      borderColor: accent.fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MascotFigure(
                pose: MascotPose.sleeping,
                height: 84,
                glow: false,
              ),
              const SizedBox(width: LySpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? '1 lymark is waiting for you.'
                          : '$count lymarks are waiting for you.',
                      style: context.texts.titleSmall?.copyWith(
                        color: accent.onFill,
                      ),
                    ),
                    const SizedBox(height: LySpace.xs),
                    Text(
                      'We saved every link you sent. Free keeps '
                      '${UserProfile.freeLimit} of them open at a time, so '
                      'these stay closed until you go Pro. Nothing is lost.',
                      style: context.texts.bodySmall?.copyWith(
                        color: accent.onFill.withValues(alpha: 0.8),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LySpace.l),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onUpgrade,
              child: const Text('Unlock with Pro'),
            ),
          ),
        ],
      ),
    );
  }
}
