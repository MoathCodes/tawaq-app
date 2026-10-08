import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:tawaq/theme/theme.dart';

/// Restores reading position after asynchronous content establishes its extent.
class HadithReaderScroll extends StatefulWidget {
  const HadithReaderScroll({
    required this.child,
    required this.ready,
    required this.initialOffset,
    required this.onOffsetChanged,
    super.key,
  });
  final Widget child;
  final bool ready;
  final double initialOffset;
  final ValueChanged<double> onOffsetChanged;
  @override
  State<HadithReaderScroll> createState() => _HadithReaderScrollState();
}

class _HadithReaderScrollState extends State<HadithReaderScroll> {
  final _controller = ScrollController();
  bool _restored = false;
  bool _restoring = false;
  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  void _changed() {
    if (_restored && !_restoring) widget.onOffsetChanged(_controller.offset);
  }

  void _restore() {
    if (!mounted || _restored || !widget.ready || !_controller.hasClients)
      return;
    _restoring = true;
    _controller.jumpTo(
      widget.initialOffset.clamp(0, _controller.position.maxScrollExtent),
    );
    _restoring = false;
    _restored = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
    return NotificationListener<UserScrollNotification>(
      onNotification: (event) {
        // Explicit user scrolling takes precedence over a delayed restoration.
        if (event.direction != ScrollDirection.idle) _restored = true;
        return false;
      },
      child: SingleChildScrollView(
        controller: _controller,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: widget.child,
      ),
    );
  }
}
