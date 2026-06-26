import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/centered_viewport_shell.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/context_menu_action.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_locale_extensions.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_focus_reading.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_thikr_body.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

class FortressCategoryDetailView extends ConsumerWidget {
  const FortressCategoryDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(fortressSelectedCategoryProvider);
    if (category == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final duasAsync = ref.watch(muslimFortressDuasProvider(category.chapterId));

    return duasAsync.when(
      data: (duas) => _FortressCategoryDetailBody(
        category: category,
        duas: duas,
      ),
      loading: () => _FortressCategoryDetailBody(
        category: category,
        duas: const [],
        isLoading: true,
      ),
      error: (error, _) => Center(
        child: ErrorStatePanel(
          message: l10n.fortressLoadError,
          detail: '$error',
          retryLabel: l10n.fortressRetry,
          onRetry: () => ref.invalidate(
            muslimFortressDuasProvider(category.chapterId),
          ),
        ),
      ),
    );
  }
}

class _FortressCategoryDetailBody extends HookConsumerWidget {
  const _FortressCategoryDetailBody({
    required this.category,
    required this.duas,
    this.isLoading = false,
  });

  final FortressCategory category;
  final List<FortressDuaItem> duas;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteChapterIds = ref.watch(
      fortressUiStateProvider.select((state) => state.favoriteChapterIds),
    );
    final isFavorite = favoriteChapterIds.contains(category.chapterId);
    final controller = ref.read(fortressScreenControllerProvider.notifier);
    final theme = context.theme;
    final l10n = context.l10n;
    final expandedIndex = useState<int?>(null);

    void toggleFavorite() => ref
        .read(fortressScreenSettingsProvider.notifier)
        .toggleFavorite(category.chapterId);

    return CenteredViewportShell(
      maxContentWidth: kFortressReadingMaxWidth,
      header: StaticCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        borderRadius: theme.radii.lg,
        backgroundColor: theme.colors.secondary.withAlpha(80),
        borderColor: theme.colors.border.withAlpha(100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    category.title,
                    style: theme.typography.body.xl2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                MouseClick(
                  onClick: toggleFavorite,
                  semanticsLabel: l10n.fortressFavorites,
                  child: FTooltip(
                    tipBuilder: (_, _) => Text(l10n.fortressFavorites),
                    child: FortressExcludeDecorative(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Icon(
                          isFavorite
                              ? FLucideIcons.bookmarkCheck
                              : FLucideIcons.bookmark,
                          size: 22,
                          color: isFavorite
                              ? theme.colors.primary
                              : theme.colors.mutedForeground,
                          fill: isFavorite ? 1.0 : 0.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              fortressRecurrenceLabel(category.recurrence, l10n),
              style: theme.typography.body.md.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FBadge(
              child: Text(l10n.fortressSupplicationsInSection(duas.length)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                FButton(
                  onPress: controller.startFocusReading,
                  prefix: const Icon(FLucideIcons.bookOpen),
                  child: Text(l10n.fortressStartReading),
                ),
              ],
            ),
          ],
        ),
      ),
      body: centeredViewportScrollTab(
        maxContentWidth: kFortressReadingMaxWidth,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxl,
          ),
          child: FSkeletonizer(
            enabled: isLoading,
            child: duas.isEmpty && !isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl,
                      ),
                      child: Text(
                        context.l10n.noResultsFound,
                        style: theme.typography.body.md.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  )
                : FTileGroup.builder(
                    divider: FItemDivider.full,
                    count: isLoading ? 4 : duas.length,
                    tileBuilder: (context, index) {
                      if (index >= (isLoading ? 4 : duas.length)) {
                        return null;
                      }
                      if (isLoading) {
                        return FortressDuaPreviewPlaceholder(index: index);
                      }
                      final dua = duas[index];
                      final isExpanded = expandedIndex.value == index;

                      return FContextMenu(
                        menuBuilder: (context, menuController, _) => [
                          FItemGroup(
                            children: [
                              contextMenuAction(
                                controller: menuController,
                                icon: FLucideIcons.copy,
                                label: l10n.menuCopyText,
                                onPressed: () {
                                  unawaited(
                                    Clipboard.setData(
                                      ClipboardData(text: dua.text.trim()),
                                    ),
                                  );
                                  showFToast(
                                    context: context,
                                    title: Text(l10n.fortressDhikrCopied),
                                  );
                                },
                              ),
                              contextMenuAction(
                                controller: menuController,
                                icon: isFavorite
                                    ? FLucideIcons.bookmarkX
                                    : FLucideIcons.bookmark,
                                label: isFavorite
                                    ? l10n.menuRemoveFavorite
                                    : l10n.menuAddFavorite,
                                onPressed: toggleFavorite,
                              ),
                              contextMenuAction(
                                controller: menuController,
                                icon: FLucideIcons.bookOpen,
                                label: l10n.fortressStartReading,
                                onPressed: controller.startFocusReading,
                              ),
                            ],
                          ),
                        ],
                        child: FortressDuaPreviewCard(
                          index: index,
                          dua: dua,
                          isExpanded: isExpanded,
                          onToggleExpanded: () {
                            expandedIndex.value = isExpanded ? null : index;
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class FortressDuaPreviewCard extends StatelessWidget {
  const FortressDuaPreviewCard({
    required this.index,
    required this.dua,
    required this.isExpanded,
    required this.onToggleExpanded,
    super.key,
  });

  final int index;
  final FortressDuaItem dua;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final colors = theme.colors;
    final hasInsights = dua.hasVirtue || dua.hasStudyContent;

    return Semantics(
      label: FortressA11y.previewRowLabel(
        l10n,
        oneBasedIndex: index + 1,
        isExpanded: isExpanded,
        targetCount: dua.targetCount,
      ),
      button: !isExpanded,
      child: FTile(
        prefix: Text(
          '${index + 1}.',
          style: theme.typography.body.sm.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        title: FortressExcludeDecorative(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FortressThikrPreview(dua: dua, isExpanded: isExpanded),
              if (isExpanded && dua.hasVirtue) ...[
                const SizedBox(height: AppSpacing.md),
                FortressDuaVirtueLine(virtue: dua.virtue!),
              ],
              if (isExpanded && dua.hasStudyContent) ...[
                const SizedBox(height: AppSpacing.lg),
                FortressDuaStudyContent(dua: dua, compact: true),
              ],
            ],
          ),
        ),
        subtitle: !isExpanded && hasInsights
            ? FortressExcludeDecorative(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (dua.hasSharh)
                      FBadge(
                        variant: .secondary,
                        child: Text(l10n.fortressSharh),
                      ),
                    if (dua.hasVirtue)
                      FBadge(
                        variant: .secondary,
                        child: Text(l10n.fortressVirtue),
                      ),
                  ],
                ),
              )
            : null,
        suffix: FortressExcludeDecorative(
          child: isExpanded
              ? MouseClick(
                  onClick: onToggleExpanded,
                  semanticsLabel: FortressA11y.previewRowLabel(
                    l10n,
                    oneBasedIndex: index + 1,
                    isExpanded: isExpanded,
                    targetCount: dua.targetCount,
                  ),
                  child: _FortressDuaPreviewSuffix(
                    targetCount: dua.targetCount,
                    isExpanded: isExpanded,
                    colors: colors,
                    typography: theme.typography,
                  ),
                )
              : _FortressDuaPreviewSuffix(
                  targetCount: dua.targetCount,
                  isExpanded: isExpanded,
                  colors: colors,
                  typography: theme.typography,
                ),
        ),
        selected: isExpanded,
        // Nested controls (e.g. FTabs) are not FTappableGroup entries; disable
        // tile press while expanded so tab taps do not collapse the row.
        onPress: isExpanded ? null : onToggleExpanded,
      ),
    );
  }
}

class _FortressDuaPreviewSuffix extends StatelessWidget {
  const _FortressDuaPreviewSuffix({
    required this.targetCount,
    required this.isExpanded,
    required this.colors,
    required this.typography,
  });

  final int targetCount;
  final bool isExpanded;
  final FColors colors;
  final FTypography typography;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '×$targetCount',
          style: typography.body.xs.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Icon(
          isExpanded ? FLucideIcons.chevronUp : FLucideIcons.chevronDown,
          size: 16,
          color: colors.mutedForeground,
        ),
      ],
    );
  }
}

class FortressDuaPreviewPlaceholder extends StatelessWidget {
  const FortressDuaPreviewPlaceholder({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FTile(
      prefix: Text(
        '${index + 1}.',
        style: theme.typography.body.sm.copyWith(
          color: theme.colors.mutedForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
      title: Container(
        height: 14,
        decoration: BoxDecoration(
          color: theme.colors.muted,
          borderRadius: theme.radii.sm,
        ),
      ),
      suffix: Container(
        width: 28,
        height: 14,
        decoration: BoxDecoration(
          color: theme.colors.muted,
          borderRadius: theme.radii.sm,
        ),
      ),
    );
  }
}
