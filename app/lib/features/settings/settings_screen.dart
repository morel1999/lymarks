import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lymarks/core/router/app_router.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/features/home/home_screen.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/widgets/ly_card.dart';
import 'package:lymarks/shared/widgets/paywall_sheet.dart';
import 'package:lymarks/shared/widgets/section_header.dart';
import 'package:lymarks/shared/widgets/settings_tile.dart';

/// 07 — Settings / Account.
///
/// Une zone utilitaire, pas une seconde application (wireframe 07 §Objectif).
/// Chaque rubrique porte sa couleur : les réglages restent lisibles d'un coup
/// d'œil sans devenir un tableau de bord.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ly = context.ly;
    final profile = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LyScreenHeader(
              title: 'Settings',
              onBack: () => context.pop(),
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
                const SettingsGroupLabel('Account'),
                _AccountRow(profile: profile),

                const SettingsGroupLabel('Plan'),
                _PlanCard(profile: profile),

                const SettingsGroupLabel('Preferences'),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: LyIcons.digest,
                      accent: ly.lime,
                      title: 'Daily Digest',
                      subtitle: profile.isPro
                          ? 'One link a day, at 8:30'
                          : 'Pro feature',
                      onTap: () => _DigestSheet.show(context, ref),
                    ),
                    SettingsTile(
                      icon: LyIcons.appearance,
                      accent: ly.lavender,
                      title: 'Appearance',
                      subtitle: switch (themeMode) {
                        ThemeMode.light => 'Light',
                        ThemeMode.dark => 'Dark',
                        ThemeMode.system => 'Follow system',
                      },
                      onTap: () => _AppearanceSheet.show(context, ref),
                    ),
                    SettingsTile(
                      icon: LyIcons.notifications,
                      accent: ly.blue,
                      title: 'Notifications',
                      subtitle: 'Only the Daily Digest. Never marketing.',
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: LyIcons.language,
                      accent: ly.yellow,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () {},
                    ),
                  ],
                ),

                const SettingsGroupLabel('Data'),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: LyIcons.exportData,
                      accent: ly.blue,
                      title: 'Export my data',
                      subtitle: 'Full JSON export of your lymarks and notes',
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: LyIcons.delete,
                      accent: ly.pink,
                      title: 'Delete account',
                      subtitle: 'Removes everything, permanently',
                      danger: true,
                      onTap: () => _confirmDeleteAccount(context),
                    ),
                  ],
                ),

                const SettingsGroupLabel('About'),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: LyIcons.privacy,
                      accent: ly.lime,
                      title: 'Privacy policy',
                      subtitle: 'How we protect your data',
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: LyIcons.note,
                      accent: ly.lavender,
                      title: 'Terms of service',
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: LyIcons.about,
                      accent: ly.yellow,
                      title: 'About Lymarks',
                      subtitle: 'Version 1.0.0',
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: LyIcons.help,
                      accent: ly.blue,
                      title: 'Help & feedback',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: LySpace.xl),
                OutlinedButton.icon(
                  onPressed: () => context.go(LyRoute.onboarding),
                  icon: const Icon(LyIcons.logout, size: LyIconSize.regular),
                  label: const Text('Log out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Suppression de compte : confirmation explicite double, jamais un simple
  /// tap (UX Bible règle 7, exigence Apple du PRD F7).
  static Future<void> _confirmDeleteAccount(BuildContext context) async {
    final ly = context.ly;

    final first = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'Every lymark, note and summary is deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text('Continue', style: TextStyle(color: ly.danger)),
          ),
        ],
      ),
    );

    if (first != true || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text(
          'Type-free confirmation is intentional here: this is the last step '
          'before permanent deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Keep my account'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text('Delete forever', style: TextStyle(color: ly.danger)),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return LyCard(
      onTap: () => context.push(LyRoute.profile),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ly.lavender.fill,
              shape: BoxShape.circle,
            ),
            child: Text(
              profile.initials,
              style: context.texts.titleMedium
                  ?.copyWith(color: ly.lavender.onFill),
            ),
          ),
          const SizedBox(width: LySpace.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: context.texts.titleSmall),
                const SizedBox(height: 2),
                Text(profile.email, style: context.texts.labelSmall),
              ],
            ),
          ),
          Icon(LyIcons.forward, size: 20, color: ly.textTertiary),
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ly = context.ly;
    final accent = profile.isPro ? ly.lime : ly.yellow;

    return LyCard(
      color: accent.fill,
      borderColor: accent.fill,
      onTap: () => PaywallSheet.show(
        context,
        trigger: PaywallTrigger.settings,
      ),
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
                  profile.isPro ? 'Lymarks Pro' : 'Free plan',
                  style: context.texts.titleSmall
                      ?.copyWith(color: accent.onFill),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.isPro
                      ? 'Unlimited lymarks, semantic search, digest'
                      : '${UserProfile.freeLimit} lymarks, keyword search',
                  style: context.texts.bodySmall?.copyWith(
                    color: accent.onFill.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Text(
            profile.isPro ? 'Manage' : 'Upgrade',
            style: context.texts.labelMedium?.copyWith(
              color: accent.onFill,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: LySpace.xs),
          Icon(LyIcons.forward, size: 18, color: accent.onFill),
        ],
      ),
    );
  }
}

/// Choix du thème — appliqué immédiatement.
class _AppearanceSheet extends ConsumerWidget {
  const _AppearanceSheet();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => const _AppearanceSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ly = context.ly;
    final current = ref.watch(themeModeProvider);

    const options = <(ThemeMode, String, IconData)>[
      (ThemeMode.light, 'Light', LyIcons.sun),
      (ThemeMode.dark, 'Dark', LyIcons.moon),
      (ThemeMode.system, 'Follow system', LyIcons.system),
    ];

    return SafeArea(
      child: Padding(
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
            Text('Appearance', style: context.texts.headlineSmall),
            const SizedBox(height: LySpace.l),
            for (final (mode, label, icon) in options)
              Padding(
                padding: const EdgeInsets.only(bottom: LySpace.s),
                child: LyCard(
                  color: mode == current ? ly.primarySoft : ly.card,
                  borderColor: mode == current ? ly.primary : ly.cardBorder,
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).state = mode,
                  padding: const EdgeInsets.symmetric(
                    horizontal: LySpace.l,
                    vertical: LySpace.m,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: LyIconSize.regular,
                        color: mode == current ? ly.primary : ly.textSecondary,
                      ),
                      const SizedBox(width: LySpace.m),
                      Expanded(
                        child: Text(label, style: context.texts.bodyLarge),
                      ),
                      if (mode == current)
                        Icon(LyIcons.check, size: 18, color: ly.primary),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Réglages du Daily Digest : activation et heure.
class _DigestSheet extends ConsumerStatefulWidget {
  const _DigestSheet();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => const _DigestSheet(),
    );
  }

  @override
  ConsumerState<_DigestSheet> createState() => _DigestSheetState();
}

class _DigestSheetState extends ConsumerState<_DigestSheet> {
  bool _enabled = true;
  double _hour = 8.5;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final h = _hour.floor();
    final m = ((_hour - h) * 60).round();

    return SafeArea(
      child: Padding(
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
            Text('Daily Digest', style: context.texts.headlineSmall),
            const SizedBox(height: LySpace.s),
            Text(
              'One forgotten link a day. Never two, never marketing.',
              style: context.texts.bodyMedium
                  ?.copyWith(color: ly.textSecondary),
            ),
            const SizedBox(height: LySpace.xl),
            LyCard(
              padding: const EdgeInsets.symmetric(
                horizontal: LySpace.l,
                vertical: LySpace.s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Send me a daily digest',
                      style: context.texts.bodyLarge,
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LySpace.l),
            Opacity(
              opacity: _enabled ? 1 : 0.4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Delivery time', style: context.texts.titleSmall),
                      const Spacer(),
                      Text(
                        '${h.toString().padLeft(2, '0')}:'
                        '${m.toString().padLeft(2, '0')}',
                        style: context.texts.titleSmall
                            ?.copyWith(color: ly.primary),
                      ),
                    ],
                  ),
                  Slider(
                    value: _hour,
                    min: 5,
                    max: 22,
                    divisions: 34,
                    onChanged:
                        _enabled ? (v) => setState(() => _hour = v) : null,
                  ),
                  Text(
                    'Your local time. Delivery lands within 15 minutes.',
                    style: context.texts.labelSmall,
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
