import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/features/category/category_path_screen.dart';
import 'package:lymarks/features/category/cluster_screen.dart';
import 'package:lymarks/features/detail/lymark_detail_screen.dart';
import 'package:lymarks/features/digest/digest_screen.dart';
import 'package:lymarks/features/home/home_screen.dart';
import 'package:lymarks/features/home/library_screen.dart';
import 'package:lymarks/features/onboarding/onboarding_screen.dart';
import 'package:lymarks/features/search/search_screen.dart';
import 'package:lymarks/features/settings/profile_screen.dart';
import 'package:lymarks/features/settings/settings_screen.dart';
import 'package:lymarks/shared/widgets/app_bottom_nav.dart';

/// Chemins nommés, pour éviter les chaînes littérales dans les écrans.
abstract final class LyRoute {
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String search = '/search';
  static const String digest = '/digest';
  static const String library = '/library';
  static const String settings = '/settings';
  static const String profile = '/profile';

  static String lymark(String id) => '/lymark/$id';
  static String category(String id) => '/category/$id';
  static String cluster(String categoryId, String clusterId) =>
      '/category/$categoryId/cluster/$clusterId';
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
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: LyRoute.onboarding,
    routes: [
      GoRoute(
        path: LyRoute.onboarding,
        builder: (_, _) => const OnboardingScreen(),
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
        routes: [
          GoRoute(
            path: 'cluster/:clusterId',
            builder: (_, state) => ClusterScreen(
              categoryId: state.pathParameters['id']!,
              clusterId: state.pathParameters['clusterId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: LyRoute.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: LyRoute.profile,
        builder: (_, _) => const ProfileScreen(),
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
