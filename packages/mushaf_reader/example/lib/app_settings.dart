import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// App-wide settings shared between the catalog and demo screens.
class ExampleAppSettings extends InheritedWidget {
  const ExampleAppSettings({
    required this.themeMode,
    required this.toggleThemeMode,
    required super.child,
    super.key,
  });

  final ThemeMode themeMode;
  final VoidCallback toggleThemeMode;

  static ExampleAppSettings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExampleAppSettings>();
    assert(scope != null, 'ExampleAppSettings not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(ExampleAppSettings oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}

/// Theme-aware [MushafStyle] for example demos.
///
/// Basmalah, page-header surah/juz labels, ayah text, and banner surah names
/// all follow the app theme via [ColorScheme.onSurface].
MushafStyle demoMushafStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return MushafStyle.modify(
    ayah: (s) => s.copyWith(color: colors.onSurface),
    basmalah: (s) => s.copyWith(color: colors.onSurface),
    surahName: (s) => s.copyWith(color: colors.onSurface),
    headerSurahName: (s) => s.copyWith(color: colors.onSurface),
    juz: (s) => s.copyWith(color: colors.onSurface),
    pageNumber: (s) => s.copyWith(color: colors.onSurface),
    activeAyah: (s) => s.copyWith(
      backgroundColor: colors.primaryContainer,
      color: colors.onPrimaryContainer,
    ),
    highlightColor: colors.primaryContainer.withValues(alpha: 0.65),
  );
}
