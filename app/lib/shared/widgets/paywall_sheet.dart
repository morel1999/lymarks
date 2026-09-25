import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/core/billing/billing.dart';
import 'package:lymarks/core/config/app_config.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/widgets/mascot.dart';

/// Ce qui a déclenché le paywall, pour adapter l'argument principal
/// (`09-produit/02-monetization-spec.md` §4).
enum PaywallTrigger { semanticSearch, dailyDigest, captureLimit, settings }

/// Bottom sheet d'abonnement.
///
/// Il ne remplace jamais l'écran : le contexte reste visible derrière
/// (wireframe 05 §Paywall), et il n'interrompt jamais une capture
/// (UX Bible règle 11).
///
/// Les forfaits et leurs prix viennent du store (RevenueCat, ADR-006) ; en
/// démo, la proposition du Monetization Spec. L'achat passe par le store, le
/// droit Pro est confirmé par le serveur (webhook) — voir `ProfileNotifier`.
class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet({required this.trigger, super.key});

  final PaywallTrigger trigger;

  static Future<void> show(
    BuildContext context, {
    required PaywallTrigger trigger,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // La poignée du thème est grise : elle se perdrait sur le bandeau
      // sombre. Le bandeau dessine la sienne, en clair.
      showDragHandle: false,
      builder: (_) => PaywallSheet(trigger: trigger),
    );
  }

  static const Map<PaywallTrigger, String> _headlines = {
    PaywallTrigger.semanticSearch: 'Search by meaning, not by exact words',
    PaywallTrigger.dailyDigest: 'Let one good link come back to you',
    PaywallTrigger.captureLimit: 'Keep saving without a ceiling',
    PaywallTrigger.settings: 'Everything Lymarks can remember',
  };

  static const List<({IconData icon, String title, String body})> _arguments = [
    (
      icon: LyIcons.sparkle,
      title: 'Semantic search',
      body: 'Describe what you remember. Lymarks finds it anyway.',
    ),
    (
      icon: LyIcons.digest,
      title: 'Daily Digest',
      body: 'One forgotten link a day, at the hour you choose. Never two.',
    ),
    (
      icon: LyIcons.bookmark,
      title: 'Unlimited lymarks',
      body: 'Past the 30 of the free plan, plus full JSON export.',
    ),
  ];

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  /// L'annuel est mis en avant (Monetization Spec §1).
  ProPeriod _selected = ProPeriod.annual;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final billing = ref.watch(billingProvider);
    final offerAsync = ref.watch(proOfferProvider);
    // Sans store : la démo montre la proposition, le mode réel dit qu'il n'y
    // a rien à acheter dans ce build.
    final offer = billing.isAvailable
        ? offerAsync.valueOrNull
        : (AppConfig.isDemo ? ProOffer.preview : null);
    final loading = billing.isAvailable && offerAsync.isLoading;
    final monthly = offer?.monthly;
    final annual = offer?.annual;
    final selected = switch (_selected) {
      ProPeriod.monthly => monthly ?? annual,
      ProPeriod.annual => annual ?? monthly,
    };
    final savings = offer?.annualSavingsPercent;

    // Défilant : sur un petit écran (ou clavier ouvert) la feuille ne déborde
    // pas, elle se laisse faire défiler jusqu'au bouton de restauration.
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProHeader(headline: PaywallSheet._headlines[widget.trigger]!),
          const SizedBox(height: LySpace.xl),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LySpace.xl,
              0,
              LySpace.xl,
              LySpace.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < PaywallSheet._arguments.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: LySpace.l),
                    child: _Argument(
                      spec: PaywallSheet._arguments[i],
                      accent: ly.accents[i % ly.accents.length],
                    ),
                  ),
                const SizedBox(height: LySpace.s),
                if (offer != null || loading)
                  Row(
                    children: [
                      Expanded(
                        child: _PriceOption(
                          label: 'Monthly',
                          price: monthly?.priceString ?? '—',
                          caption: 'per month',
                          selected: selected != null && selected == monthly,
                          onTap: monthly == null || _busy
                              ? null
                              : () => setState(
                                  () => _selected = ProPeriod.monthly,
                                ),
                        ),
                      ),
                      const SizedBox(width: LySpace.m),
                      Expanded(
                        child: _PriceOption(
                          label: 'Annual',
                          price: annual?.priceString ?? '—',
                          caption: savings == null
                              ? 'per year'
                              : 'per year · save $savings%',
                          selected: selected != null && selected == annual,
                          onTap: annual == null || _busy
                              ? null
                              : () => setState(
                                  () => _selected = ProPeriod.annual,
                                ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    billing.isAvailable
                        ? 'The store is not reachable right now. '
                              'Try again later.'
                        : 'Purchases are not available in this build.',
                    style: context.texts.bodySmall?.copyWith(
                      color: ly.textSecondary,
                    ),
                  ),
                const SizedBox(height: LySpace.l),
                FilledButton(
                  onPressed: selected == null || _busy
                      ? null
                      : () => _purchase(selected),
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
                const SizedBox(height: LySpace.s),
                Center(
                  child: TextButton(
                    onPressed:
                        _busy || (!billing.isAvailable && !AppConfig.isDemo)
                        ? null
                        : _restore,
                    child: const Text('Restore my purchases'),
                  ),
                ),
                if (offer != null)
                  Text(
                    'Renews automatically until cancelled from your '
                    'store account.',
                    textAlign: TextAlign.center,
                    style: context.texts.labelSmall?.copyWith(
                      color: ly.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchase(ProPackage package) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final profile = ref.read(profileProvider.notifier);

    // Démo : pas de store. Le plan bascule localement, et la bibliothèque
    // est relue pour que les cartes gardées s'ouvrent — le même message
    // qu'en mode réel, parce que c'est la même chose qui vient de se passer.
    if (!ref.read(billingProvider).isAvailable) {
      navigator.pop();
      await profile.grantProInDemo();
      messenger.showSnackBar(
        const SnackBar(content: Text('Welcome to Lymarks Pro.')),
      );
      return;
    }

    setState(() => _busy = true);
    final outcome = await profile.purchase(package);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PurchaseOutcome.purchased:
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Welcome to Lymarks Pro.')),
        );
      case PurchaseOutcome.pending:
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Payment pending. Pro unlocks once it clears.'),
          ),
        );
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.failed:
      case PurchaseOutcome.unavailable:
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'The purchase did not go through. Nothing was charged.',
            ),
          ),
        );
    }
  }

  Future<void> _restore() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final profile = ref.read(profileProvider.notifier);

    if (!ref.read(billingProvider).isAvailable) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No purchase to restore.')),
      );
      return;
    }

    setState(() => _busy = true);
    final pro = await profile.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (pro) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Lymarks Pro restored.')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('No purchase to restore.')),
      );
    }
  }
}

/// Le bandeau du paywall.
///
/// C'est lui qui fait la différence entre une liste d'arguments et un
/// moment : le dégradé de la marque, la mascotte, et le nom de l'offre.
/// Le reste de la feuille reste clair et sobre — un dégradé derrière du
/// texte long se paierait en lisibilité, et la règle est la même partout,
/// 4,5:1 minimum pour du texte courant.
///
/// La mascotte est un **décor** : elle déborde du cadre, elle passe sous un
/// voile, et elle ne porte aucune information. C'est pour ça qu'elle est
/// masquée aux lecteurs d'écran.
class _ProHeader extends StatelessWidget {
  const _ProHeader({required this.headline});

  final String headline;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: ly.primaryGradient),
        child: Stack(
          children: [
            // Posée assez bas pour que le bord haut du bandeau ne lui coupe
            // pas la tête : une mascotte décapitée se lit comme un accident
            // de cadrage, pas comme un décor.
            const Positioned(
              right: -18,
              bottom: -26,
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: 0.32,
                  child: MascotFigure(
                    pose: MascotPose.waving,
                    height: 152,
                    glow: false,
                  ),
                ),
              ),
            ),
            // Le voile. Opaque sous la colonne de texte, transparent sur la
            // droite où la mascotte doit rester visible : le contraste du
            // titre ne dépend donc pas de ce qui est dessiné derrière lui.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    stops: const [0.45, 1],
                    colors: [
                      ly.gradientTop,
                      ly.gradientTop.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LySpace.xl,
                LySpace.m,
                LySpace.xl,
                LySpace.xxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poignée de la feuille, redessinée en clair : celle du
                  // thème est grise et se perdrait sur ce fond.
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: LyRadius.pillR,
                      ),
                    ),
                  ),
                  const SizedBox(height: LySpace.xl),
                  const _ProBadge(),
                  const SizedBox(height: LySpace.l),
                  // Bornée : le titre ne court pas sous la mascotte.
                  FractionallySizedBox(
                    widthFactor: 0.78,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      headline,
                      style: context.texts.displaySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
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

/// La pastille de l'offre payante.
///
/// Chrome sur bleu nuit : c'est la seule surface métallique de l'app, et
/// elle ne ressemble à aucun accent de couleur — un accent dirait « une
/// catégorie », le chrome dit « une autre nature de chose ».
class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LySpace.m,
        vertical: LySpace.xs + 2,
      ),
      decoration: BoxDecoration(
        gradient: ly.chromeGradient,
        borderRadius: LyRadius.pillR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LyIcons.pro, size: 14, color: ly.gradientTop),
          const SizedBox(width: LySpace.s),
          Text(
            'Lymarks Pro',
            style: context.texts.labelSmall?.copyWith(
              color: ly.gradientTop,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Argument extends StatelessWidget {
  const _Argument({required this.spec, required this.accent});

  final ({IconData icon, String title, String body}) spec;
  final LyAccent accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.fill,
            borderRadius: LyRadius.tileR,
          ),
          child: Icon(spec.icon, size: 20, color: accent.onFill),
        ),
        const SizedBox(width: LySpace.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(spec.title, style: context.texts.titleSmall),
              const SizedBox(height: 2),
              Text(
                spec.body,
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

class _PriceOption extends StatelessWidget {
  const _PriceOption({
    required this.label,
    required this.price,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String price;
  final String caption;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: LyRadius.cardR,
        child: Container(
          padding: const EdgeInsets.all(LySpace.l),
          decoration: BoxDecoration(
            color: selected ? ly.primarySoft : ly.card,
            borderRadius: LyRadius.cardR,
            border: Border.all(
              color: selected ? ly.primary : ly.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: context.texts.labelSmall)),
                  // La sélection ne tient pas qu'à la couleur : un daltonien
                  // verrait deux cartes identiques. La coche la dit en forme.
                  if (selected)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: ly.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LyIcons.check,
                        size: 12,
                        color: ly.onPrimary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: LySpace.xs),
              Text(price, style: context.texts.titleLarge),
              const SizedBox(height: 2),
              Text(
                caption,
                style: context.texts.labelSmall?.copyWith(
                  color: selected ? ly.primary : ly.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
