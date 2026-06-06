import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_locale_extensions.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_thikr_body.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/theme/theme.dart';

class FortressCategoryDetailView extends HookConsumerWidget {
  const FortressCategoryDetailView({
    required this.category,
    required this.duas,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onStartReading,
    this.isLoading = false,
    super.key,
  });

  final FortressCategory category;
  final List<FortressDuaItem> duas;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onStartReading;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final expandedIndex = useState<int?>(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colors.secondary.withAlpha(80),
            borderRadius: theme.radii.lg,
            border: Border.all(color: theme.colors.border.withAlpha(100)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title,
                          style: theme.typography.xl2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          fortressRecurrenceLabel(category.recurrence, l10n),
                          style: theme.typography.md.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MouseClick(
                    onClick: onToggleFavorite,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        FLucideIcons.bookmark,
                        size: 22,
                        color: isFavorite
                            ? theme.colors.primary
                            : theme.colors.mutedForeground,
                        fill: isFavorite ? 1.0 : 0.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FBadge(
                child: Text(l10n.fortressSupplicationsInSection(duas.length)),
              ),
              const SizedBox(height: AppSpacing.lg),
              FButton(
                onPress: onStartReading,
                prefix: const Icon(FLucideIcons.bookOpen),
                child: Text(l10n.fortressStartReading),
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
                      style: theme.typography.md.copyWith(
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

                      return FortressDuaPreviewCard(
                        index: index,
                        dua: dua,
                        isExpanded: isExpanded,
                        onToggleExpanded: () {
                          expandedIndex.value = isExpanded ? null : index;
                        },
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
  const FortressDuaPreviewCard({required this.index, required this.dua, required this.isExpanded, required this.onToggleExpanded, super.key,
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
                  style: theme.typography.sm.copyWith(
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
                        style: theme.typography.xs.copyWith(
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
            FortressDuaStudyAccess(dua: dua),
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
            style: theme.typography.sm.copyWith(
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

