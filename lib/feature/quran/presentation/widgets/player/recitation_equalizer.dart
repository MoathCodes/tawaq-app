
import 'package:flutter/widgets.dart';

/// A small three-bar "now playing" equalizer that animates while audio plays.
///
/// Bars pulse on a staggered loop, echoing the gold equalizer in the player
/// design. Purely decorative; [color] sets the bar color.
class RecitationEqualizer extends StatefulWidget {
  /// Creates a [RecitationEqualizer].
  const RecitationEqualizer({
    required this.color,
    this.animating = true,
    this.height = 14,
    this.barWidth = 2.5,
    this.gap = 2,
    super.key,
  });

  /// Bar color.
  final Color color;

  /// When false, bars stay static and the animation controller is paused.
  final bool animating;

  /// Overall height of the tallest bar.
  final double height;

  /// Width of each bar.
  final double barWidth;

  /// Horizontal gap between bars.
  final double gap;

  @override
  State<RecitationEqualizer> createState() => _RecitationEqualizerState();
}

class _RecitationEqualizerState extends State<RecitationEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const _phases = [0.0, 0.2, 0.4];

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant RecitationEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animating != widget.animating) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.animating) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _phases.length; i++) ...[
                  if (i > 0) SizedBox(width: widget.gap),
                  _bar(_phases[i]),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bar(double phase) {
    final t = (_controller.value + phase) % 1.0;
    final scale = widget.animating
        ? 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2)
        : 0.45;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: widget.barWidth,
        height: widget.height * scale,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
