import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';

/// Ligne de réglage : tuile d'icône colorée, titre, sous-titre, chevron.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.danger = false,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final LyAccent accent;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Action destructive : le libellé passe en couleur d'alerte.
  final bool danger;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LySpace.l,
            vertical: LySpace.m,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.fill,
                  borderRadius: LyRadius.tileR,
                ),
                child: Icon(
                  icon,
                  size: LyIconSize.regular,
                  color: danger ? ly.danger : accent.onFill,
                ),
              ),
              const SizedBox(width: LySpace.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.texts.titleSmall?.copyWith(
                        color: danger ? ly.danger : ly.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.texts.labelSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(LyIcons.forward, size: 20, color: ly.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Groupe de [SettingsTile] dans une seule carte, séparés par des filets.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Container(
      decoration: BoxDecoration(
        color: ly.card,
        borderRadius: LyRadius.cardR,
        border: Border.all(color: ly.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 72),
                child: Divider(height: 1, color: ly.cardBorder),
              ),
          ],
        ],
      ),
    );
  }
}
