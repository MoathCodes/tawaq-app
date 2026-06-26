import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme/palette_item.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

/// Widget for selecting the application color theme.
class ColorThemeSelector extends ConsumerWidget {
  /// Creates a [ColorThemeSelector].
  const ColorThemeSelector({this.embedded = false, super.key});

  /// When true, omits the appearance section header for onboarding.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(
      themeProvider.select((t) => t.value?.themeMode),
    );
    final themeReady = ref.watch(themeProvider.select((t) => t.hasValue));

    final theme = FTheme.of(context);
    final l10n = context.l10n;

    return Column(
      spacing: AppSpacing.lg,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded)
          SettingsSemantics.sectionHeader(
            label: l10n.appearance,
            child: Text(
              l10n.appearance,
              style: theme.typography.body.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        SettingsGroup(
          child: FTabs(
            control: FTabControl.lifted(
              index: selectedMode == ThemeMode.light ? 0 : 1,
              onChange: (value) {
                if (!themeReady) return;
                ref
                    .read(themeProvider.notifier)
                    .setThemeMode(
                      value == 0 ? ThemeMode.light : ThemeMode.dark,
                    );
              },
            ),
            children: [
              FTabEntry(
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    const Icon(FLucideIcons.sun, size: 16),
                    Text(l10n.light),
                  ],
                ),
                child: const SizedBox.shrink(),
              ),
              FTabEntry(
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    const Icon(FLucideIcons.moon, size: 16),
                    Text(l10n.dark),
                  ],
                ),
                child: const SizedBox.shrink(),
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
