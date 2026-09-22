import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/shared/widgets/mascot.dart';

/// État vide.
///
/// UX Bible règle 12 : le vide est un état conçu, jamais un écran blanc. Le
/// ton reste positif et ne culpabilise jamais (§Ton).
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.accent,
    this.action,
    this.pose,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final LyAccent? accent;
  final Widget? action;

  /// Quand une pose est fournie, la mascotte prend la place de la pastille
  /// d'icône. Réservé aux écrans qui ont la place de l'accueillir : dans une
  /// carte ou un bandeau, l'icône reste la bonne réponse.
  final MascotPose? pose;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final a = accent ?? ly.steel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LySpace.xl,
          vertical: LySpace.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pose case final MascotPose p)
              MascotFigure(pose: p)
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: a.fill,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: a.onFill),
              ),
            const SizedBox(height: LySpace.xl),
            Text(
              title,
              style: context.texts.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LySpace.s),
            Text(
              message,
              style: context.texts.bodyMedium?.copyWith(
                color: ly.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: LySpace.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Mini-tutoriel de capture affiché quand la bibliothèque est vide
/// (UX Bible règle 12 : « liste vide = mini-tutoriel de capture »).
class CaptureTutorial extends StatelessWidget {
  const CaptureTutorial({super.key});

  static const List<({String step, String text})> _steps = [
    (step: '1', text: 'Open any app and tap Share.'),
    (step: '2', text: 'Pick Lymarks in the share sheet.'),
    (step: '3', text: 'Tap Save. That is it — we do the rest.'),
  ];

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Save your first link', style: context.texts.titleLarge),
        const SizedBox(height: LySpace.s),
        Text(
          'Three steps, then Lymarks remembers the context for you.',
          style: context.texts.bodyMedium?.copyWith(color: ly.textSecondary),
        ),
        const SizedBox(height: LySpace.xl),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: LySpace.l),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ly.accents[i % ly.accents.length].fill,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _steps[i].step,
                    style: context.texts.labelMedium?.copyWith(
                      color: ly.accents[i % ly.accents.length].onFill,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: LySpace.m),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _steps[i].text,
                      style: context.texts.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
