import 'package:example/app_settings.dart';
import 'package:example/demo_catalog.dart';
import 'package:example/demo_scaffold.dart';
import 'package:example/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Use an app-specific subdirectory (same pattern as tawaq's `subDirectory: 'tawaq'`)
  // so hive boxes are not shared with other apps or stale files under ~/Documents/.
  await MushafReaderLibrary.ensureInitialized(
    subDirectory: 'mushaf_reader_example',
  );
  LocaleSettings.useDeviceLocale();
  runApp(TranslationProvider(child: const MushafExampleApp()));
}

class MushafExampleApp extends StatefulWidget {
  const MushafExampleApp({super.key});

  @override
  State<MushafExampleApp> createState() => _MushafExampleAppState();
}

class _MushafExampleAppState extends State<MushafExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleThemeMode() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  static ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B4332),
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExampleAppSettings(
      themeMode: _themeMode,
      toggleThemeMode: _toggleThemeMode,
      child: MaterialApp(
        title: 'Mushaf Reader Example',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) {
          final isRtl = LocaleSettings.currentLocale == AppLocale.ar;
          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          );
        },
        home: const DemoCatalogScreen(),
      ),
    );
  }
}

/// Home screen listing all widget demos grouped by category.
class DemoCatalogScreen extends StatelessWidget {
  const DemoCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = buildMushafDemoSections();

    return DemoScaffold(
      title: t.appTitle,
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  t.gettingStarted,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                section.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            for (final demo in section.demos)
              ListTile(
                leading: Icon(demo.icon),
                title: Text(demo.title),
                subtitle: Text(demo.subtitle),
                trailing: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: demo.builder),
                  );
                },
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
