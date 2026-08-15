import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:window_manager/window_manager.dart';

part 'window_state_provider.g.dart';

/// Canonical native window flags.
class NativeWindowSnapshot {
  const NativeWindowSnapshot({required this.visible, required this.maximized});

  final bool visible;
  final bool maximized;
}

/// Single listener-backed authority for native window flags.
@Riverpod(keepAlive: true)
class NativeWindowState extends _$NativeWindowState {
  @override
  Future<NativeWindowSnapshot> build() async {
    if (!isDesktopPlatform) {
      return const NativeWindowSnapshot(visible: true, maximized: false);
    }
    final listener = _NativeWindowListener(refresh);
    windowManager.addListener(listener);
    ref.onDispose(() => windowManager.removeListener(listener));
    return _query();
  }

  Future<NativeWindowSnapshot> _query() async => NativeWindowSnapshot(
    visible: await windowManager.isVisible(),
    maximized: await windowManager.isMaximized(),
  );

  /// Re-queries native state after a command or OS event.
  Future<void> refresh() async {
    if (!isDesktopPlatform) return;
    final next = await _query();
    if (ref.mounted) state = AsyncData(next);
  }
}

class _NativeWindowListener with WindowListener {
  _NativeWindowListener(this._refresh);

  final Future<void> Function() _refresh;

  @override
  void onWindowEvent(String eventName) => _refresh();

  @override
  void onWindowMaximize() => _refresh();

  @override
  void onWindowUnmaximize() => _refresh();
}
