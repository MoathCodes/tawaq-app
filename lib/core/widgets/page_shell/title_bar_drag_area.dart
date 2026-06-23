import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/desktop/window_state_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/page_shell/page_shell.dart' show PageShell;
import 'package:window_manager/window_manager.dart';

/// Title-bar drag region that toggles maximize without rebuilding [PageShell].
class TitleBarDragArea extends ConsumerWidget {
  /// Creates [TitleBarDragArea].
  const TitleBarDragArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maximized = ref.watch(windowMaximizedProvider).value ?? false;
    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) {
          unawaited(windowManager.startDragging());
        },
        onDoubleTap: () {
          if (!isDesktopPlatform) return;
          unawaited(
            maximized ? windowManager.unmaximize() : windowManager.maximize(),
          );
        },
      ),
    );
  }
}
