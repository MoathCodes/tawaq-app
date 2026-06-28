import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/layout/hadith_layout_scope.dart';
import 'package:tawaq/theme/theme.dart';

/// Horizontal list of recent search queries.
class HadithRecentSearchesSection extends ConsumerWidget {
  /// Creates the recent searches section.
  const HadithRecentSearchesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final ui = ref.watch(hadithScreenUiProvider);
    final screenController = ref.read(hadithSessionControllerProvider.notifier);

    return ui.recentSearches.when(
      data: (items) {
        if (items.isEmpty) {
          return Text(
            l10n.hadithNoRecentSearches,
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.xs,
          children: [
            _SearchMetaSectionHeader(
              icon: FLucideIcons.history,
              title: l10n.hadithRecentSearches,
              trailing: FButton(
                variant: FButtonVariant.ghost,
                size: FButtonSizeVariant.sm,
                mainAxisSize: MainAxisSize.min,
                onPress: ui.searchBusy
                    ? null
                    : () => unawaited(screenController.clearRecentSearches()),
                child: Text(l10n.hadithClearAllRecents),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: AppSpacing.xs,
                children: [
                  for (final query in items)
                    _RecentSearchChip(query: query),
                ],
              ),
            ),
          ],
        );
      },
      error: (_, _) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}

class _RecentSearchChip extends HookConsumerWidget {
  const _RecentSearchChip({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final ui = ref.watch(hadithScreenUiProvider);
    final screenController = ref.read(hadithSessionControllerProvider.notifier);
    final (:isHovered, :setHovered) = useHoverState();
    final showRemove = isHovered || !HadithLayoutScope.of(context);

    return MouseRegion(
      onEnter: (_) => setHovered(value: true),
      onExit: (_) => setHovered(value: false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FButton(
            variant: FButtonVariant.ghost,
            size: FButtonSizeVariant.sm,
            mainAxisSize: MainAxisSize.min,
            semanticsLabel: hadithRecentSearchChipSemanticsLabel(query, l10n),
            onPress: ui.searchBusy
                ? null
                : () {
                    unawaited(screenController.setQuery(query));
                  },
            child: HadithDecorExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xs,
                children: [
                  Icon(
                    FLucideIcons.search,
                    size: 11,
                    color: theme.colors.mutedForeground,
                  ),
                  Text(query, softWrap: false),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: theme.durations.fast,
              curve: Curves.easeOut,
              alignment: AlignmentDirectional.centerStart,
              child: showRemove && !ui.searchBusy
                  ? FButton.icon(
                      variant: FButtonVariant.ghost,
                      size: FButtonSizeVariant.sm,
                      semanticsLabel: hadithRemoveRecentSearchSemanticsLabel(
                        query,
                        l10n,
                      ),
                      onPress: () {
                        unawaited(screenController.removeRecentSearch(query));
                      },
                      child: const HadithDecorExcludeSemantics(
                        child: Icon(FLucideIcons.x, size: 12),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchMetaSectionHeader extends StatelessWidget {
  const _SearchMetaSectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      children: [
        Icon(icon, size: 12, color: theme.colors.mutedForeground),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: theme.typography.body.xs.copyWith(
            color: theme.colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}
