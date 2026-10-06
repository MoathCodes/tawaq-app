import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/desktop/omarchy_theme_source.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/omarchy_theme.dart';
import 'package:tawaq/theme/omarchy_theme_provider.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

/// Light/dark mode and available palette controls.
class ColorThemeSelectorContent extends ConsumerWidget {
  /// Creates [ColorThemeSelectorContent].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(
      themeProvider.select((t) => t.value?.themeMode),
    );
    final selectedPalette = ref.watch(
      themeProvider.select((t) => t.value?.appPalette),
    );
    final themeReady = ref.watch(themeProvider.select((t) => t.hasValue));
    final omarchyTheme = ref.watch(omarchyThemeProvider).value;
    final omarchyAvailable = omarchyTheme?.isAvailable == true;
    final omarchySelected =
        selectedPalette == AppPalette.omarchy && omarchyAvailable;
    final effectiveSelectedPalette =
        selectedPalette == AppPalette.omarchy && !omarchyAvailable
        ? AppPalette.manuscript
        : selectedPalette;
    final visiblePalettes = AppPalette.values.where(
      (palette) => palette != AppPalette.omarchy || omarchyAvailable,
    );
    final l10n = context.l10n;
    final notifier = ref.read(themeProvider.notifier);

    return Column(
      spacing: AppSpacing.lg,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: l10n.themeModeLabel,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 480;
              final width =
                  (constraints.maxWidth - AppSpacing.sm * (compact ? 1 : 2)) /
                  (compact ? 2 : 3);
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final mode in [
                    ThemeMode.system,
                    ThemeMode.light,
                    ThemeMode.dark,
                  ])
                    SizedBox(
                      width: compact && mode == ThemeMode.system
                          ? constraints.maxWidth
                          : width,
                      child: FButton(
                        variant: selectedMode == mode ? .primary : .outline,
                        onPress: themeReady && !omarchySelected
                            ? () => notifier.setThemeMode(mode)
                            : null,
                        prefix: Icon(switch (mode) {
                          ThemeMode.system => FLucideIcons.monitor,
                          ThemeMode.light => FLucideIcons.sun,
                          ThemeMode.dark => FLucideIcons.moon,
                        }, size: 16),
                        child: Text(switch (mode) {
                          ThemeMode.system => l10n.systemThemeLabel,
                          ThemeMode.light => l10n.light,
                          ThemeMode.dark => l10n.dark,
                        }),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        SettingsGroup(
          title: l10n.colorTheme,
          subtitle: l10n.colorThemeSubtitle,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 640
                  ? 2
                  : visiblePalettes.length;
              final width =
                  (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final palette in visiblePalettes)
                    SizedBox(
                      width: width,
                      child: FButton(
                        variant: effectiveSelectedPalette == palette
                            ? .primary
                            : .outline,
                        onPress: themeReady
                            ? () => notifier.setPalette(palette)
                            : null,
                        prefix: _PaletteSwatch(
                          palette: palette,
                          omarchyTheme: omarchyTheme,
                        ),
                        child: Text(palette.getLocaleName(l10n)),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Small primary-color dot identifying a palette on the outline/primary buttons.
class _PaletteSwatch extends StatelessWidget {
  const new({required this.palette, this.omarchyTheme});

  final AppPalette palette;
  final OmarchyThemeSnapshot? omarchyTheme;

  @override
  Widget build(BuildContext context) {
    final colors =
        palette == AppPalette.omarchy && omarchyTheme?.isAvailable == true
        ? buildOmarchyColors(omarchyTheme!)
        : resolveColorScheme(
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
