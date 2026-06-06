import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/page_shell/app_bar.dart';
import 'package:tawaq/core/widgets/page_shell/shell_navigation_bar.dart';
import 'package:tawaq/core/widgets/page_shell/shell_shortcut_scope.dart';
import 'package:tawaq/core/widgets/page_shell/shell_sidebar.dart';
import 'package:tawaq/core/widgets/window_controls.dart';
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
    final isMobile = ResponsiveQuery.of(context).isLessThan(.sm);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        NonSelectable(
          child: ColoredBox(
            color: context.theme.colors.background,
            child: Padding(
              padding: const .all(6),
              child: SizedBox(
                height: 28,
                child: Row(
                  children: [
                    const WindowControls(),
                    Expanded(
                      child: ExcludeSemantics(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanStart: (_) {
                            unawaited(windowManager.startDragging());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: FScaffold(
            header: const NonSelectable(child: ShellAppBar()),
            sidebar: ResponsiveQuery.of(context).isAtLeast(.sm)
                ? const NonSelectable(child: ShellSidebar())
                : null,
            footer: isMobile
                ? const NonSelectable(child: ShellBottomNavigationBar())
                : null,
            // RepaintBoundary prevents child from rebuilding
            // when sidebar changes
            child: RepaintBoundary(
              child: FToaster(
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
