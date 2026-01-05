import 'package:flutter/material.dart';
import 'package:hasanat/core/hooks/hooks.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Widget for selecting the application theme palette.
class AppThemeSelector extends StatelessWidget {
  /// Creates a new [AppThemeSelector] instance.
  const AppThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ...AppPalette.values.map(
          (e) => _SingleColorCard(
            appPalette: e,
            key: ValueKey(e.key),
          ),
        ),
      ],
    );
  }
}

class _SingleColorCard extends HookConsumerWidget {
  const _SingleColorCard({required this.appPalette, super.key});
  final AppPalette appPalette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:isHovered, :setHovered) = useHoverState();
    const resolver = resolveColorScheme;
    final lightTheme = resolver(appPalette, ThemeMode.light);
    final darkTheme = resolver(appPalette, ThemeMode.dark);
    final selectedTheme = ref.watch(themeProvider).value ?? defaultTheme;
    final isSelected = selectedTheme.appPalette == appPalette;
    final isDarkThemeSelected = selectedTheme.themeMode == ThemeMode.dark;

    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      scale: isHovered ? 1.05 : 1,
      child: MouseClick(
        onExit: (p0) => setHovered(false),
        onHover: (p0) => setHovered(true),
        onClick: () {
          if (isSelected) {
            ref
                .read(themeProvider.notifier)
                .setThemeMode(
                  isSelected && isDarkThemeSelected
                      ? ThemeMode.light
                      : ThemeMode.dark,
                );
          } else {
            ref.read(themeProvider.notifier).setPalette(appPalette);
            ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
          }
        },
        child: Container(
          width: 180,
          height: 120,
          decoration: BoxDecoration(
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedTheme.colorScheme.colors.primary.withAlpha(
                        60,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            color: selectedTheme.colorScheme.colors.background,
            border: Border.all(
              color: isSelected
                  ? selectedTheme.colorScheme.colors.primary
                  : selectedTheme.colorScheme.colors.secondaryForeground
                        .withAlpha(100),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const .all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: .spaceEvenly,
            children: [
              Text(appPalette.getLocaleName(context.l10n)),
              Row(
                spacing: 5,
                children: [
                  Expanded(
                    child: MouseClick(
                      onClick: () {
                        ref.read(themeProvider.notifier).setPalette(appPalette);
                        ref
                            .read(themeProvider.notifier)
                            .setThemeMode(ThemeMode.light);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected && !isDarkThemeSelected
                              ? Border.all(color: lightTheme.colors.primary)
                              : null,
                          color: lightTheme.colors.background,
                        ),
                        padding: const .all(AppSpacing.md),
                        child: Text(
                          context.l10n.light,
                          style: TextStyle(color: lightTheme.colors.primary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: MouseClick(
                      onClick: () {
                        ref.read(themeProvider.notifier).setPalette(appPalette);
                        ref
                            .read(themeProvider.notifier)
                            .setThemeMode(ThemeMode.dark);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected && isDarkThemeSelected
                              ? Border.all(color: darkTheme.colors.primary)
                              : null,
                          color: darkTheme.colors.background,
                        ),
                        padding: const .all(AppSpacing.md),
                        child: Text(
                          context.l10n.dark,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: darkTheme.colors.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
