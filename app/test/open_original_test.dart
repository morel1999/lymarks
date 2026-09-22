import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lymarks/core/theme/app_theme.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/widgets/lymark_actions.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// « Open original » — le geste que l'utilisateur attend d'un bookmark.
///
/// Le bouton est resté un stub pendant toute la construction de l'app : ces
/// tests existent pour qu'il ne puisse plus redevenir muet sans qu'on le
/// sache.
class _FakeLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  _FakeLauncher({this.refuse = const {}});

  /// Modes que cet appareil ne sait pas honorer : `launchUrl` y lève, comme
  /// le plugin Android quand aucun navigateur compatible n'est installé.
  final Set<PreferredLaunchMode> refuse;

  final List<(String, PreferredLaunchMode)> calls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    calls.add((url, options.mode));
    if (refuse.contains(options.mode)) {
      throw PlatformException(code: 'NO_BROWSER');
    }
    return true;
  }
}

Lymark _lymark({String url = 'https://example.com/a'}) => Lymark(
  id: 'lm-1',
  url: url,
  domain: 'example.com',
  title: 'Une page',
  savedAt: DateTime(2026, 9),
);

/// Monte un bouton qui déclenche l'ouverture, avec de quoi afficher un
/// SnackBar — `openOriginal` a besoin d'un `ScaffoldMessenger`.
Future<void> _tapOpen(WidgetTester tester, Lymark lymark) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: LyTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => LymarkActions.openOriginal(context, lymark),
            child: const Text('Open original'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open original'));
  await tester.pumpAndSettle();
}

void main() {
  late _FakeLauncher launcher;

  setUp(() {
    launcher = _FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  group('Open original', () {
    testWidgets('le lien part dans le navigateur en surcouche', (tester) async {
      await _tapOpen(tester, _lymark());

      expect(launcher.calls, hasLength(1));
      expect(launcher.calls.single.$1, 'https://example.com/a');
      expect(launcher.calls.single.$2, PreferredLaunchMode.inAppBrowserView);
    });

    testWidgets('sans surcouche, l ouverture externe prend le relais', (
      tester,
    ) async {
      launcher = _FakeLauncher(
        refuse: const {PreferredLaunchMode.inAppBrowserView},
      );
      UrlLauncherPlatform.instance = launcher;

      await _tapOpen(tester, _lymark());

      expect(
        launcher.calls.map((c) => c.$2),
        [
          PreferredLaunchMode.inAppBrowserView,
          PreferredLaunchMode.externalApplication,
        ],
      );
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('aucun navigateur : l echec se dit, jamais un bouton muet', (
      tester,
    ) async {
      launcher = _FakeLauncher(
        refuse: const {
          PreferredLaunchMode.inAppBrowserView,
          PreferredLaunchMode.externalApplication,
        },
      );
      UrlLauncherPlatform.instance = launcher;

      await _tapOpen(tester, _lymark());

      expect(find.text("Couldn't open this link."), findsOneWidget);
    });

    testWidgets('un lien illisible ne declenche aucune ouverture', (
      tester,
    ) async {
      await _tapOpen(tester, _lymark(url: 'pas une adresse'));

      expect(launcher.calls, isEmpty);
      expect(find.text("This link can't be opened."), findsOneWidget);
    });
  });
}
