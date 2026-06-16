import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:window_manager/window_manager.dart';

part 'window_state_provider.g.dart';

/// Whether the main window is currently maximized.
///
/// Backed by [WindowListener] events so the value stays in sync after the user
/// (or the OS) maximizes / restores the window — unlike a one-shot
/// `windowManager.isMaximized()` future, which never updates.
@Riverpod(keepAlive: true)
Stream<bool> windowMaximized(Ref ref) async* {
  if (!isDesktopPlatform) {
    yield false;
    return;
  }

  final controller = StreamController<bool>();
  final listener = _WindowMaximizedListener(controller);
  windowManager.addListener(listener);
  ref.onDispose(() {
    windowManager.removeListener(listener);
    unawaited(controller.close());
  });

  yield await windowManager.isMaximized();
  yield* controller.stream;
}

class _WindowMaximizedListener with WindowListener {
  _WindowMaximizedListener(this._controller);

  final StreamController<bool> _controller;

  void _emit({required bool maximized}) {
    if (!_controller.isClosed) _controller.add(maximized);
  }

  @override
  void onWindowMaximize() => _emit(maximized: true);

  @override
  void onWindowUnmaximize() => _emit(maximized: false);
}
