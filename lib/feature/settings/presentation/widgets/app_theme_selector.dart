import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class AppThemeSelector extends StatelessWidget {
  const AppThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        ...AppPalette.values.map((e) => _SingleColorCard(
              appPalette: e,
              key: ValueKey(e.key),
            )),
      ],
    );
  }
}

class _SingleColorCard extends ConsumerWidget {
  final AppPalette appPalette;

  const _SingleColorCard({super.key, required this.appPalette});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const resolver = resolveColorScheme;
    final lightColorScheme = resolver(appPalette, ThemeMode.light);
    final darkColorScheme = resolver(appPalette, ThemeMode.dark);
    final selectedTheme =
        ref.watch(themeNotifierProvider).valueOrNull ?? defaultTheme;
    final isSelected = selectedTheme.appPalette == appPalette;
    final isDarkThemeSelected = selectedTheme.themeMode == ThemeMode.dark;

    return OutlinedContainer(
        width: 180,
        height: 120,
        borderColor: isSelected
            ? lightColorScheme.primary
            : lightColorScheme.foreground.withAlpha(100),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(appPalette.getLocaleName(context.l10n)).bold,
            Row(
              spacing: 5,
              children: [
                Expanded(
                  child: MouseClick(
                    onClick: () {
                      ref
                          .read(themeNotifierProvider.notifier)
                          .setPalette(appPalette);
                      ref
                          .read(themeNotifierProvider.notifier)
                          .setThemeMode(ThemeMode.light);
                    },
                    child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected && !isDarkThemeSelected
                              ? Border.all(color: lightColorScheme.primary)
                              : null,
                          color: lightColorScheme.primaryForeground,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          context.l10n.light,
                          style: TextStyle(color: lightColorScheme.primary),
                          textAlign: TextAlign.center,
                        )),
                  ),
                ),
                Expanded(
                  child: MouseClick(
                    onClick: () {
                      ref
                          .read(themeNotifierProvider.notifier)
                          .setPalette(appPalette);
                      ref
                          .read(themeNotifierProvider.notifier)
                          .setThemeMode(ThemeMode.dark);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected && isDarkThemeSelected
                            ? Border.all(color: darkColorScheme.primary)
                            : null,
                        color: darkColorScheme.primaryForeground,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        context.l10n.dark,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: darkColorScheme.primary),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ));
  }
}
