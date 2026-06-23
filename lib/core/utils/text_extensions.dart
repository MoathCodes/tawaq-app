// text_extensions.dart
import 'package:flutter/material.dart';
import 'package:forui/theme.dart';
// ← adjust to your real import path for FTheme

/// Text styling helpers that apply the app's [FTheme] typography presets to a
/// [Text] widget. Use these getters to quickly obtain a thematically styled
/// `Text` widget while preserving any explicitly provided properties.
extension FTextSizing on Text {
  /// Applies the base (default) typographic style from the current theme.
  Widget get base => _withStyle((ctx) => FTheme.of(ctx).typography.body.md);

  // /// Applies a bold font weight to the text.
  // Widget get bold => _withStyle(
  //   (ctx) =>
  //       style?.copyWith(fontWeight: FontWeight.bold) ??
  //       FTheme.of(ctx).typography.body.md.copyWith(fontWeight: FontWeight.bold),
  // );

  /// Applies the large text style from the current theme.
  Widget get lg => _withStyle((ctx) => FTheme.of(ctx).typography.body.lg);

  /// Applies the muted foreground color from the current theme.
  Widget get mute => _withStyle(
    (ctx) =>
        style?.copyWith(color: FTheme.of(ctx).colors.muted) ??
        FTheme.of(
          ctx,
        ).typography.body.md.copyWith(color: FTheme.of(ctx).colors.muted),
  );

  /// Applies the small text style from the current theme.
  Widget get sm => _withStyle((ctx) => FTheme.of(ctx).typography.body.sm);

  /// Applies the extra-large text style (level 1) from the current theme.
  Widget get xl => _withStyle((ctx) => FTheme.of(ctx).typography.body.xl);

  /// Applies the extra-large text style (level 2) from the current theme.
  Widget get xl2 => _withStyle((ctx) => FTheme.of(ctx).typography.body.xl2);

  /// Applies the extra-large text style (level 3) from the current theme.
  Widget get xl3 => _withStyle((ctx) => FTheme.of(ctx).typography.body.xl3);

  /// Applies the extra-large text style (level 4) from the current theme.
  Widget get xl4 => _withStyle((ctx) => FTheme.of(ctx).typography.body.xl4);

  /// Applies the extra-large text style (level 5) from the current theme.
  Widget get xl5 => _withStyle((ctx) => FTheme.of(ctx).typography.body.xl5);

  /// Applies the extra-large text style (level 6) from the current theme.
  Widget get xl6 => _withStyle((ctx) => FTheme.of(ctx).typography.body.xl6);

  /// Applies the extra-large text style (level 7) from the current theme.
  Widget get xl7 => _withStyle((ctx) => FTheme.of(ctx).typography.body.xl7);

  /// Applies the extra-large text style (level 8) from the current theme.
  Widget get xl8 => _withStyle((ctx) => FTheme.of(ctx).typography.body.xl8);

  /// Applies the extra-small text style from the current theme.
  Widget get xs => _withStyle((ctx) => FTheme.of(ctx).typography.body.xs);

  /// A private helper that rebuilds the [Text] widget with a new style.
  ///
  /// This function takes a `styleLookup` function that returns a [TextStyle]
  /// based on the current [BuildContext]. It then merges the new style with
  /// the existing style of the [Text] widget and rebuilds it with the
  /// merged style.
  Widget _withStyle(TextStyle Function(BuildContext) styleLookup) {
    return Builder(
      builder: (ctx) {
        final themeStyle = styleLookup(ctx);
        final mergedStyle = style?.merge(themeStyle) ?? themeStyle;

        if (data != null) {
          return Text(
            data!,
            key: key,
            style: mergedStyle,
            strutStyle: strutStyle,
            textAlign: textAlign,
            textDirection: textDirection,
            locale: locale,
            softWrap: softWrap,
            overflow: overflow,
            textScaler: textScaler,
            maxLines: maxLines,
            semanticsLabel: semanticsLabel,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior,
          );
        }

        // if it was built with Text.rich(...)
        if (textSpan != null) {
          return Text.rich(
            textSpan!,
            key: key,
            style: mergedStyle,
            strutStyle: strutStyle,
            textAlign: textAlign,
            textDirection: textDirection,
            locale: locale,
            softWrap: softWrap,
            overflow: overflow,
            textScaler: textScaler,
            maxLines: maxLines,
            semanticsLabel: semanticsLabel,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior,
          );
        }

        // fallback—should never happen
        return const SizedBox.shrink();
      },
    );
  }
}
