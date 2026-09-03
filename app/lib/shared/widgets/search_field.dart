import 'package:flutter/material.dart';
import 'package:lymarks/core/theme/app_colors.dart';
import 'package:lymarks/core/theme/app_dimens.dart';
import 'package:lymarks/core/utils/ly_icons.dart';

/// Champ de recherche unique.
///
/// UX Bible règle 5 : un seul champ, pas de filtres, pas de syntaxe. L'icône
/// ✦ prend la couleur primaire quand la requête part en sémantique (Pro).
class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.semantic = false,
    this.autofocus = false,
    this.onClear,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  /// La requête déclenche la recherche sémantique (utilisateur Pro).
  final bool semantic;
  final bool autofocus;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    final hasText = controller.text.isNotEmpty;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: context.texts.bodyLarge,
      cursorColor: ly.primary,
      decoration: InputDecoration(
        hintText: 'Search your memory...',
        hintStyle: context.texts.bodyLarge?.copyWith(color: ly.textTertiary),
        filled: true,
        fillColor: ly.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LySpace.l,
          vertical: LySpace.l,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: LySpace.l, right: LySpace.m),
          child: Icon(
            semantic ? LyIcons.sparkle : LyIcons.search,
            size: LyIconSize.large,
            color: semantic ? ly.primary : ly.textSecondary,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: hasText
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(LyIcons.close, size: LyIconSize.regular),
                color: ly.textSecondary,
                tooltip: 'Clear search',
              )
            : null,
        border: _border(ly.cardBorder),
        enabledBorder: _border(ly.cardBorder),
        focusedBorder: _border(ly.primary, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: LyRadius.pillR,
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Bandeau « ✦ Semantic search · Pro » affiché sous le champ.
class SearchModeLabel extends StatelessWidget {
  const SearchModeLabel({
    required this.semantic,
    required this.isPro,
    super.key,
  });

  final bool semantic;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final ly = context.ly;
    if (!semantic) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LyIcons.search, size: 16, color: ly.textSecondary),
          const SizedBox(width: LySpace.s),
          Flexible(
            child: Text(
              'Keyword search',
              style: context.texts.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LyIcons.sparkle, size: 16, color: ly.primary),
        const SizedBox(width: LySpace.s),
        Flexible(
          child: Text(
            'Semantic search',
            style: context.texts.labelMedium?.copyWith(color: ly.primary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: LySpace.m),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isPro ? ly.lime.strong : ly.textTertiary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: LySpace.s),
        Text('Pro', style: context.texts.labelSmall),
      ],
    );
  }
}
