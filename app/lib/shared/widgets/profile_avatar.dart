import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';
import 'package:lymarks/shared/data/providers.dart';
import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/widgets/ly_card.dart';

/// Avatars proposés au choix.
///
/// Provisoires : ils seront remplacés par les emoji dessinés pour Lymarks
/// quand ils existeront. La feuille de choix suit la longueur de la liste.
const List<String> kAvatarChoices = ['🦊', '🐼', '🦉', '🐙', '🦄'];

/// Pastille ronde du profil : l'emoji choisi, sinon les initiales.
///
/// Reprend le dégradé lavande → bleu de la carte d'identité, un cran plus
/// saturé pour rester visible sur cette même carte. La cible tactile ne
/// descend jamais sous 44 pt (UX Bible), quelle que soit [size].
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.profile,
    this.size = 40,
    this.onTap,
    this.semanticsLabel = 'Profile',
    super.key,
  });

  /// Cible tactile minimale.
  static const double minTapTarget = 44;

  final UserProfile profile;
  final double size;
  final VoidCallback? onTap;

  /// Ce que lit le lecteur d'écran ; le contenu du cercle est décoratif.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final avatar = profile.avatar;
    final tapSize = math.max(size, minTapTarget);

    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ly.lift(ly.lavender, 0.35), ly.lift(ly.blue, 0.45)],
        ),
        border: Border.all(color: ly.card, width: 2),
      ),
      child: avatar == null
          ? Text(
              profile.initials,
              textScaler: TextScaler.noScaling,
              style: context.texts.titleMedium?.copyWith(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -0.2,
                color: ly.lavender.onFill,
              ),
            )
          : Text(
              avatar,
              textScaler: TextScaler.noScaling,
              // Inter n'a pas de glyphes emoji : le système fournit les siens.
              style: TextStyle(fontSize: size * 0.55, height: 1),
            ),
    );

    return Semantics(
      button: onTap != null,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: tapSize,
            height: tapSize,
            child: Center(child: ExcludeSemantics(child: circle)),
          ),
        ),
      ),
    );
  }
}

/// Ouvre la feuille de choix d'avatar.
///
/// Le choix s'applique tout de suite ([ProfileNotifier.setAvatar]) et la
/// feuille se ferme : pas de bouton « Enregistrer » pour un seul geste.
Future<void> showAvatarPicker(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheet) => _AvatarPickerSheet(
      profile: ref.read(profileProvider),
      onSelect: (avatar) {
        unawaited(ref.read(profileProvider.notifier).setAvatar(avatar));
        Navigator.of(sheet).pop();
      },
    ),
  );
}

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({required this.profile, required this.onSelect});

  final UserProfile profile;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final useInitials = profile.avatar == null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LySpace.xl,
          LySpace.s,
          LySpace.xl,
          LySpace.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your avatar', style: context.texts.headlineSmall),
              const SizedBox(height: LySpace.s),
              Text(
                'Pick an emoji, or keep your initials.',
                style: context.texts.bodyMedium?.copyWith(
                  color: ly.textSecondary,
                ),
              ),
              const SizedBox(height: LySpace.xl),
              // Cellules bornées : sur un écran large (tablette, paysage,
              // surface de test), cinq colonnes libres débordaient.
              GridView.extent(
                maxCrossAxisExtent: 72,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                mainAxisSpacing: LySpace.m,
                crossAxisSpacing: LySpace.m,
                children: [
                  for (final emoji in kAvatarChoices)
                    _EmojiChoice(
                      emoji: emoji,
                      selected: profile.avatar == emoji,
                      onTap: () => onSelect(emoji),
                    ),
                ],
              ),
              const SizedBox(height: LySpace.l),
              LyCard(
                color: useInitials ? ly.primarySoft : ly.card,
                borderColor: useInitials ? ly.primary : ly.cardBorder,
                onTap: () => onSelect(null),
                padding: const EdgeInsets.symmetric(
                  horizontal: LySpace.l,
                  vertical: LySpace.m,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ly.lavender.fill,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        profile.initials,
                        style: context.texts.labelMedium?.copyWith(
                          color: ly.lavender.onFill,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: LySpace.m),
                    Expanded(
                      child: Text(
                        'Use my initials',
                        style: context.texts.bodyLarge,
                      ),
                    ),
                    if (useInitials)
                      Icon(LyIcons.check, size: 18, color: ly.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiChoice extends StatelessWidget {
  const _EmojiChoice({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? ly.primarySoft : ly.card,
        shape: CircleBorder(
          side: BorderSide(
            color: selected ? ly.primary : ly.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(
              emoji,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(fontSize: 28, height: 1),
            ),
          ),
        ),
      ),
    );
  }
}
