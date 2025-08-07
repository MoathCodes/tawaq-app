import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';

class AppThemeSelector extends StatelessWidget {
  const AppThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
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

class _SingleColorCard extends ConsumerStatefulWidget {
  final AppPalette appPalette;

  const _SingleColorCard({super.key, required this.appPalette});

  @override
  ConsumerState<_SingleColorCard> createState() => _SingleColorCardState();
}

class _SingleColorCardState extends ConsumerState<_SingleColorCard> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    const resolver = resolveColorScheme;
    final lightTheme = resolver(widget.appPalette, ThemeMode.light);
    final darkTheme = resolver(widget.appPalette, ThemeMode.dark);
    final selectedTheme =
        ref.watch(themeNotifierProvider).valueOrNull ?? defaultTheme;
    final isSelected = selectedTheme.appPalette == widget.appPalette;
    final isDarkThemeSelected = selectedTheme.themeMode == ThemeMode.dark;

    return AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _isHovered ? 1.05 : 1,
        child: MouseClick(
          onExit: (p0) {
            setState(() {
              _isHovered = false;
            });
          },
          onHover: (p0) {
            setState(() {
              _isHovered = true;
            });
          },
          onClick: () {
            if (isSelected) {
              ref.read(themeNotifierProvider.notifier).setThemeMode(
                  isSelected && isDarkThemeSelected
                      ? ThemeMode.light
                      : ThemeMode.dark);
            } else {
              ref
                  .read(themeNotifierProvider.notifier)
                  .setPalette(widget.appPalette);
              ref
                  .read(themeNotifierProvider.notifier)
                  .setThemeMode(ThemeMode.light);
            }
          },
          child: Container(
              width: 180,
              height: 120,
              decoration: BoxDecoration(
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: selectedTheme.colorScheme.colors.primary
                              .withAlpha(60),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
                color: isSelected
                    ? selectedTheme.colorScheme.colors.background
                    : null,
                border: Border.all(
                  color: isSelected
                      ? selectedTheme.colorScheme.colors.primary
                      : selectedTheme.colorScheme.colors.secondaryForeground
                          .withAlpha(100),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(widget.appPalette.getLocaleName(context.l10n)),
                  Row(
                    spacing: 5,
                    children: [
                      Expanded(
                        child: MouseClick(
                          onClick: () {
                            ref
                                .read(themeNotifierProvider.notifier)
                                .setPalette(widget.appPalette);
                            ref
                                .read(themeNotifierProvider.notifier)
                                .setThemeMode(ThemeMode.light);
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected && !isDarkThemeSelected
                                    ? Border.all(
                                        color: lightTheme.colors.primary)
                                    : null,
                                color: lightTheme.colors.primaryForeground,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                context.l10n.light,
                                style:
                                    TextStyle(color: lightTheme.colors.primary),
                                textAlign: TextAlign.center,
                              )),
                        ),
                      ),
                      Expanded(
                        child: MouseClick(
                          onClick: () {
                            ref
                                .read(themeNotifierProvider.notifier)
                                .setPalette(widget.appPalette);
                            ref
                                .read(themeNotifierProvider.notifier)
                                .setThemeMode(ThemeMode.dark);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected && isDarkThemeSelected
                                  ? Border.all(color: darkTheme.colors.primary)
                                  : null,
                              color: darkTheme.colors.primaryForeground,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              context.l10n.dark,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: darkTheme.colors.primary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              )),
        ));
  }
}
