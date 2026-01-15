import 'package:flutter/cupertino.dart' show MouseRegion;
import 'package:flutter/material.dart' show MouseRegion;
import 'package:flutter/widgets.dart' show MouseRegion;
import 'package:flutter_hooks/flutter_hooks.dart';

/// A record type representing hover state and its setter.
typedef HoverState = ({
  bool isHovered,
  void Function({required bool value}) setHovered,
});

/// Creates a hover state that can be used with [MouseRegion] or similar
/// widgets to track hover status.
///
/// Returns a record containing:
/// - `isHovered`: The current hover state
/// - `setHovered`: A function to update the hover state
///
/// Example:
/// ```dart
/// class MyWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final (:isHovered, :setHovered) = useHoverState();
///
///     return MouseRegion(
///       onEnter: (_) => setHovered(value: true),
///       onExit: (_) => setHovered(value: false),
///       child: Container(
///         color: isHovered ? Colors.blue : Colors.grey,
///       ),
///     );
///   }
/// }
/// ```
HoverState useHoverState({bool initialValue = false}) {
  final state = useState(initialValue);
  return (
    isHovered: state.value,
    setHovered: ({required bool value}) => state.value = value,
  );
}
