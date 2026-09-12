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
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_layout.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_favorite_toggle.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_dua_content.dart';
import 'package:tawaq/theme/theme.dart';

class FortressCategoryDetailView extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(fortressSelectedCategoryProvider);
    if (category == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final repositoryAsync = ref.watch(fortressRepositoryProvider);

    return repositoryAsync.when(
      data: (repository) => _FortressCategoryDetailBody(
        category: category,
        duas: repository.loadDuas(category.chapterId),
      ),
      loading: () => _FortressCategoryDetailBody(
        category: category,
        duas: const [],
        isLoading: true,
      ),
      error: (_, _) => Center(
        child: ErrorStatePanel(
          message: l10n.fortressLoadError,
          retryLabel: l10n.fortressRetry,
          onRetry: () => ref.invalidate(fortressRepositoryProvider),
        ),
      ),
    );
  }
}

/// Compact chapter header shared by the browse detail route.
class FortressCategoryDetailHeader extends StatelessWidget {
  /// Creates a compact chapter header.
  const new({
    required this.category,
    required this.duaCount,
    required this.onStartReading,
    super.key,
  });

  /// Chapter metadata shown in the header.
  final FortressCategory category;

  /// Number of sourced adhkar in the chapter.
  final int duaCount;

  /// Starts focus reading, or is null while the chapter has no content.
  final VoidCallback? onStartReading;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return StaticCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: theme.radii.lg,
      backgroundColor: theme.colors.secondary.withAlpha(80),
      borderColor: theme.colors.border.withAlpha(100),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleAndMeta = Column(
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
                  const SizedBox(width: AppSpacing.sm),
                  FortressFavoriteToggle(
                    chapterId: category.chapterId,
                    iconSize: 22,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  _FortressHeaderMeta(
                    icon: FLucideIcons.repeat,
                    label: fortressRecurrenceLabel(category.recurrence, l10n),
                  ),
                  _FortressHeaderMeta(
                    icon: FLucideIcons.list,
                    label: l10n.fortressSupplicationsInSection(duaCount),
                  ),
                ],
              ),
            ],
          );
          final startButton = FButton(
            onPress: onStartReading,
            prefix: const Icon(FLucideIcons.bookOpen),
            child: Text(l10n.fortressStartReading),
          );

          // Keep the action in the header on wide panes, but let it take a
          // natural second line when localized titles need the room.
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleAndMeta,
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: startButton,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleAndMeta),
              const SizedBox(width: AppSpacing.lg),
              startButton,
            ],
          );
        },
      ),
    );
  }
}

class _FortressCategoryDetailBody extends HookConsumerWidget {
  const new({
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
      fortressScreenSettingsProvider.select(
        (v) => v.asData?.value.favoriteChapterIds ?? const [],
      ),
    );
    final isFavorite = favoriteChapterIds.contains(category.chapterId);
    final controller = ref.read(fortressScreenControllerProvider.notifier);
    final theme = context.theme;
    final l10n = context.l10n;
    final expandedContentId = useState<int?>(null);
    useEffect(() {
      // Keep disclosure local to the selected chapter even if the detail body
      // is reused while the repository publishes a refreshed snapshot.
      expandedContentId.value = null;
      return null;
    }, [category.chapterId]);

    void toggleFavorite() => ref
        .read(fortressScreenSettingsProvider.notifier)
        .toggleFavorite(category.chapterId);

    return CenteredViewportShell(
      maxContentWidth: kFortressReadingMaxWidth,
      header: FortressCategoryDetailHeader(
        category: category,
        duaCount: duas.length,
        onStartReading: duas.isEmpty && !isLoading
            ? null
            : controller.startFocusReading,
      ),
      body: CenteredViewportShell.scrollTab(
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
                      final isExpanded =
                          expandedContentId.value == dua.contentId;

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
                          key: ValueKey(dua.contentId),
                          index: index,
                          dua: dua,
                          isExpanded: isExpanded,
                          onToggleExpanded: () {
                            expandedContentId.value = isExpanded
                                ? null
                                : dua.contentId;
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
  const new({
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

    final content = FortressDuaContent(
      dua: dua,
      mode: isExpanded
          ? FortressDuaContentMode.previewExpanded
          : FortressDuaContentMode.previewCollapsed,
    );
    final title = isExpanded ? content : ExcludeSemantics(child: content);
    final insightMeta = !isExpanded && hasInsights
        ? ExcludeSemantics(
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (dua.hasSharh)
                  _FortressPreviewMeta(
                    icon: FLucideIcons.bookOpenText,
                    label: l10n.fortressSharh,
                  ),
                if (dua.hasVirtue)
                  _FortressPreviewMeta(
                    icon: FLucideIcons.sparkles,
                    label: l10n.fortressVirtue,
                  ),
              ],
            ),
          )
        : null;
    final disclosure = isExpanded
        ? Semantics(
            container: true,
            button: true,
            label: FortressA11y.previewCollapseLabel(
              l10n,
              oneBasedIndex: index + 1,
            ),
            onTap: onToggleExpanded,
            child: ExcludeSemantics(
              child: MouseClick(
                onClick: onToggleExpanded,
                child: ExcludeSemantics(
                  child: _FortressDuaPreviewFooter(
                    targetCount: dua.targetCount,
                    isExpanded: isExpanded,
                    colors: colors,
                    typography: theme.typography,
                  ),
                ),
              ),
            ),
          )
        : ExcludeSemantics(
            child: _FortressDuaPreviewFooter(
              targetCount: dua.targetCount,
              isExpanded: isExpanded,
              colors: colors,
              typography: theme.typography,
            ),
          );
    final subtitle = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (insightMeta != null) ...[
          insightMeta,
          const SizedBox(height: AppSpacing.xs),
        ],
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: disclosure,
        ),
      ],
    );
    final prefix = ExcludeSemantics(
      child: Text(
        '${index + 1}.',
        style: theme.typography.body.sm.copyWith(
          color: colors.mutedForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // Collapsed rows own one semantic button with the sourced dhikr text.
    // Expanded rows expose their content and nested study tabs as descendants;
    // Only the footer remains interactive so tab activation never collapses it.
    final tile = FTile(
      prefix: prefix,
      title: title,
      subtitle: subtitle,
      selected: isExpanded,
      semanticsLabel: isExpanded
          ? null
          : FortressA11y.previewRowLabel(
              l10n,
              oneBasedIndex: index + 1,
              isExpanded: false,
              targetCount: dua.targetCount,
              text: dua.text,
            ),
      semanticsExpanded: isExpanded,
      // Nested controls (e.g. FTabs) are not FTappableGroup entries; disable
      // tile press while expanded so tab taps do not collapse the row.
      onPress: isExpanded ? null : onToggleExpanded,
    );

    if (!isExpanded) return tile;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: FortressA11y.previewRowLabel(
        l10n,
        oneBasedIndex: index + 1,
        isExpanded: true,
        targetCount: dua.targetCount,
      ),
      expanded: true,
      child: tile,
    );
  }
}

class _FortressDuaPreviewFooter extends StatelessWidget {
  const new({
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
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '×$targetCount',
              style: typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              isExpanded ? l10n.fortressShowLess : l10n.fortressShowMore,
              style: typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              isExpanded ? FLucideIcons.chevronUp : FLucideIcons.chevronDown,
              size: 14,
              color: colors.mutedForeground,
            ),
          ],
        ),
      ],
    );
  }
}

class _FortressHeaderMeta extends StatelessWidget {
  const _FortressHeaderMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colors.mutedForeground),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}

class _FortressPreviewMeta extends StatelessWidget {
  const _FortressPreviewMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colors.mutedForeground),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}

class FortressDuaPreviewPlaceholder extends StatelessWidget {
  const new({required this.index, super.key});

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
