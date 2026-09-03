import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';

/// Vignette de source d'un lymark.
///
/// Aucune image distante n'est chargée : la liste ne doit émettre aucune
/// requête vers un tiers (Core Principles §5, et cela protège le budget de
/// scroll à 60 FPS). L'icône vient de la table [LyIcons.forDomain] et la
/// couleur de l'accent stable du lymark.
class SourceAvatar extends StatelessWidget {
  const SourceAvatar({
    required this.domain,
    required this.accent,
    this.size = 52,
    super.key,
  });

  final String domain;
  final LyAccent accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.fill,
        borderRadius: LyRadius.tileR,
      ),
      child: Icon(
        LyIcons.forDomain(domain),
        size: size * 0.46,
        color: accent.onFill,
      ),
    );
  }
}
