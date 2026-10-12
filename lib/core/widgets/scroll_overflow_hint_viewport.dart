import 'dart:async';

import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/reduce_motion.dart';
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
  var _syncScheduled = false;

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      _syncHintVisibility();
    });
    // Metrics may arrive during post-frame callbacks. Drive the next frame
    // so that initial or asynchronously added overflow needs no user scroll.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _scrollDown() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final target = (position.pixels + position.viewportDimension * 0.75).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (reduceMotion(context)) {
      _controller.jumpTo(target);
    } else {
      unawaited(
        _controller.animateTo(
          target,
          duration: context.theme.durations.normal,
          curve: Curves.easeOut,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_syncHintVisibility);
    _scheduleSync();
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
    if (!widget.showHint ||
        !controller.hasClients ||
        !controller.position.hasContentDimensions)
      return false;
    final remaining =
        controller.position.maxScrollExtent - controller.position.pixels;
    return remaining > widget.minOverflowExtent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = widget.hintLabel ?? l10n.scrollMoreHint;
    final duration = reduceMotion(context)
        ? Duration.zero
        : context.theme.durations.fast;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            if (notification.depth == 0) _scheduleSync();
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.depth == 0) _syncHintVisibility();
              return false;
            },
            child: widget.builder(_controller),
          ),
        ),
        IgnorePointer(
          ignoring: !_showChip,
          child: ExcludeFocus(
            excluding: !_showChip,
            child: ExcludeSemantics(
              excluding: !_showChip,
              child: AnimatedOpacity(
                opacity: _showChip ? 1 : 0,
                duration: duration,
                child: AnimatedSlide(
                  offset: _showChip ? Offset.zero : const Offset(0, 0.35),
                  duration: duration,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ScrollMoreHintChip(
                      label: label,
                      onPress: _scrollDown,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScrollMoreHintChip extends StatelessWidget {
  const new({required this.label, required this.onPress});

  final String label;
  final VoidCallback onPress;

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
      child: FButton(
        mainAxisSize: MainAxisSize.min,
        variant: .ghost,
        onPress: onPress,
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
