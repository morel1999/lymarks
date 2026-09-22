import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/features/auth/sign_in_screen.dart';
import 'package:lymarks/features/category/category_path_screen.dart';
import 'package:lymarks/features/detail/lymark_detail_screen.dart';
import 'package:lymarks/features/digest/digest_screen.dart';
import 'package:lymarks/features/home/home_screen.dart';
import 'package:lymarks/features/home/library_screen.dart';
import 'package:lymarks/features/onboarding/onboarding_screen.dart';
import 'package:lymarks/features/search/search_screen.dart';
import 'package:lymarks/features/settings/legal_content.dart';
import 'package:lymarks/features/settings/legal_screen.dart';
import 'package:lymarks/features/settings/profile_screen.dart';
import 'package:lymarks/features/settings/settings_screen.dart';
import 'package:lymarks/features/splash/splash_screen.dart';
import 'package:lymarks/shared/widgets/app_bottom_nav.dart';

/// Chemins nommés, pour éviter les chaînes littérales dans les écrans.
abstract final class LyRoute {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String home = '/home';
  static const String search = '/search';
  static const String digest = '/digest';
  static const String library = '/library';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String privacy = '/privacy';
  static const String terms = '/terms';

  static String lymark(String id) => '/lymark/$id';
  static String category(String id) => '/category/$id';
}

/// Navigation de l'application.
///
/// Trois onglets persistants (Home / Search / Digest) via
/// [StatefulShellRoute] : chaque onglet garde sa pile, son scroll et sa
/// requête, ce qui implémente la règle 10 de l'UX Bible (« toujours revenir à
/// l'endroit exact »).
///
/// Category Path, Lymark Detail et Settings sont **au-dessus** de la coquille,
/// donc sans barre d'onglets : ce sont des parcours secondaires
/// (wireframes 03, 04, 07 et §9 Navigation globale).
///
/// Garde d'authentification : tout ce qui n'est ni l'onboarding ni la
/// connexion exige une session (F5). Le routeur écoute [auth] et réévalue la
/// redirection à chaque connexion ou déconnexion.
GoRouter buildRouter({required AuthSession auth}) {
  return GoRouter(
    initialLocation: LyRoute.splash,
    refreshListenable: auth,
    redirect: (_, state) {
      final path = state.matchedLocation;
      final public =
          path == LyRoute.splash ||
          path == LyRoute.onboarding ||
          path == LyRoute.signIn;
      if (!auth.isSignedIn && !public) return LyRoute.signIn;
      if (auth.isSignedIn && path == LyRoute.signIn) return LyRoute.home;
      return null;
    },
    routes: [
      GoRoute(
        path: LyRoute.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: LyRoute.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: LyRoute.signIn,
        builder: (_, _) => const SignInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _ShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: LyRoute.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: LyRoute.search,
                builder: (_, _) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: LyRoute.digest,
                builder: (_, _) => const DigestScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: LyRoute.library,
        builder: (_, _) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/lymark/:id',
        builder: (_, state) =>
            LymarkDetailScreen(lymarkId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/category/:id',
        builder: (_, state) =>
            CategoryPathScreen(categoryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: LyRoute.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: LyRoute.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: LyRoute.privacy,
        builder: (_, _) => LegalScreen(page: LegalTexts.privacy),
      ),
      GoRoute(
        path: LyRoute.terms,
        builder: (_, _) => LegalScreen(page: LegalTexts.terms),
      ),
    ],
  );
}

/// Coquille des trois onglets principaux.
class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      extendBody: true,
      bottomNavigationBar: AppBottomNav(
        current: LyTab.values[shell.currentIndex],
        onSelect: (tab) => shell.goBranch(
          tab.index,
          initialLocation: tab.index == shell.currentIndex,
        ),
      ),
    );
  }
}
