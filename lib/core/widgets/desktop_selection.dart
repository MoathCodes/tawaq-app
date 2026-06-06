import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/utils/platform.dart';

/// Theme-aligned colors for standalone selectable text on desktop.
({Color selectionColor, Color cursorColor}) desktopTextSelectionColors(
  BuildContext context,
) {
  final primary = FTheme.of(context).colors.primary;
  return (
    selectionColor: primary.withValues(alpha: 0.28),
    cursorColor: primary,
  );
}

/// Plain text that opts out of [SelectionArea] but keeps native single
/// click-drag selection (for content inside scrollables).
class ScopedSelectableText extends StatelessWidget {
  /// Creates scoped selectable text.
  const ScopedSelectableText(
    this.data, {
    required this.style,
    super.key,
    this.textAlign,
    this.textDirection,
    this.maxLines,
  });

  /// The text to display.
  final String data;

  /// Style for the text.
  final TextStyle style;

  /// Optional alignment.
  final TextAlign? textAlign;

  /// Optional reading direction.
  final TextDirection? textDirection;

  /// Optional line limit.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform) {
      return Text(
        data,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
      );
    }

    final (:selectionColor, :cursorColor) = desktopTextSelectionColors(context);
    return NonSelectable(
      child: SelectableText(
        data,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        selectionColor: selectionColor,
        cursorColor: cursorColor,
      ),
    );
  }
}

/// Rich text with the same scoped selection behavior as [ScopedSelectableText].
class ScopedSelectableRichText extends StatelessWidget {
  /// Creates scoped selectable rich text.
  const ScopedSelectableRichText(
    this.textSpan, {
    super.key,
    this.textAlign,
    this.textDirection = TextDirection.rtl,
    this.strutStyle,
  });

  /// The rich text span tree.
  final TextSpan textSpan;

  /// Optional alignment.
  final TextAlign? textAlign;

  /// Reading direction.
  final TextDirection textDirection;

  /// Optional strut style for uniform line metrics across mixed spans.
  final StrutStyle? strutStyle;

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform) {
      return RichText(
        text: textSpan,
        textAlign: textAlign ?? TextAlign.start,
        textDirection: textDirection,
      );
    }

    final (:selectionColor, :cursorColor) = desktopTextSelectionColors(context);
    return NonSelectable(
      child: SelectableText.rich(
        textSpan,
        textAlign: textAlign,
        textDirection: textDirection,
        strutStyle: strutStyle,
        selectionColor: selectionColor,
        cursorColor: cursorColor,
      ),
    );
  }
}

/// Enables [SelectionArea] on desktop; passthrough on other platforms.
class DesktopSelectionArea extends StatelessWidget {
  /// Creates a desktop-only selection region.
  const DesktopSelectionArea({required this.child, super.key});

  /// The subtree whose plain [Text] widgets become selectable on desktop.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform) return child;

    final (:selectionColor, :cursorColor) = desktopTextSelectionColors(context);
    return DefaultSelectionStyle(
      selectionColor: selectionColor,
      cursorColor: cursorColor,
      child: SelectionArea(child: child),
    );
  }
}

/// Opts a subtree out of an ancestor [SelectionArea]
/// (browser `user-select: none`).
class NonSelectable extends StatelessWidget {
  /// Creates a non-selectable subtree.
  const NonSelectable({required this.child, super.key});

  /// The subtree that must not participate in text selection.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(child: child);
  }
}
