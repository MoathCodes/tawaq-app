import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'route.freezed.dart';

@freezed
abstract class AppRoute with _$AppRoute {
  const factory AppRoute({
    required String path,
    required String label,
    required IconData icon,
    required Widget child,
  }) = _AppRoute;
}
