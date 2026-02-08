import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/palette_item.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hasanat/theme/theme_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Widget for selecting the application color theme.
class ColorThemeSelector extends ConsumerWidget {
  /// Creates a [ColorThemeSelector].
  const ColorThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPalette = ref.watch(
      themeProvider.select((t) => t.value?.appPalette),
    );
    final selectedMode = ref.watch(
      themeProvider.select((t) => t.value?.themeMode),
    );

    final theme = FTheme.of(context);
    return FCard(
      child: Column(
        spacing: AppSpacing.md,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.appearance,
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FTabs(
            control: FTabControl.lifted(
              index: selectedMode == ThemeMode.light ? 0 : 1,
              onChange: (value) => ref
                  .read(themeProvider.notifier)
                  .setThemeMode(value == 0 ? ThemeMode.light : ThemeMode.dark),
            ),
            children: [
              FTabEntry(
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.md,
                  children: [
                    const Icon(FIcons.sun),
                    Text(context.l10n.light),
                  ],
                ),
                child: const SizedBox.shrink(),
              ),
              FTabEntry(
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.md,
                  children: [
                    const Icon(FIcons.moon),
                    Text(context.l10n.dark),
                  ],
                ),
                child: const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.colorTheme,
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colors.mutedForeground,
            ),
          ),
          GridView.extent(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            maxCrossAxisExtent: 200,
            childAspectRatio: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            children: [
              for (final palette in AppPalette.values)
                PaletteItem(
                  key: ValueKey(palette),
                  palette: palette,
                  isSelected: selectedPalette == palette,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
