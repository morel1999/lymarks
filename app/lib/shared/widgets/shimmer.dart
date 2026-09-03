import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';

/// Balayage lumineux de l'état `processing`.
///
/// Design System §Animations : boucle de 1,2 s. Le squelette « se remplit
/// seul » ; aucune notification n'accompagne la fin du traitement
/// (UX Bible règle 4).
class Shimmer extends StatefulWidget {
  const Shimmer({required this.child, super.key});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: LyMotion.shimmer,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value * 2 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(t - 0.6, 0),
            end: Alignment(t + 0.6, 0),
            colors: [
              ly.skeleton,
              ly.skeletonHighlight,
              ly.skeleton,
            ],
            stops: const [0.1, 0.5, 0.9],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Un bloc de squelette aux dimensions d'un futur texte.
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({
    required this.width,
    this.height = 12,
    super.key,
  });

  const SkeletonBar.line({double height = 12, Key? key})
      : this(width: double.infinity, height: height, key: key);

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.ly.skeleton,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
