import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
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
                _PaletteItem(
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

class _PaletteItem extends ConsumerWidget {
  const _PaletteItem({
    required this.palette,
    required this.isSelected,
    super.key,
  });

  final AppPalette palette;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = resolveColorScheme(palette, ThemeMode.light);
    final duration = context.theme.durations.instant;

    return MouseClick(
      onClick: () => ref.read(themeProvider.notifier).setPalette(palette),
      child: AnimatedScale(
        duration: duration,
        scale: !isSelected ? 1.0 : 1.05,
        child: AnimatedContainer(
          duration: duration,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: context.theme.radii.xl,
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: theme.colors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              else
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
            ],
            border: isSelected
                ? Border.all(
                    color: theme.colors.primary.withValues(alpha: 0.8),
                    width: 2,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: context.theme.radii.xl,
                color: theme.colors.primary,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.md,
                children: [
                  Text(
                    palette.getLocaleName(context.l10n),
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.normal,
                      color: theme.colors.primaryForeground,
                    ),
                  ),
                  Icon(FIcons.check, color: theme.colors.primaryForeground)
                      .animate(target: isSelected ? 1 : 0)
                      .scaleXY(begin: 0, end: 1, duration: duration),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
