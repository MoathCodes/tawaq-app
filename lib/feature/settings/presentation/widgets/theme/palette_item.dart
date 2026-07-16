import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

bool _useTouchVariant() =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.fuchsia);

/// Compact circular swatch for a theme palette.
class PaletteItem extends ConsumerWidget {
  /// Creates a new [PaletteItem] instance.
  const PaletteItem({
    required this.palette,
    super.key,
  });

  /// The palette this item represents.
  final AppPalette palette;

  static const _swatchSize = 44.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      themeProvider.select((t) => t.value?.appPalette == palette),
    );
    final enabled = ref.watch(themeProvider.select((t) => t.hasValue));

    final paletteTheme = resolveColorScheme(
      palette,
      ThemeMode.light,
      touch: _useTouchVariant(),
    );
    final appTheme = context.theme;
    final duration = appTheme.durations.fast;
    final l10n = context.l10n;
    final paletteName = palette.getLocaleName(l10n);

    void selectPalette() =>
        ref.read(themeProvider.notifier).setPalette(palette);

    return MouseClick(
      disabled: !enabled,
      onClick: enabled ? selectPalette : null,
      semanticsLabel: paletteName,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: [
            AnimatedContainer(
              duration: duration,
              width: _swatchSize,
              height: _swatchSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: paletteTheme.colors.primary,
                border: Border.all(
                  color: isSelected
                      ? appTheme.colors.foreground
                      : appTheme.colors.border.withValues(alpha: 0.65),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: paletteTheme.colors.primary.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? SettingsSemantics.decorative(
                      Icon(
                        FLucideIcons.check,
                        size: 18,
                        color: paletteTheme.colors.primaryForeground,
                      ),
                    )
                  : null,
            ),
            Text(
              paletteName,
              style: appTheme.typography.body.xs.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? appTheme.colors.foreground
                    : appTheme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
