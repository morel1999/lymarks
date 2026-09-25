import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lymarks/core/auth/auth_session.dart';
import 'package:lymarks/core/billing/billing.dart';
import 'package:lymarks/core/billing/billing_link.dart';
import 'package:lymarks/core/theme/app_theme.dart';
import 'package:lymarks/shared/data/mock_repository.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/models/lymark.dart';
import 'package:lymarks/shared/widgets/paywall_sheet.dart';

/// Store de test : offre fixée, achats journalisés, issue pilotable.
class FakeBilling implements Billing {
  FakeBilling({
    this.available = true,
    this.offerToReturn = ProOffer.preview,
    this.outcome = PurchaseOutcome.purchased,
    this.restoresPro = false,
  });

  bool available;
  ProOffer? offerToReturn;
  PurchaseOutcome outcome;
  bool restoresPro;

  final List<String> identified = [];
  int forgotten = 0;
  final List<String> purchased = [];
  int restored = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<void> identify(String appUserId) async => identified.add(appUserId);

  @override
  Future<void> forget() async => forgotten += 1;

  @override
  Future<ProOffer?> offer() async => offerToReturn;

  @override
  Future<PurchaseOutcome> purchase(ProPackage package) async {
    purchased.add(package.id);
    return outcome;
  }

  @override
  Future<bool> restore() async {
    restored += 1;
    return restoresPro;
  }

  @override
  Future<Uri?> managementUrl() async => management;

  /// Adresse de gestion rendue par le store, quand il y en a une.
  Uri? management;
}

void main() {
  group('ProOffer', () {
    test('mensuel, annuel et économie de la proposition', () {
      const o = ProOffer.preview;
      expect(o.monthly?.id, 'preview_monthly');
      expect(o.annual?.id, 'preview_annual');
      // 39,99 contre 12 × 4,99 = 59,88 → 33 %.
      expect(o.annualSavingsPercent, 33);
    });

    test("pas d'économie affichée si l'annuel ne fait pas gagner", () {
      const o = ProOffer([
        ProPackage(
          id: 'm',
          period: ProPeriod.monthly,
          priceString: '1',
          price: 1,
        ),
        ProPackage(
          id: 'a',
          period: ProPeriod.annual,
          priceString: '12',
          price: 12,
        ),
      ]);
      expect(o.annualSavingsPercent, isNull);
      expect(const ProOffer([]).annualSavingsPercent, isNull);
      expect(const ProOffer([]).monthly, isNull);
    });
  });

  group('BillingLink', () {
    test('rattache à la connexion, détache à la déconnexion, '
        'une fois', () async {
      final billing = FakeBilling();
      final session = DemoAuthSession(signedIn: false);
      final link = BillingLink(billing, session);
      await Future<void>.delayed(Duration.zero);
      expect(billing.identified, isEmpty);
      // Déjà déconnecté au départ : rien à détacher.
      expect(billing.forgotten, 0);

      // Notification redondante : un seul rattachement.
      session
        ..signIn()
        ..signIn();
      await Future<void>.delayed(Duration.zero);
      expect(billing.identified, ['demo-user']);

      await session.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(billing.forgotten, 1);
      link.dispose();
    });
  });

  group('PaywallSheet', () {
    Future<FakeBilling> pump(
      WidgetTester tester, {
      required FakeBilling billing,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [billingProvider.overrideWithValue(billing)],
          child: MaterialApp(
            theme: LyTheme.light(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => PaywallSheet.show(
                      context,
                      trigger: PaywallTrigger.semanticSearch,
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return billing;
    }

    testWidgets('prix du store, annuel choisi par défaut, achat → Pro', (
      tester,
    ) async {
      final billing = await pump(
        tester,
        billing: FakeBilling(
          offerToReturn: const ProOffer([
            ProPackage(
              id: r'$rc_monthly',
              period: ProPeriod.monthly,
              priceString: r'$4.99',
              price: 4.99,
            ),
            ProPackage(
              id: r'$rc_annual',
              period: ProPeriod.annual,
              priceString: r'$39.99',
              price: 39.99,
            ),
          ]),
        ),
      );
      expect(find.text(r'$4.99'), findsOneWidget);
      expect(find.text(r'$39.99'), findsOneWidget);
      expect(find.text('per year · save 33%'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(billing.purchased, [r'$rc_annual']);
      expect(find.text('Welcome to Lymarks Pro.'), findsOneWidget);
      expect(find.byType(PaywallSheet), findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      expect(container.read(profileProvider).plan, UserPlan.pro);
    });

    testWidgets('mensuel sélectionnable ; annulation sans message', (
      tester,
    ) async {
      final billing = await pump(
        tester,
        billing: FakeBilling(outcome: PurchaseOutcome.cancelled),
      );
      await tester.tap(find.text('Monthly'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(billing.purchased, ['preview_monthly']);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(PaywallSheet), findsOneWidget);
    });

    testWidgets('échec du store : message, feuille ouverte, plan inchangé', (
      tester,
    ) async {
      await pump(tester, billing: FakeBilling(outcome: PurchaseOutcome.failed));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      container.read(profileProvider.notifier).setPlan(UserPlan.free);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nothing was charged'), findsOneWidget);
      expect(find.byType(PaywallSheet), findsOneWidget);
      expect(container.read(profileProvider).plan, UserPlan.free);
    });

    testWidgets('restauration : Pro retrouvé ou rien à restaurer', (
      tester,
    ) async {
      final billing = await pump(tester, billing: FakeBilling());
      await tester.ensureVisible(find.text('Restore my purchases'));
      await tester.tap(find.text('Restore my purchases'));
      await tester.pumpAndSettle();
      expect(billing.restored, 1);
      expect(find.text('No purchase to restore.'), findsOneWidget);

      // Le premier message doit s'effacer avant que le second s'affiche.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      billing.restoresPro = true;
      await tester.tap(find.text('Restore my purchases'));
      await tester.pumpAndSettle();
      expect(find.text('Lymarks Pro restored.'), findsOneWidget);
      expect(find.byType(PaywallSheet), findsNothing);
    });

    testWidgets('store branché mais sans offre : bouton désactivé', (
      tester,
    ) async {
      await pump(tester, billing: FakeBilling(offerToReturn: null));
      expect(find.textContaining('not reachable'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('démo (aucun store) : proposition affichée, bascule locale', (
      tester,
    ) async {
      final billing = await pump(
        tester,
        billing: FakeBilling(available: false),
      );
      expect(find.text('4,99 €'), findsOneWidget);
      expect(find.text('39,99 €'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(billing.purchased, isEmpty);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      expect(container.read(profileProvider).plan, UserPlan.pro);
    });
  });
  // Sans serveur, personne n'appliquait le plafond : `locked` n'arrive
  // normalement que du JSON de l'API. La demo affichait donc un compte Pro
  // sans rien de garde — c'est-a-dire sans rien de ce que le produit a de
  // particulier, et sans moyen d'atteindre le paywall.
  group('Mode demo : Free, puis Pro', () {
    test('les plus recents restent ouverts, le reste est garde', () async {
      final repo = MockLymarksRepository(isPro: false, simulatesServer: true);
      final items = await repo.fetchAll();
      final vivants = [
        for (final l in items)
          if (!l.archived) l,
      ];
      final ouverts = [
        for (final l in vivants)
          if (!l.locked) l,
      ];

      expect(ouverts, hasLength(UserProfile.freeLimit));
      expect(vivants.length, greaterThan(ouverts.length));
      // Les fermes sont les plus recents : le plafond se pose a la capture.
      final dernierOuvert = ouverts
          .map((l) => l.savedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      for (final l in vivants.where((l) => l.locked)) {
        expect(l.savedAt.isAfter(dernierOuvert), isTrue, reason: l.id);
      }
      // Et ils n'ont jamais traverse le pipeline : rien a montrer.
      for (final l in vivants.where((l) => l.locked)) {
        expect(l.bullets, isEmpty, reason: l.id);
        expect(l.keywords, isEmpty, reason: l.id);
      }
      // Et plus aucune carte ne charge indefiniment.
      expect(items.where((l) => l.status == LymarkStatus.processing), isEmpty);
    });

    test('les rendus de reference ne subissent pas ce plafond', () async {
      final items = await MockLymarksRepository().fetchAll();

      expect(items.where((l) => l.locked), isEmpty);
      // L'etat `processing` reste visible pour qui veut le rendre.
      expect(
        items.where((l) => l.status == LymarkStatus.processing),
        isNotEmpty,
      );
    });

    test('l achat simule ouvre les cartes gardees', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(lymarksProvider.notifier).refresh();
      final gardes = {
        for (final l in c.read(lymarksProvider))
          if (l.locked) l.id,
      };
      expect(gardes, isNotEmpty);

      await c.read(profileProvider.notifier).grantProInDemo();

      final apres = c.read(lymarksProvider);
      expect(apres.where((l) => l.locked), isEmpty);
      expect(c.read(profileProvider).plan, UserPlan.pro);

      // Et elles ne s'ouvrent pas vides : le resume revient. Le serveur fait
      // la meme chose pour une autre raison — il lance le pipeline au
      // deverrouillage, puisqu'il ne l'avait pas paye. Ici le texte etait
      // deja ecrit, il reparait. (La carte en echec n'a jamais eu de puces :
      // on ne juge que celles qui sont pretes.)
      final rouvertes = [
        for (final l in apres)
          if (gardes.contains(l.id) && l.status == LymarkStatus.ready) l,
      ];
      expect(rouvertes, isNotEmpty);
      for (final l in rouvertes) {
        expect(l.bullets, isNotEmpty, reason: l.id);
        expect(l.keywords, isNotEmpty, reason: l.id);
      }
    });
  });
}
