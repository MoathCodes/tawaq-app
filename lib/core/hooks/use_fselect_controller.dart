import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';

/// Creates and manages an [FSelectController] that is automatically
/// disposed when the widget is removed from the tree.
///
/// [T] is the type of values that can be selected.
/// [initialValue] sets the initially selected value.

///
/// Example:
/// ```dart
/// class MyWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final tickerProvider = useSingleTickerProvider();
///     final controller = useFSelectController<String>(
///       vsync: tickerProvider,
///       initialValue: 'option1',
///     );
///     return FSelect(controller: controller, ...);
///   }
/// }
/// ```
FSelectController<T> useFSelectController<T>({
  T? initialValue,
  List<Object?>? keys,
}) {
  return use(
    _FSelectControllerHook<T>(
      initialValue: initialValue,
      keys: keys,
    ),
  );
}

class _FSelectControllerHook<T> extends Hook<FSelectController<T>> {
  const _FSelectControllerHook({
    this.initialValue,
    super.keys,
  });

  final T? initialValue;

  @override
  _FSelectControllerHookState<T> createState() =>
      _FSelectControllerHookState<T>();
}

class _FSelectControllerHookState<T>
    extends HookState<FSelectController<T>, _FSelectControllerHook<T>> {
  late final FSelectController<T> _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = FSelectController<T>(
      value: hook.initialValue,
    );
  }

  @override
  FSelectController<T> build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String get debugLabel => 'useFSelectController<$T>';
}
