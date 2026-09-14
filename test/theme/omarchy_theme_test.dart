import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/desktop/omarchy_theme_source.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/omarchy_theme.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  test('maps modern Omarchy tokens to Forui roles', () {
    final colors = buildOmarchyColors(
      const OmarchyThemeSnapshot(
        isAvailable: true,
        values: {
          'mode': 'dark',
          'accent': '#BB9AF7',
          'background': '#05010C',
          'foreground': '#FFFFFF',
          'lighter_background': '#100A1F',
          'muted': '#6B578F',
          'red': '#F07178',
        },
      ),
    );

    expect(colors.brightness, Brightness.dark);
    expect(colors.primary, const Color(0xFFBB9AF7));
    expect(colors.background, const Color(0xFF05010C));
    expect(colors.foreground, Colors.white);
    expect(colors.error, const Color(0xFFF07178));
    expect(colors.systemOverlayStyle, SystemUiOverlayStyle.light);
  });

  test('maps legacy ANSI tokens and infers brightness', () {
    final colors = buildOmarchyColors(
      const OmarchyThemeSnapshot(
        isAvailable: true,
        values: {
          'accent': '#0066CC',
          'background': '#FFFFFF',
          'foreground': '#111111',
          'color0': '#EEEEEE',
          'color1': '#CC0000',
          'color7': '#333333',
        },
      ),
    );

    expect(colors.brightness, Brightness.light);
    expect(colors.primary, const Color(0xFF0066CC));
    expect(colors.card, const Color(0xFFEEEEEE));
    expect(colors.error, const Color(0xFFCC0000));
    expect(colors.systemOverlayStyle, SystemUiOverlayStyle.dark);
  });

  test('uses Omarchy colors when the Omarchy palette is selected', () {
    final theme = buildAppTheme(
      palette: AppPalette.omarchy,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
      omarchyTheme: const OmarchyThemeSnapshot(
        isAvailable: true,
        values: {
          'accent': '#BB9AF7',
          'background': '#05010C',
          'foreground': '#FFFFFF',
        },
      ),
    );

    expect(theme.colors.primary, const Color(0xFFBB9AF7));
    expect(theme.colors.background, const Color(0xFF05010C));
  });

  testWidgets('interpolates the transition to the Omarchy palette', (
    tester,
  ) async {
    var useOmarchy = false;
    late void Function(VoidCallback) rebuild;
    late BuildContext themeContext;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return FTheme(
            data: buildAppTheme(
              palette: useOmarchy ? AppPalette.omarchy : AppPalette.manuscript,
              themeMode: ThemeMode.light,
              touch: false,
              textScale: 1,
              omarchyTheme: useOmarchy
                  ? const OmarchyThemeSnapshot(
                      isAvailable: true,
                      values: {
                        'accent': '#BB9AF7',
                        'background': '#05010C',
                        'foreground': '#FFFFFF',
                      },
                    )
                  : null,
            ),
            child: Builder(
              builder: (context) {
                themeContext = context;
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );

    final before = FTheme.of(themeContext).colors.primary;
    rebuild(() => useOmarchy = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final middle = FTheme.of(themeContext).colors.primary;
    await tester.pump(const Duration(milliseconds: 150));
    final after = FTheme.of(themeContext).colors.primary;

    expect(middle, isNot(before));
    expect(after, const Color(0xFFBB9AF7));
  });
}
