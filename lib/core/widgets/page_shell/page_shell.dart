import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/page_shell/app_bar.dart';
import 'package:tawaq/core/widgets/page_shell/shell_navigation_bar.dart';
import 'package:tawaq/core/widgets/page_shell/shell_shortcut_scope.dart';
import 'package:tawaq/core/widgets/page_shell/shell_sidebar.dart';
import 'package:tawaq/core/widgets/window_controls.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/adhan/adhan_alert_toast_listener.dart';
import 'package:window_manager/window_manager.dart';

/// The main shell of the application.
///
/// This widget is responsible for displaying the
///  main layout of the application,
/// including the app bar, sidebar, and bottom navigation bar.
class PageShell extends ConsumerWidget {
  /// Creates a new instance of [PageShell].
  const PageShell({required this.child, super.key});

  /// The child to display in the shell.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = isLessThan(context, FBreakpoint.sm);

    // Place window controls on the platform-conventional side: macOS keeps
    // them at the leading edge (top-left), Windows/Linux at the trailing edge
    // (top-right). Using logical start/end lets RTL locales mirror this
    // automatically.
    final controlsAtStart = Platform.isMacOS;
    final dragArea = Expanded(
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) {
            unawaited(windowManager.startDragging());
          },
        ),
      ),
    );
    const controls = WindowControls();

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        NonSelectable(
          child: Container(
            color: context.theme.colors.background,
            padding: const .all(6),
            height: 40,
            child: Row(
              children: controlsAtStart
                  ? [controls, dragArea]
                  : [dragArea, controls],
            ),
          ),
        ),
        Expanded(
          child: FScaffold(
            header: const NonSelectable(child: ShellAppBar()),
            sidebar: isAtLeast(context, FBreakpoint.sm)
                ? const NonSelectable(child: ShellSidebar())
                : null,
            footer: isMobile
                ? const NonSelectable(child: ShellBottomNavigationBar())
                : null,
            // RepaintBoundary prevents child from rebuilding
            // when sidebar changes
            child: RepaintBoundary(
              child: AdhanAlertToastListener(
                child: ShellShortcutScope(
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
