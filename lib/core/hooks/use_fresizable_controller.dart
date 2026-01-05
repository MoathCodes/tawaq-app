import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';

/// Creates and manages an [FResizableController] that is automatically
/// disposed when the widget is removed from the tree.
///
///
/// Example:
/// ```dart
/// class MyWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final controller = useFResizableController();
///     return FAccordion(controller: controller, ...);
///   }
/// }
/// ```
FResizableController useFResizableController({
  List<Object?>? keys,
}) {
  return use(
    _FResizableControllerHook(
      keys: keys,
    ),
  );
}

class _FResizableControllerHook extends Hook<FResizableController> {
  const _FResizableControllerHook({
    super.keys,
  });

  @override
  _FResizableControllerHookState createState() =>
      _FResizableControllerHookState();
}

class _FResizableControllerHookState
    extends HookState<FResizableController, _FResizableControllerHook> {
  late final FResizableController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = FResizableController();
  }

  @override
  FResizableController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String get debugLabel => 'useFResizableController';
}
