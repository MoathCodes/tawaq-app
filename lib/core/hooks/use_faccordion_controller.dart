import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';

/// Creates and manages an [FAccordionController] that is automatically
/// disposed when the widget is removed from the tree.
///
///
/// Example:
/// ```dart
/// class MyWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final controller = useFAccordionController();
///     return FAccordion(controller: controller, ...);
///   }
/// }
/// ```
FAccordionController useFAccordionController({
  List<Object?>? keys,
}) {
  return use(
    _FAccordionControllerHook(
      keys: keys,
    ),
  );
}

class _FAccordionControllerHook extends Hook<FAccordionController> {
  const _FAccordionControllerHook({
    super.keys,
  });

  @override
  _FAccordionControllerHookState createState() =>
      _FAccordionControllerHookState();
}

class _FAccordionControllerHookState
    extends HookState<FAccordionController, _FAccordionControllerHook> {
  late final FAccordionController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = FAccordionController();
  }

  @override
  FAccordionController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String get debugLabel => 'useFAccordionController';
}
