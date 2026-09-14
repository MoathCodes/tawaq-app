import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/desktop/omarchy_theme_source.dart';

Color _parseColor(String? value, Color fallback) {
  if (value == null) return fallback;
  final normalized = value.trim().replaceFirst('#', '').replaceFirst('0x', '');
  try {
    final hex = normalized.length == 3
        ? normalized.split('').map((value) => '$value$value').join()
        : normalized;
    final parsed = int.parse(hex, radix: 16);
    return Color(hex.length == 8 ? parsed : 0xFF000000 | parsed);
  } on FormatException {
    return fallback;
  }
}

Color _token(
  OmarchyThemeSnapshot theme,
  Iterable<String> keys,
  Color fallback,
) {
  for (final key in keys) {
    final value = theme.colorToken(key);
    if (value != null) return _parseColor(value, fallback);
  }
  return fallback;
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance();
  final darker = background.computeLuminance();
  final high = lighter > darker ? lighter : darker;
  final low = lighter > darker ? darker : lighter;
  return (high + 0.05) / (low + 0.05);
}

Color _onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;

Color _readableForeground({
  required Color background,
  required Iterable<Color> candidates,
}) {
  for (final candidate in candidates) {
    if (_contrastRatio(candidate, background) >= 4.5) return candidate;
  }
  return _onColor(background);
}

/// Converts an Omarchy palette into the Forui color roles used by Tawaq.
///
/// Both current named tokens and older ANSI `color0`-`color15` tokens are
/// supported because user-installed Omarchy themes may use either format.
FColors buildOmarchyColors(OmarchyThemeSnapshot theme) {
  final background = _token(
    theme,
    const ['background'],
    const Color(0xFF1A1B26),
  );
  final foreground = _token(
    theme,
    const ['foreground'],
    const Color(0xFFA9B1D6),
  );
  final accent = _token(
    theme,
    const ['accent', 'blue', 'color4'],
    foreground,
  );
  final card = _token(
    theme,
    const ['lighter_background', 'color0'],
    Color.lerp(background, foreground, 0.08)!,
  );
  final muted = _token(
    theme,
    const ['muted', 'color8'],
    Color.lerp(background, foreground, 0.16)!,
  );
  final error = _token(theme, const ['red', 'color1'], const Color(0xFFE5484D));
  final primaryForeground = _token(
    theme,
    const ['selection_foreground'],
    _onColor(accent),
  );
  final secondaryForeground = _readableForeground(
    background: card,
    candidates: [foreground, _onColor(card)],
  );
  final mutedForeground = _readableForeground(
    background: background,
    candidates: [
      _token(theme, const [
        'light_foreground',
        'bright_foreground',
      ], foreground),
      _token(theme, const ['color7'], foreground),
      foreground,
    ],
  );
  final brightness = theme.values['mode'] == 'light'
      ? Brightness.light
      : theme.values['mode'] == 'dark'
      ? Brightness.dark
      : ThemeData.estimateBrightnessForColor(background);

  return FColors(
    brightness: brightness,
    systemOverlayStyle: brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
    barrier: Colors.black.withValues(
      alpha: brightness == Brightness.dark ? 0.75 : 0.15,
    ),
    background: background,
    foreground: foreground,
    primary: accent,
    primaryForeground: primaryForeground,
    secondary: card,
    secondaryForeground: secondaryForeground,
    muted: muted,
    mutedForeground: mutedForeground,
    destructive: error,
    destructiveForeground: _onColor(error),
    error: error,
    errorForeground: _onColor(error),
    card: card,
    border: muted,
  );
}
