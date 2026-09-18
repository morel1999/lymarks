import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/core/config/app_config.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';

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
    final ly = context.ly;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.xl,
                LySpace.l,
                LySpace.xl,
                LySpace.m,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lymarks', style: context.texts.titleLarge),
                  const SizedBox(height: LySpace.l),
                  Text(
                    'Sign in to sync\nyour memory.',
                    style: context.texts.displayLarge,
                  ),
                  const SizedBox(height: LySpace.s),
                  Text(
                    'Your lymarks follow you on every device.',
                    style: context.texts.bodyLarge?.copyWith(
                      color: ly.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AppConfig.isLive
                  ? const _ClerkPanel()
                  : _DemoPanel(
                      onContinue: () {
                        final auth = ref.read(authSessionProvider);
                        if (auth is DemoAuthSession) auth.signIn();
                      },
                    ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(LySpace.xl),
      child: Column(
        children: [
          const Spacer(),
          FilledButton(
            onPressed: onContinue,
            child: const Text('Continue in demo mode'),
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
