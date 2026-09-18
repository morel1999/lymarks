import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';

/// Les trois intentions du produit (wireframe 02 §Navigation principale) :
/// explorer, retrouver, redécouvrir.
enum LyTab { home, search, digest }

/// Barre de navigation flottante en pilule.
///
/// L'onglet actif prend une pastille claire, comme sur les maquettes. Les
/// réglages ne sont pas un onglet : ils restent accessibles depuis le compte.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.current,
    required this.onSelect,
    super.key,
  });

  final LyTab current;
  final void Function(LyTab tab) onSelect;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LySpace.l,
          0,
          LySpace.l,
          LySpace.m,
        ),
        child: Container(
          padding: const EdgeInsets.all(LySpace.xs + 2),
          decoration: BoxDecoration(
            color: ly.navSurface,
            borderRadius: LyRadius.pillR,
          ),
          child: Row(
            children: [
              for (final tab in LyTab.values)
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    selected: tab == current,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final LyTab tab;
  final bool selected;
  final VoidCallback onTap;

  static const Map<LyTab, ({IconData icon, String label})> _spec = {
    LyTab.home: (icon: LyIcons.home, label: 'Home'),
    LyTab.search: (icon: LyIcons.search, label: 'Search'),
    LyTab.digest: (icon: LyIcons.digest, label: 'Digest'),
  };

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final spec = _spec[tab]!;
    final fg = selected ? ly.primary : ly.textSecondary;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? ly.card : Colors.transparent,
        borderRadius: LyRadius.pillR,
        child: InkWell(
          onTap: onTap,
          borderRadius: LyRadius.pillR,
          child: AnimatedContainer(
            duration: LyMotion.micro,
            curve: LyMotion.microCurve,
            padding: const EdgeInsets.symmetric(vertical: LySpace.m),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(spec.icon, size: LyIconSize.regular, color: fg),
                const SizedBox(width: LySpace.s),
                Flexible(
                  child: Text(
                    spec.label,
                    style: context.texts.labelMedium?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
