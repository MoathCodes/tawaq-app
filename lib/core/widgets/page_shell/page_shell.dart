import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/page_shell/app_bar.dart';
import 'package:hasanat/core/widgets/page_shell/shell_navigation_bar.dart';
import 'package:hasanat/core/widgets/page_shell/shell_sidebar.dart';
import 'package:hasanat/core/widgets/window_controls.dart';
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
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) {
            unawaited(windowManager.startDragging());
          },
          child: ColoredBox(
            color: context.theme.colors.background,
            child: const Padding(
              padding: .all(6),
              child: SizedBox(
                height: 28,
                child: Row(children: [WindowControls()]),
              ),
            ),
          ),
        ),
        Expanded(
          child: FScaffold(
            header: const ShellAppBar(),
            sidebar: ResponsiveQuery.of(context).isAtLeast(.sm)
                ? const ShellSidebar()
                : null,
            footer: isMobile ? const ShellBottomNavigationBar() : null,
            // RepaintBoundary prevents child from rebuilding when sidebar changes
            child: RepaintBoundary(
              child: FToaster(child: child),
            ),
          ),
        ),
      ],
    );
  }
}
