import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:free_map/free_map.dart';

/// Creates and manages a [MapController] from the free_map package that is
/// automatically disposed when the widget is removed from the tree.
///
/// Example:
/// ```dart
/// class MyWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final mapController = useMapController();
///     return FlutterMap(
///       mapController: mapController,
///       ...
///     );
///   }
/// }
/// ```
MapController useMapController({List<Object?>? keys}) {
  return use(_MapControllerHook(keys: keys));
}

class _MapControllerHook extends Hook<MapController> {
  const new({super.keys});

  @override
  _MapControllerHookState createState() => _MapControllerHookState();
}

class _MapControllerHookState
    extends HookState<MapController, _MapControllerHook> {
  late final MapController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = MapController();
  }

  @override
  MapController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String get debugLabel => 'useMapController';
}
