import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fondu d'arrivée de l'image (UX Bible règle 8 : micro-interaction <150 ms).
const Duration _fade = Duration(milliseconds: 150);

/// Ratio 1,91:1 des images `og:image` : on décode assez large pour qu'une
/// telle image couvre encore toute la hauteur du cadre en `BoxFit.cover`.
const double _ogAspect = 1.91;

/// Image d'aperçu d'un lymark, avec repli visuel.
///
/// [fallback] (vignette de source, dégradé d'accent) reste affiché tant que
/// l'image n'est pas décodée, si [url] est nul et si le chargement échoue :
/// l'aperçu n'est qu'un renfort de reconnaissance, jamais un cadre vide ni un
/// squelette (le shimmer signifie « le pipeline travaille », pas « l'image
/// arrive »). L'image se pose ensuite par un fondu de 150 ms.
///
/// Pas de cache disque en MVP ; `cacheWidth` borne la mémoire décodée à la
/// taille affichée (téléphones modestes). Le cadre doit être borné : [width]
/// et [height] explicites, ou hérités d'un parent borné (élément de liste).
class PreviewImage extends StatelessWidget {
  const PreviewImage({
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.radius,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? url;
  final Widget fallback;
  final double? width;
  final double? height;

  /// Arrondi appliqué à l'image seule : le repli garde le sien.
  final BorderRadius? radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final src = url;
    if (src == null || src.isEmpty) {
      return SizedBox(width: width, height: height, child: fallback);
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final boxWidth = width ?? MediaQuery.sizeOf(context).width;
    final boxHeight = height ?? boxWidth;
    final decodeWidth = math.max(boxWidth, boxHeight * _ogAspect) * dpr;
    final clip = radius;

    return SizedBox(
      width: width,
      height: height,
      child: Image.network(
        src,
        fit: fit,
        cacheWidth: decodeWidth.ceil(),
        // Image décorative : le titre porte le sens.
        excludeFromSemantics: true,
        // `frame` est nul avant la première image décodée ; c'est plus sûr
        // que `loadingBuilder`, dont la progression est aussi nulle avant le
        // premier octet reçu (le cadre resterait vide un instant).
        frameBuilder: (_, child, frame, _) {
          final faded = AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: _fade,
            curve: Curves.easeOut,
            child: child,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              // Le repli reste sous l'image : aucun flash pendant le fondu,
              // et un fond teinté derrière les PNG transparents.
              fallback,
              if (clip == null)
                faded
              else
                ClipRRect(borderRadius: clip, child: faded),
            ],
          );
        },
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
