import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme/palette_item.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

/// Color palette and light/dark mode controls without outer section chrome.
class ColorThemeSelectorContent extends ConsumerWidget {
  /// Creates [ColorThemeSelectorContent].
  const ColorThemeSelectorContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(
      themeProvider.select((t) => t.value?.themeMode),
    );
    final themeReady = ref.watch(themeProvider.select((t) => t.hasValue));
    final l10n = context.l10n;
    final isLight = selectedMode != ThemeMode.dark;

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
                      ? () => ref
                          .read(themeProvider.notifier)
                          .setThemeMode(ThemeMode.light)
                      : null,
                  prefix: const Icon(FLucideIcons.sun, size: 16),
                  child: Text(l10n.light),
                ),
              ),
              Expanded(
                child: FButton(
                  variant: isLight ? .outline : .primary,
                  onPress: themeReady
                      ? () => ref
                          .read(themeProvider.notifier)
                          .setThemeMode(ThemeMode.dark)
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = responsiveColumnCount(
                context,
                constraints.maxWidth,
                maxColumns: 5,
                minColumns: 5,
              );

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 76,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.sm,
                ),
                itemCount: AppPalette.values.length,
                itemBuilder: (context, index) {
                  final palette = AppPalette.values[index];
                  return PaletteItem(
                    key: ValueKey(palette),
                    palette: palette,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
