import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';

/// Creates and manages an [FCalendarController] for single date selection
/// that is automatically disposed when the widget is removed from the tree.
///
/// [initial] sets the initially selected date.
/// [toggleable] determines if the selection can be toggled off.
///
/// Example:
/// ```dart
/// class MyWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final controller = useFCalendarController(
///       initial: DateTime.now(),
///       toggleable: false,
///     );
///     return FCalendar(controller: controller, ...);
///   }
/// }
/// ```
FCalendarController<DateTime?> useFCalendarController({
  DateTime? initial,
  bool toggleable = true,
  List<Object?>? keys,
}) {
  return use(
    _FCalendarControllerHook(
      initial: initial,
      toggleable: toggleable,
      keys: keys,
    ),
  );
}

class _FCalendarControllerHook extends Hook<FCalendarController<DateTime?>> {
  const _FCalendarControllerHook({
    this.initial,
    this.toggleable = true,
    super.keys,
  });

  final DateTime? initial;
  final bool toggleable;

  @override
  _FCalendarControllerHookState createState() =>
      _FCalendarControllerHookState();
}

class _FCalendarControllerHookState extends HookState<
    FCalendarController<DateTime?>, _FCalendarControllerHook> {
  late final FCalendarController<DateTime?> _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = FCalendarController.date(
      initial: hook.initial,
      toggleable: hook.toggleable,
    );
  }

  @override
  FCalendarController<DateTime?> build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String get debugLabel => 'useFCalendarController';
}
