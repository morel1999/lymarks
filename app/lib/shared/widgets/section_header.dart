import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';

/// En-tête de section : un titre à gauche, une action facultative à droite.
///
/// Reproduit « All Lymarks … See all → » de la Home.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    this.actionLabel,
    this.onAction,
    this.trailing,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Padding(
      padding: const EdgeInsets.only(bottom: LySpace.m),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: context.texts.headlineSmall),
          ),
          if (trailing != null)
            trailing!
          else if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: LySpace.s),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: context.texts.labelMedium?.copyWith(
                      color: ly.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: LySpace.xs),
                  Icon(LyIcons.forward, size: 16, color: ly.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Libellé de groupe des réglages : « PREFERENCES », « DATA ».
class SettingsGroupLabel extends StatelessWidget {
  const SettingsGroupLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(LySpace.xs, LySpace.xl, 0, LySpace.m),
      child: Text(
        label.toUpperCase(),
        style: context.texts.labelSmall?.copyWith(
          color: context.ly.textTertiary,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
