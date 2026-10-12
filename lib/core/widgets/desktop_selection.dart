import 'package:flutter/rendering.dart'
    show ClearSelectionEvent, Selectable, SelectedContent;
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
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

/// Plain text participating in the shared desktop reading selection region.
/// Mouse anchors use the displayed paragraph, without an editable viewport.
class ScopedSelectableText extends StatelessWidget {
  /// Creates scoped selectable text.
  const new(
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

    return Directionality(
      textDirection: textDirection ?? Directionality.of(context),
      child: DesktopSelectionArea(
        child: Text(
          data,
          style: style,
          softWrap: true,
          overflow: TextOverflow.clip,
          textAlign: textAlign,
          textDirection: textDirection,
          maxLines: maxLines,
        ),
      ),
    );
  }
}

/// Rich text with the same scoped selection behavior as [ScopedSelectableText].
class ScopedSelectableRichText extends StatelessWidget {
  /// Creates scoped selectable rich text.
  const new(
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

    return Directionality(
      textDirection: textDirection,
      child: DesktopSelectionArea(
        child: Text.rich(
          textSpan,
          style: textSpan.style,
          softWrap: true,
          overflow: TextOverflow.clip,
          textAlign: textAlign,
          textDirection: textDirection,
          strutStyle: strutStyle,
        ),
      ),
    );
  }
}

/// Owns desktop reading selection; nested instances share the existing region.
/// Standalone dialogs and previews receive the same behavior through a fallback.
class DesktopSelectionArea extends StatelessWidget {
  /// Creates a desktop-only selection region.
  const new({required this.child, super.key});

  /// The subtree whose plain [Text] widgets become selectable on desktop.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final container = context
        .findAncestorWidgetOfExactType<SelectionContainer>();
    if (!isDesktopPlatform ||
        SelectionContainer.maybeOf(context) != null ||
        (container != null && container.delegate == null)) {
      return child;
    }

    final (:selectionColor, :cursorColor) = desktopTextSelectionColors(context);
    return DefaultSelectionStyle(
      selectionColor: selectionColor,
      cursorColor: cursorColor,
      child: _DesktopSelectionRegion(
        child: DesktopSelectionDocument(child: child),
      ),
    );
  }
}

/// Opts a subtree out of an ancestor [SelectionArea]
/// (browser `user-select: none`).
class NonSelectable extends StatelessWidget {
  /// Creates a non-selectable subtree.
  const new({required this.child, super.key});

  /// The subtree that must not participate in text selection.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(child: child);
  }
}

/// Keeps clipboard paragraph boundaries inside a shared selection region.
/// Place around logical reading blocks, inside any surrounding scroll view.
class DesktopSelectionDocument extends StatefulWidget {
  /// Creates a paragraph-aware reading document.
  const new({required this.child, super.key});

  /// Paragraphs and other logical reading blocks.
  final Widget child;

  @override
  State<DesktopSelectionDocument> createState() =>
      _DesktopSelectionDocumentState();
}

class _DesktopSelectionDocumentState extends State<DesktopSelectionDocument> {
  final _delegate = _ParagraphSelectionDelegate();

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform) return widget.child;
    return DesktopSelectionArea(
      child: SelectionContainer(delegate: _delegate, child: widget.child),
    );
  }
}

class _ParagraphSelectionDelegate extends StaticSelectionContainerDelegate {
  bool _removedSelectionEdge = false;

  @override
  void remove(Selectable selectable) {
    for (final index in [
      currentSelectionStartIndex,
      currentSelectionEndIndex,
    ]) {
      if (index >= 0 &&
          index < selectables.length &&
          selectables[index] == selectable) {
        _removedSelectionEdge = true;
      }
    }
    super.remove(selectable);
  }

  @override
  void didChangeSelectables() {
    // StaticSelectionContainerDelegate replays cached edge positions before
    // updating geometry. A removed edge can leave a visible cached point with
    // an invalid index. Retire that selection before replaying it into new text.
    if (_removedSelectionEdge) {
      _removedSelectionEdge = false;
      dispatchSelectionEvent(const ClearSelectionEvent());
    }
    super.didChangeSelectables();
  }

  @override
  SelectedContent? getSelectedContent() {
    final paragraphs = [
      for (final selectable in selectables)
        if (selectable.getSelectedContent() case final SelectedContent content)
          if (content.plainText.isNotEmpty) content.plainText,
    ];
    return paragraphs.isEmpty
        ? null
        : SelectedContent(plainText: paragraphs.join('\n'));
  }
}

class _DesktopSelectionRegion extends StatefulWidget {
  const _DesktopSelectionRegion({required this.child});
  final Widget child;

  @override
  State<_DesktopSelectionRegion> createState() =>
      _DesktopSelectionRegionState();
}

class _DesktopSelectionRegionState extends State<_DesktopSelectionRegion> {
  final _focus = FocusNode(debugLabel: 'Desktop reading selection');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SelectionArea(
    focusNode: _focus,
    child: Builder(
      builder: (regionContext) => Actions(
        actions: {
          ExtendSelectionVerticallyToAdjacentLineIntent: _CaretSelectionAction(
            regionContext,
          ),
        },
        child: widget.child,
      ),
    ),
  );
}

// Flutter 3.47's vertical selection action casts EditableText's caret action to
// a concrete intent type. Forward through the common caret type so input keys
// reach the editable action, while reading keys retain the region's behavior.
class _CaretSelectionAction extends Action<DirectionalCaretMovementIntent> {
  _CaretSelectionAction(this.regionContext);
  final BuildContext regionContext;

  Action<DirectionalCaretMovementIntent>? _action(
    DirectionalCaretMovementIntent intent,
  ) => callingAction ?? Actions.maybeFind(regionContext, intent: intent);

  @override
  bool isEnabled(DirectionalCaretMovementIntent intent) =>
      _action(intent)?.isEnabled(intent) ?? false;

  @override
  bool consumesKey(DirectionalCaretMovementIntent intent) =>
      _action(intent)?.consumesKey(intent) ?? false;

  @override
  Object? invoke(DirectionalCaretMovementIntent intent) {
    if (callingAction case final action?) return action.invoke(intent);
    return Actions.invoke(regionContext, intent);
  }
}

/// Keeps contextual shortcuts below a shared reading region's selection focus.
/// Only the pointer-hit scope adopts focus; inputs and controls retain theirs.
class DesktopSelectionFocusAnchor extends StatefulWidget {
  /// Creates a focus anchor for contextual reading shortcuts.
  const new({
    required this.child,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Content governed by the surrounding shortcut scope.
  final Widget child;

  /// An existing reading focus node, when the caller owns one.
  final FocusNode? focusNode;

  /// Whether the contextual reading scope initially requests focus.
  final bool autofocus;

  @override
  State<DesktopSelectionFocusAnchor> createState() =>
      _DesktopSelectionFocusAnchorState();
}

class _DesktopSelectionFocusAnchorState
    extends State<DesktopSelectionFocusAnchor> {
  final _ownedFocus = FocusNode(debugLabel: 'Reading shortcut anchor');

  void _adoptSelectionFocus(PointerEvent event) {
    final area = context.findAncestorStateOfType<SelectionAreaState>();
    if (area == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          FocusManager.instance.primaryFocus == area.widget.focusNode) {
        (widget.focusNode ?? _ownedFocus).requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _ownedFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: widget.focusNode ?? _ownedFocus,
    autofocus: widget.autofocus,
    child: Listener(
      onPointerDown: _adoptSelectionFocus,
      onPointerUp: _adoptSelectionFocus,
      child: widget.child,
    ),
  );
}
