import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

/// Light/dark mode and Manuscript/Neutral palette controls.
class ColorThemeSelectorContent extends ConsumerWidget {
  /// Creates [ColorThemeSelectorContent].
  const ColorThemeSelectorContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(
      themeProvider.select((t) => t.value?.themeMode),
    );
    final selectedPalette = ref.watch(
      themeProvider.select((t) => t.value?.appPalette),
    );
    final themeReady = ref.watch(themeProvider.select((t) => t.hasValue));
    final l10n = context.l10n;
    final isLight = selectedMode != ThemeMode.dark;
    final notifier = ref.read(themeProvider.notifier);

    return Column(
      spacing: AppSpacing.lg,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: FButton(
                  variant: isLight ? .primary : .outline,
                  onPress: themeReady
                      ? () => notifier.setThemeMode(ThemeMode.light)
                      : null,
                  prefix: const Icon(FLucideIcons.sun, size: 16),
                  child: Text(l10n.light),
                ),
              ),
              Expanded(
                child: FButton(
                  variant: isLight ? .outline : .primary,
                  onPress: themeReady
                      ? () => notifier.setThemeMode(ThemeMode.dark)
                      : null,
                  prefix: const Icon(FLucideIcons.moon, size: 16),
                  child: Text(l10n.dark),
                ),
              ),
            ],
          ),
        ),
        SettingsGroup(
          title: l10n.colorTheme,
          subtitle: l10n.colorThemeSubtitle,
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              for (final palette in AppPalette.values)
                Expanded(
                  child: FButton(
                    variant: selectedPalette == palette ? .primary : .outline,
                    onPress: themeReady
                        ? () => notifier.setPalette(palette)
                        : null,
                    prefix: _PaletteSwatch(palette: palette),
                    child: Text(palette.getLocaleName(l10n)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small primary-color dot identifying a palette on the outline/primary buttons.
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final colors = resolveColorScheme(
      palette,
      ThemeMode.light,
      touch: context.platformVariant.touch,
    ).colors;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary,
        border: Border.all(
          color: colors.primaryForeground.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
