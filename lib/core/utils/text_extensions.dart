// text_extensions.dart
import 'package:flutter/material.dart';
import 'package:forui/theme.dart';
// ← adjust to your real import path for FTheme

extension FTextSizing on Text {
  Widget get base => _withStyle((ctx) => FTheme.of(ctx).typography.base);
  Widget get bold => _withStyle((ctx) =>
      style?.copyWith(fontWeight: FontWeight.bold) ??
      FTheme.of(ctx).typography.base.copyWith(fontWeight: FontWeight.bold));
  Widget get lg => _withStyle((ctx) => FTheme.of(ctx).typography.lg);
  Widget get mute => _withStyle((ctx) =>
      style?.copyWith(color: FTheme.of(ctx).colors.muted) ??
      FTheme.of(ctx)
          .typography
          .base
          .copyWith(color: FTheme.of(ctx).colors.muted));
  Widget get sm => _withStyle((ctx) => FTheme.of(ctx).typography.sm);
  Widget get xl => _withStyle((ctx) => FTheme.of(ctx).typography.xl);
  Widget get xl2 => _withStyle((ctx) => FTheme.of(ctx).typography.xl2);
  Widget get xl3 => _withStyle((ctx) => FTheme.of(ctx).typography.xl3);
  Widget get xl4 => _withStyle((ctx) => FTheme.of(ctx).typography.xl4);
  Widget get xl5 => _withStyle((ctx) => FTheme.of(ctx).typography.xl5);
  Widget get xl6 => _withStyle((ctx) => FTheme.of(ctx).typography.xl6);
  Widget get xl7 => _withStyle((ctx) => FTheme.of(ctx).typography.xl7);
  Widget get xl8 => _withStyle((ctx) => FTheme.of(ctx).typography.xl8);
  Widget get xs => _withStyle((ctx) => FTheme.of(ctx).typography.xs);

  Widget _withStyle(TextStyle Function(BuildContext) styleLookup) {
    return Builder(builder: (ctx) {
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
          textScaleFactor: textScaleFactor,
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
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
        );
      }

      // fallback—should never happen
      return const SizedBox.shrink();
    });
  }
}
