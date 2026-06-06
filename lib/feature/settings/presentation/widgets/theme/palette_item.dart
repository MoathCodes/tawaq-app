import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

bool _useTouchVariant() =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.fuchsia);

/// A single palette swatch item in the theme selector grid.
class PaletteItem extends ConsumerWidget {
  /// Creates a new [PaletteItem] instance.
  const PaletteItem({
    required this.palette,
    required this.isSelected,
    this.enabled = true,
    super.key,
  });

  /// The palette this item represents.
  final AppPalette palette;

  /// Whether this palette is currently selected.
  final bool isSelected;

  /// Whether the palette can be selected.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = resolveColorScheme(
      palette,
      ThemeMode.light,
      touch: _useTouchVariant(),
    );
    final appTheme = context.theme;
    final duration = appTheme.durations.instant;
    final radii = appTheme.radii.xl;
    final l10n = context.l10n;

    final paletteName = palette.getLocaleName(l10n);

    void selectPalette() =>
        ref.read(themeProvider.notifier).setPalette(palette);

    return SettingsSemantics.labeledControl(
      name: paletteName,
      value: l10n.colorTheme,
      button: true,
      selected: isSelected,
      enabled: enabled,
      excludeChild: true,
      onTap: enabled ? selectPalette : null,
      child: MouseClick(
        disabled: !enabled,
        onClick: enabled ? selectPalette : null,
        child: AnimatedScale(
        duration: duration,
        scale: !isSelected ? 1.0 : 1.05,
        child: AnimatedContainer(
          duration: duration,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: radii,
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
                borderRadius: radii,
                color: theme.colors.primary,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.md,
                children: [
                  Text(
                    palette.getLocaleName(l10n),
                    style: theme.typography.md.copyWith(
                      fontWeight: FontWeight.normal,
                      color: theme.colors.primaryForeground,
                    ),
                  ),
                  SettingsSemantics.decorative(
                    Icon(
                      FLucideIcons.check,
                      color: theme.colors.primaryForeground,
                    )
                        .animate(target: isSelected ? 1 : 0)
                        .scaleXY(begin: 0, end: 1, duration: duration),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
