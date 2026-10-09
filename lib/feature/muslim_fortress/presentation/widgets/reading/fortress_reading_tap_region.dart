import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// Activates a reading surface through selectable text without treating
/// selection drags, long presses, or nested controls as activation.
class FortressReadingTapRegion extends StatefulWidget {
  const FortressReadingTapRegion({
    required this.onTap,
    required this.child,
    super.key,
  });
  final VoidCallback onTap;
  final Widget child;

  @override
  State<FortressReadingTapRegion> createState() => _ReadingTapState();
}

class _ReadingTapState extends State<FortressReadingTapRegion> {
  int? _pointer;
  Offset? _start;
  Duration _time = Duration.zero;
  bool _moved = false;
  int? _blocked;

  @override
  Widget build(BuildContext context) => _ReadingTapScope(
    state: this,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (event.buttons != kPrimaryButton) return;
        _pointer = event.pointer;
        _start = event.position;
        _time = event.timeStamp;
        _moved = false;
        _blocked = null;
      },
      onPointerMove: (event) {
        if (event.pointer == _pointer &&
            (event.position - _start!).distance > 6)
          _moved = true;
      },
      onPointerCancel: (_) => _pointer = null,
      onPointerUp: (event) {
        if (event.pointer == _pointer &&
            _blocked != event.pointer &&
            !_moved &&
            event.timeStamp - _time < const Duration(milliseconds: 500))
          widget.onTap();
        _pointer = null;
      },
      child: widget.child,
    ),
  );
}

/// Nested source/detail/share controls handle their own pointer activation.
class FortressReadingTapControl extends StatelessWidget {
  const FortressReadingTapControl({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Listener(
    // Pointer events bubble from children before reaching the reading region.
    onPointerUp: (event) =>
        context
                .getInheritedWidgetOfExactType<_ReadingTapScope>()
                ?.state
                ._blocked =
            event.pointer,
    child: child,
  );
}

class _ReadingTapScope extends InheritedWidget {
  const _ReadingTapScope({required this.state, required super.child});
  final _ReadingTapState state;
  @override
  bool updateShouldNotify(_ReadingTapScope oldWidget) =>
      state != oldWidget.state;
}
