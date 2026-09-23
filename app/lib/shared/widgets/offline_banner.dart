import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';

/// Bandeau discret quand l'app travaille sans réseau.
///
/// Jamais une erreur : rien n'est cassé, l'app fonctionne simplement sur ce
/// qu'elle a déjà. D'où le jaune (attention) plutôt que le rouge (panne), et
/// un message qui dit ce que l'utilisateur voit — pas ce qui a échoué.
///
/// Partagé par la Home et la recherche : les deux écrans montrent une vue
/// partielle sans réseau, et doivent le dire de la même façon.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LySpace.screen,
        0,
        LySpace.screen,
        LySpace.m,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LySpace.m,
          vertical: LySpace.s,
        ),
        decoration: BoxDecoration(
          color: ly.yellow.fill,
          borderRadius: LyRadius.tileR,
        ),
        child: Row(
          children: [
            Icon(
              LyIcons.offline,
              size: LyIconSize.small,
              color: ly.yellow.onFill,
            ),
            const SizedBox(width: LySpace.s),
            Expanded(
              child: Text(
                message,
                style: context.texts.bodySmall?.copyWith(
                  color: ly.yellow.onFill,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
