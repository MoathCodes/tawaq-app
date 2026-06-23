import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaticCard(
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
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: FSkeletonizer(
            enabled: isLoading,
            child: duas.isEmpty && !isLoading
                ? Center(
                    child: Text(
                      context.l10n.noResultsFound,
                      style: theme.typography.body.md.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    itemCount: isLoading ? 4 : duas.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
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
      ],
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: theme.radii.md,
        border: Border.all(
          color: isExpanded
              ? theme.colors.primary.withAlpha(80)
              : theme.colors.border,
        ),
        color: isExpanded
            ? theme.colors.primary.withAlpha(10)
            : Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MouseClick(
            onClick: onToggleExpanded,
            semanticsLabel: FortressA11y.previewRowLabel(
              l10n,
              oneBasedIndex: index + 1,
              isExpanded: isExpanded,
              targetCount: dua.targetCount,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}.',
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FortressExcludeDecorative(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FortressThikrPreview(
                          dua: dua,
                          isExpanded: isExpanded,
                        ),
                        if (!isExpanded && dua.hasSharh) ...[
                          const SizedBox(height: AppSpacing.sm),
                          FBadge(
                            variant: .secondary,
                            child: Text(l10n.fortressSharh),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FortressExcludeDecorative(
                  child: Column(
                    children: [
                      Text(
                        '×${dua.targetCount}',
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Icon(
                        isExpanded
                            ? FLucideIcons.chevronUp
                            : FLucideIcons.chevronDown,
                        size: 16,
                        color: theme.colors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: AppSpacing.lg),
            if (dua.hasVirtue) ...[
              FortressDuaVirtueLine(virtue: dua.virtue!),
              const SizedBox(height: AppSpacing.md),
            ],
            LayoutBuilder(
              builder: (context, constraints) => FortressDuaStudyAccess(
                dua: dua,
                useSheet: constraints.maxWidth < 480,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FortressDuaPreviewPlaceholder extends StatelessWidget {
  const FortressDuaPreviewPlaceholder({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: theme.radii.md,
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}.',
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: theme.colors.muted,
                borderRadius: theme.radii.sm,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 28,
            height: 14,
            decoration: BoxDecoration(
              color: theme.colors.muted,
              borderRadius: theme.radii.sm,
            ),
          ),
        ],
      ),
    );
  }
}
