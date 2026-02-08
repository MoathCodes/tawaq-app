import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hasanat/theme/theme_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A single palette swatch item in the theme selector grid.
class PaletteItem extends ConsumerWidget {
  /// Creates a new [PaletteItem] instance.
  const PaletteItem({
    required this.palette,
    required this.isSelected,
    super.key,
  });

  /// The palette this item represents.
  final AppPalette palette;

  /// Whether this palette is currently selected.
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
