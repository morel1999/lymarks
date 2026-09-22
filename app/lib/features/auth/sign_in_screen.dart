import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/core/config/app_config.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/shared/widgets/mascot.dart';

/// Connexion (F5) : Google et e-mail via Clerk.
///
/// L'interface de saisie est celle du SDK Clerk (`ClerkAuthentication`) : les
/// stratégies affichées sont celles activées dans le dashboard, aucune n'est
/// codée ici. Une fois la session ouverte, le routeur redirige vers la Home
/// tout seul (`buildRouter`, garde d'authentification).
///
/// En mode démo il n'y a pas de SDK : un bouton ouvre une session factice.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Deux compositions, parce que les deux panneaux n'ont pas le même
    // appétit. Le SDK Clerk amène ses propres champs et doit défiler : le
    // bloc d'accueil se fait compact au-dessus. Le mode démo n'a qu'un
    // bouton : l'accueil prend alors toute la place et se centre, au lieu de
    // laisser un trou entre un titre colle en haut et un bouton colle en bas.
    return Scaffold(
      body: SafeArea(
        child: AppConfig.isLive
            ? const Column(
                children: [
                  _Welcome(compact: true),
                  Expanded(child: _ClerkPanel()),
                ],
              )
            : Column(
                children: [
                  const Expanded(child: Center(child: _Welcome())),
                  _DemoPanel(
                    onContinue: () {
                      final auth = ref.read(authSessionProvider);
                      if (auth is DemoAuthSession) auth.signIn();
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

/// L'accueil : la mascotte, la promesse, et rien d'autre.
///
/// Tout est centré. La version précédente alignait les textes à gauche et
/// posait la mascotte dans un `Center` au milieu de cette colonne : elle
/// flottait seule pendant que le reste collait au bord.
class _Welcome extends StatelessWidget {
  const _Welcome({this.compact = false});

  /// Au-dessus du panneau Clerk, qui a besoin de la hauteur restante.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        LySpace.xl,
        compact ? LySpace.l : 0,
        LySpace.xl,
        compact ? LySpace.m : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Première rencontre : elle salue, elle ne vend rien.
          MascotFigure(
            pose: MascotPose.waving,
            height: compact ? 108 : 148,
          ),
          SizedBox(height: compact ? LySpace.m : LySpace.xl),
          Text(
            'Sign in to sync\nyour memory.',
            style: compact
                ? context.texts.displaySmall
                : context.texts.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LySpace.s),
          Text(
            'Your lymarks follow you on every device.',
            style: context.texts.bodyLarge?.copyWith(color: ly.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Panneau Clerk, thémé aux couleurs de l'app.
class _ClerkPanel extends StatelessWidget {
  const _ClerkPanel();

  @override
  Widget build(BuildContext context) {
    return ClerkErrorListener(
      // `message` est un gabarit (« {arg} (ERROR RECEIVED FROM SERVER) ») :
      // le texte utile est le message serveur, sinon le gabarit résolu.
      handler: (context, error) {
        final text = error.errors?.errorMessage ?? error.toString();
        debugPrint('[lymarks/auth] clerk ${error.code.name}: $text');
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(text),
              duration: const Duration(seconds: 6),
            ),
          );
      },
      child: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: LySpace.m,
          vertical: LySpace.s,
        ),
        child: ClerkAuthentication(),
      ),
    );
  }
}

class _DemoPanel extends StatelessWidget {
  const _DemoPanel({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LySpace.xl,
        0,
        LySpace.xl,
        LySpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              child: const Text('Continue in demo mode'),
            ),
          ),
          const SizedBox(height: LySpace.m),
          Text(
            'No account service configured for this build.',
            style: context.texts.bodySmall?.copyWith(color: ly.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
