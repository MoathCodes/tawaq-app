import 'package:example/app_settings.dart';
import 'package:example/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// Shared chrome for every demo screen.
class DemoScaffold extends StatelessWidget {
  const DemoScaffold({
    required this.title,
    required this.body,
    this.actions = const [],
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final settings = ExampleAppSettings.of(context);
    final isDark = settings.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...actions,
          IconButton(
            tooltip: t.common.themeToggle,
            onPressed: settings.toggleThemeMode,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: t.common.localeToggle,
            onPressed: () {
              final next = LocaleSettings.currentLocale == AppLocale.en
                  ? AppLocale.ar
                  : AppLocale.en;
              LocaleSettings.setLocale(next);
            },
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: body,
    );
  }
}
