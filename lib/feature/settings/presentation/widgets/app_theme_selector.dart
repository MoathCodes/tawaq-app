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
        // ...AppPalette.values.map((e) => _SingleColorCard(
        //       appPalette: e,
        //       key: ValueKey(e.key),
        //     )),
        ...AppPalette.values.map((e) => _DarkThemeOnlyCard(
              appPalette: e,
              key: ValueKey(e.key),
            )),
      ],
    );
  }
}

class _DarkThemeOnlyCard extends ConsumerWidget {
  final AppPalette appPalette;
  const _DarkThemeOnlyCard({required this.appPalette, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    const resolver = resolveColorScheme;
    final theme = resolver(appPalette, ThemeMode.dark);
    final selectedTheme =
        ref.watch(themeNotifierProvider).valueOrNull ?? defaultTheme;
    final isSelected = selectedTheme.appPalette == appPalette;

    List<Widget> contrast = [
      Expanded(
          child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
          color: theme.colors.primary,
        ),
      )),
      Expanded(
          child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topRight: Radius.circular(16)),
          color: theme.colors.secondary,
        ),
      ))
    ];

    if (locale.value?.languageCode == 'ar') {
      contrast = contrast.reversed.toList();
    }

    return MouseClick(
      onClick: () {
        ref.read(themeNotifierProvider.notifier).setPalette(appPalette);
        ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.dark);
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 80, maxWidth: 175),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(
                    color: selectedTheme.colorScheme.colors.primary,
                    width: 2,
                  )
                : Border.all(
                    color:
                        theme.colors.secondaryForeground.withValues(alpha: .2),
                    width: 1,
                  ),
            borderRadius: BorderRadius.circular(16),
            color: selectedTheme.colorScheme.cardStyle.decoration.color,
          ),
          child: Column(
            spacing: 4,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  flex: 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: contrast,
                  )),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  appPalette.getLocaleName(context.l10n),
                  style: selectedTheme.colorScheme.typography.xs.copyWith(
                      color: selectedTheme.colorScheme.cardStyle.contentStyle
                          .subtitleTextStyle.color,
                      fontWeight: FontWeight.bold),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _SingleColorCard extends ConsumerStatefulWidget {
  final AppPalette appPalette;

  const _SingleColorCard({required this.appPalette});

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
                      ? lightTheme.colors.primary
                      : lightTheme.colors.foreground.withAlpha(100),
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
