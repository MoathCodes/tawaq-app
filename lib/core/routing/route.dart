import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'route.freezed.dart';

/// Immutable description of a top-level navigation destination.
@freezed
abstract class AppRoute with _$AppRoute {
  /// Creates a route entry rendered by the navigation shell.
  const factory AppRoute({
    required String path,
    required String label,
    required IconData icon,
    required Widget child,
  }) = _AppRoute;
}
