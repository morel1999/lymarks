import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';

/// Onboarding — deux écrans, pas un tutoriel (wireframe 01).
///
/// L'utilisateur doit comprendre trois choses : ses liens deviennent une
/// mémoire, la capture est rapide, Lymarks comprend le contenu tout seul.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Déjà connecté (retour dans l'app, mode démo) : droit à la Home ; sinon
  /// la connexion, dont le routeur ressort vers la Home une fois la session
  /// ouverte.
  void _finish() => context.go(
    ref.read(authSessionProvider).isSignedIn ? LyRoute.home : LyRoute.signIn,
  );

  void _next() {
    if (_index == 0) {
      unawaited(
        _pages.animateToPage(
          1,
          duration: LyMotion.list,
          curve: LyMotion.listCurve,
        ),
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.xl,
                LySpace.l,
                LySpace.l,
                0,
              ),
              child: Row(
                children: [
                  Text('Lymarks', style: context.texts.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: context.texts.labelMedium?.copyWith(
                        color: ly.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [_PromiseSlide(), _MechanismSlide()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.xl,
                0,
                LySpace.xl,
                LySpace.xl,
              ),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: _next,
                    child: Text(_index == 0 ? 'Get started' : 'Start saving'),
                  ),
                  const SizedBox(height: LySpace.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 2; i++)
                        AnimatedContainer(
                          duration: LyMotion.micro,
                          margin: const EdgeInsets.symmetric(
                            horizontal: LySpace.xs,
                          ),
                          width: i == _index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index ? ly.primary : ly.cardBorder,
                            borderRadius: LyRadius.pillR,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 01A — La promesse.
class _PromiseSlide extends StatelessWidget {
  const _PromiseSlide();

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LySpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          SizedBox(
            height: 240,
            child: Stack(
              children: [
                _FloatingShape(
                  accent: ly.lime,
                  size: 150,
                  left: 0,
                  top: 40,
                  icon: LyIcons.link,
                ),
                _FloatingShape(
                  accent: ly.steel,
                  size: 120,
                  left: 118,
                  top: 0,
                  icon: LyIcons.sparkle,
                ),
                _FloatingShape(
                  accent: ly.blue,
                  size: 104,
                  left: 150,
                  top: 128,
                  icon: LyIcons.search,
                ),
                _FloatingShape(
                  accent: ly.yellow,
                  size: 64,
                  left: 60,
                  top: 176,
                  icon: LyIcons.bookmark,
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Turn forgotten links\ninto active memory.',
            style: context.texts.displayLarge,
          ),
          const SizedBox(height: LySpace.l),
          Text(
            'Save what you discover.\nFind it when you need it.',
            style: context.texts.bodyLarge?.copyWith(color: ly.textSecondary),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// 01B — Le mécanisme : capture, compréhension, redécouverte.
class _MechanismSlide extends StatelessWidget {
  const _MechanismSlide();

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LySpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          _Step(
            accent: ly.blue,
            icon: LyIcons.link,
            title: 'A link you share',
            caption: 'One tap from any app.',
          ),
          _Connector(color: ly.cardBorder),
          _Step(
            accent: ly.steel,
            icon: LyIcons.sparkle,
            title: 'Lymarks reads it',
            caption: 'Summary and keywords, in the background.',
          ),
          _Connector(color: ly.cardBorder),
          _Step(
            accent: ly.lime,
            icon: LyIcons.note,
            title: 'Three things to remember',
            caption: 'The context you would have forgotten.',
          ),
          const Spacer(),
          Text(
            'Save once.\nLymarks remembers\nthe context.',
            style: context.texts.displayLarge,
          ),
          const SizedBox(height: LySpace.l),
          Text(
            'Capture → Understand → Rediscover',
            style: context.texts.bodyLarge?.copyWith(color: ly.textSecondary),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.accent,
    required this.icon,
    required this.title,
    required this.caption,
  });

  final LyAccent accent;
  final IconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: accent.fill,
            borderRadius: LyRadius.tileR,
          ),
          child: Icon(icon, size: 24, color: accent.onFill),
        ),
        const SizedBox(width: LySpace.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.texts.titleSmall),
              const SizedBox(height: 2),
              Text(
                caption,
                style: context.texts.bodySmall?.copyWith(
                  color: context.ly.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25),
      child: Container(width: 2, height: 22, color: color),
    );
  }
}

class _FloatingShape extends StatelessWidget {
  const _FloatingShape({
    required this.accent,
    required this.size,
    required this.left,
    required this.top,
    required this.icon,
  });

  final LyAccent accent;
  final double size;
  final double left;
  final double top;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.ly.lift(accent, 0.3), accent.fill],
          ),
        ),
        child: Icon(icon, size: size * 0.3, color: accent.onFill),
      ),
    );
  }
}
