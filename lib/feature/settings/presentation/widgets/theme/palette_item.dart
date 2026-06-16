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
    super.key,
  });

  /// The palette this item represents.
  final AppPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      themeProvider.select((t) => t.value?.appPalette == palette),
    );
    final enabled = ref.watch(themeProvider.select((t) => t.hasValue));

    final theme = resolveColorScheme(
      palette,
      ThemeMode.light,
      touch: _useTouchVariant(),
    );
    final appTheme = context.theme;
    final duration = appTheme.durations.instant;
    final radii = appTheme.radii.md;
    final l10n = context.l10n;

    final paletteName = palette.getLocaleName(l10n);

    void selectPalette() =>
        ref.read(themeProvider.notifier).setPalette(palette);

    return MouseClick(
      disabled: !enabled,
      onClick: enabled ? selectPalette : null,
      semanticsLabel: paletteName,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: duration,
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
                : Border.all(
                    color: appTheme.colors.border.withValues(alpha: 0.5),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radii,
                color: theme.colors.primary,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.xs,
                  children: [
                    Flexible(
                      child: Text(
                        paletteName,
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colors.primaryForeground,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SettingsSemantics.decorative(
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: Icon(
                          FLucideIcons.check,
                          size: 14,
                          color: theme.colors.primaryForeground,
                        )
                            .animate(target: isSelected ? 1 : 0)
                            .scaleXY(begin: 0, end: 1, duration: duration),
                      ),
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
