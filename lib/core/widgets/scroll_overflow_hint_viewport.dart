import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/theme/theme.dart';

/// Minimum remaining scroll extent before the “more below” hint appears.
const double kScrollOverflowHintMinExtent = 32;

/// Scroll viewport that shows a subtle chip when more content is below.
class ScrollOverflowHintViewport extends StatefulWidget {
  /// Creates [ScrollOverflowHintViewport].
  const new({
    required this.builder,
    this.showHint = true,
    this.minOverflowExtent = kScrollOverflowHintMinExtent,
    this.hintLabel,
    this.resetTrigger,
    super.key,
  });

  /// Builds the scrollable child. Pass the provided [ScrollController] to it.
  final Widget Function(ScrollController controller) builder;

  /// When false, never shows the overflow hint chip.
  final bool showHint;

  /// Minimum scrollable distance below the viewport to show the hint.
  final double minOverflowExtent;

  /// Optional override for the hint label.
  final String? hintLabel;

  /// When this value changes, scroll position resets and hint visibility
  /// is recalculated (e.g. the current onboarding step index).
  final Object? resetTrigger;

  @override
  State<ScrollOverflowHintViewport> createState() =>
      _ScrollOverflowHintViewportState();
}

class _ScrollOverflowHintViewportState
    extends State<ScrollOverflowHintViewport> {
  late final ScrollController _controller;
  var _showChip = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_syncHintVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncHintVisibility());
  }

  @override
  void didUpdateWidget(covariant ScrollOverflowHintViewport oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.resetTrigger != widget.resetTrigger) {
      _onContentChanged();
      return;
    }

    if (oldWidget.showHint != widget.showHint ||
        oldWidget.minOverflowExtent != widget.minOverflowExtent) {
      _syncHintVisibility();
    }
  }

  void _onContentChanged() {
    if (_showChip) {
      setState(() => _showChip = false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.hasClients && _controller.offset > 0) {
        _controller.jumpTo(0);
      }
      _syncHintVisibility();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncHintVisibility() {
    if (!mounted) return;

    final next = _shouldShowHint(_controller);
    if (next == _showChip) return;
    setState(() => _showChip = next);
  }

  bool _shouldShowHint(ScrollController controller) {
    if (!widget.showHint || !controller.hasClients) return false;
    final remaining =
        controller.position.maxScrollExtent - controller.position.pixels;
    return remaining > widget.minOverflowExtent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = widget.hintLabel ?? l10n.scrollMoreHint;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _syncHintVisibility();
            return false;
          },
          child: widget.builder(_controller),
        ),
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _showChip ? 1 : 0,
            duration: context.theme.durations.fast,
            child: AnimatedSlide(
              offset: _showChip ? Offset.zero : const Offset(0, 0.35),
              duration: context.theme.durations.fast,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ScrollMoreHintChip(label: label),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScrollMoreHintChip extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.88),
        borderRadius: theme.radii.full,
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: colors.barrier.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: [
            Icon(
              FLucideIcons.chevronDown,
              size: 14,
              color: colors.mutedForeground,
            ),
            Text(
              label,
              style: theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
