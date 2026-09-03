import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/knowledge.dart';

/// Ce qui a déclenché le paywall, pour adapter l'argument principal
/// (`09-produit/02-monetization-spec.md` §4).
enum PaywallTrigger { semanticSearch, dailyDigest, captureLimit, settings }

/// Bottom sheet d'abonnement.
///
/// Il ne remplace jamais l'écran : le contexte reste visible derrière
/// (wireframe 05 §Paywall), et il n'interrompt jamais une capture
/// (UX Bible règle 11).
///
/// L'UI réelle sera fournie par RevenueCat (`purchases_flutter`) ; les prix
/// affichés ici sont la proposition du Monetization Spec, encore à décider.
class PaywallSheet extends ConsumerWidget {
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
      builder: (_) => PaywallSheet(trigger: trigger),
    );
  }

  static const Map<PaywallTrigger, String> _headlines = {
    PaywallTrigger.semanticSearch:
        'Search by meaning, not by exact words',
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
  Widget build(BuildContext context, WidgetRef ref) {
    final ly = context.ly;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LySpace.xl,
        LySpace.s,
        LySpace.xl,
        LySpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LySpace.m,
                  vertical: LySpace.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: ly.primarySoft,
                  borderRadius: LyRadius.pillR,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LyIcons.sparkle, size: 14, color: ly.primary),
                    const SizedBox(width: LySpace.s),
                    Text(
                      'Lymarks Pro',
                      style: context.texts.labelSmall?.copyWith(
                        color: ly.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LySpace.l),
          Text(_headlines[trigger]!, style: context.texts.displaySmall),
          const SizedBox(height: LySpace.xl),
          for (var i = 0; i < _arguments.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: LySpace.l),
              child: _Argument(
                spec: _arguments[i],
                accent: ly.accents[i % ly.accents.length],
              ),
            ),
          const SizedBox(height: LySpace.s),
          const Row(
            children: [
              Expanded(
                child: _PriceOption(
                  label: 'Monthly',
                  price: '4,99 €',
                  caption: 'per month',
                ),
              ),
              SizedBox(width: LySpace.m),
              Expanded(
                child: _PriceOption(
                  label: 'Annual',
                  price: '39,99 €',
                  caption: 'per year · save 33%',
                  highlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: LySpace.l),
          FilledButton(
            onPressed: () {
              // Démo : en production, l'achat passe par RevenueCat et
              // l'entitlement est confirmé côté serveur par webhook.
              ref.read(profileProvider.notifier).setPlan(UserPlan.pro);
              Navigator.of(context).pop();
            },
            child: const Text('Continue'),
          ),
          const SizedBox(height: LySpace.s),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Restore my purchases'),
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
                style: context.texts.bodySmall
                    ?.copyWith(color: context.ly.textSecondary),
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
    this.highlighted = false,
  });

  final String label;
  final String price;
  final String caption;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    return Container(
      padding: const EdgeInsets.all(LySpace.l),
      decoration: BoxDecoration(
        color: highlighted ? ly.primarySoft : ly.card,
        borderRadius: LyRadius.cardR,
        border: Border.all(
          color: highlighted ? ly.primary : ly.cardBorder,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.texts.labelSmall),
          const SizedBox(height: LySpace.xs),
          Text(price, style: context.texts.titleLarge),
          const SizedBox(height: 2),
          Text(
            caption,
            style: context.texts.labelSmall?.copyWith(
              color: highlighted ? ly.primary : ly.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
