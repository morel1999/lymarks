import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/core/utils/relative_time.dart';
import 'package:lymarks/features/home/home_screen.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/widgets/ly_card.dart';
import 'package:lymarks/shared/widgets/paywall_sheet.dart';
import 'package:lymarks/shared/widgets/section_header.dart';
import 'package:lymarks/shared/widgets/settings_tile.dart';

/// Compte — sous-page utilitaire des réglages (wireframe 07 §Account).
///
/// Les statistiques restent factuelles. Aucune série de jours, aucun badge :
/// l'UX Bible interdit la gamification (§Ton), donc le « 7 day streak » de la
/// maquette n'est pas repris.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ly = context.ly;
    final profile = ref.watch(profileProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LyScreenHeader(
              title: 'Profile',
              subtitle: 'Manage your account and preferences',
              onBack: () => context.pop(),
              trailing: LyCircleButton(
                icon: LyIcons.settings,
                tooltip: 'Settings',
                onTap: () => context.push(LyRoute.settings),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              LySpace.screen,
              0,
              LySpace.screen,
              LySpace.xxl,
            ),
            sliver: SliverList.list(
              children: [
                _IdentityCard(profile: profile),
                const SizedBox(height: LySpace.l),
                _StatsRow(profile: profile),
                const SizedBox(height: LySpace.l),
                _PlanBanner(profile: profile),

                const SettingsGroupLabel('Your memory'),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: LyIcons.bookmark,
                      accent: ly.lavender,
                      title: 'All Lymarks',
                      subtitle: 'Browse everything you saved',
                      onTap: () => context.push(LyRoute.library),
                    ),
                    SettingsTile(
                      icon: LyIcons.tag,
                      accent: ly.lime,
                      title: 'Tags',
                      subtitle: 'Generated from what you save',
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: LyIcons.digest,
                      accent: ly.blue,
                      title: 'Daily Digest',
                      subtitle: 'What comes back, and when',
                      onTap: () => context.push(LyRoute.digest),
                    ),
                  ],
                ),

                const SettingsGroupLabel('Account'),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: LyIcons.security,
                      accent: ly.lavender,
                      title: 'Security',
                      subtitle: 'Sign-in methods and sessions',
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: LyIcons.billing,
                      accent: ly.yellow,
                      title: 'Billing & subscription',
                      subtitle: profile.isPro ? 'Pro · annual' : 'Free plan',
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: LyIcons.settings,
                      accent: ly.pink,
                      title: 'All settings',
                      onTap: () => context.push(LyRoute.settings),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Container(
      padding: const EdgeInsets.all(LySpace.xl),
      decoration: BoxDecoration(
        borderRadius: LyRadius.heroR,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ly.lavender.fill, ly.lift(ly.blue, 0.16)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ly.card,
              shape: BoxShape.circle,
            ),
            child: Text(
              profile.initials,
              style: context.texts.displaySmall?.copyWith(
                color: ly.lavender.strong,
              ),
            ),
          ),
          const SizedBox(width: LySpace.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: context.texts.titleLarge?.copyWith(
                    color: ly.lavender.onFill,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email,
                  style: context.texts.bodySmall?.copyWith(
                    color: ly.lavender.onFill.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: LySpace.m),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LySpace.m,
                    vertical: LySpace.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: ly.card,
                    borderRadius: LyRadius.pillR,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LyIcons.sparkle, size: 13, color: ly.primary),
                      const SizedBox(width: LySpace.s),
                      Text(
                        profile.isPro ? 'Pro plan' : 'Free plan',
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
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ly = context.ly;
    final now = ref.watch(clockProvider)();

    return Row(
      children: [
        Expanded(
          child: _Stat(
            icon: LyIcons.bookmark,
            accent: ly.lime,
            value: '${profile.lymarkCount}',
            label: 'Lymarks',
          ),
        ),
        const SizedBox(width: LySpace.m),
        Expanded(
          child: _Stat(
            icon: LyIcons.note,
            accent: ly.yellow,
            value: '${profile.noteCount}',
            label: 'Notes',
          ),
        ),
        const SizedBox(width: LySpace.m),
        Expanded(
          child: _Stat(
            icon: LyIcons.calendar,
            accent: ly.blue,
            value: LyTime.relative(
              profile.memberSince,
              now: now,
            ).replaceAll(' ago', ''),
            label: 'With Lymarks',
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final LyAccent accent;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return LyCard(
      padding: const EdgeInsets.all(LySpace.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.fill,
              borderRadius: LyRadius.tileR,
            ),
            child: Icon(icon, size: 16, color: accent.onFill),
          ),
          const SizedBox(height: LySpace.m),
          Text(
            value,
            style: context.texts.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: context.texts.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PlanBanner extends ConsumerWidget {
  const _PlanBanner({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ly = context.ly;
    final accent = profile.isPro ? ly.lime : ly.yellow;

    return LyCard(
      color: accent.fill,
      borderColor: accent.fill,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ly.badgeInk,
              borderRadius: LyRadius.tileR,
            ),
            child: Icon(LyIcons.sparkle, size: 20, color: accent.strong),
          ),
          const SizedBox(width: LySpace.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.isPro ? "You're on Pro" : 'You are on the free plan',
                  style: context.texts.titleSmall?.copyWith(
                    color: accent.onFill,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.isPro
                      ? 'Thanks for supporting Lymarks.'
                      : '${UserProfile.freeLimit} lymarks, keyword search.',
                  style: context.texts.bodySmall?.copyWith(
                    color: accent.onFill.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LySpace.s),
          // Bascule du plan : présente uniquement pour éprouver le paywall
          // tant que RevenueCat n'est pas branché.
          FilledButton(
            onPressed: () {
              if (profile.isPro) {
                ref.read(profileProvider.notifier).setPlan(UserPlan.free);
              } else {
                unawaited(
                  PaywallSheet.show(
                    context,
                    trigger: PaywallTrigger.settings,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: ly.card,
              foregroundColor: accent.onFill,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: LySpace.l),
              textStyle: context.texts.labelMedium,
            ),
            child: Text(profile.isPro ? 'Manage' : 'Upgrade'),
          ),
        ],
      ),
    );
  }
}
