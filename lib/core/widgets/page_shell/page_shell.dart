import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/page_shell/app_bar.dart';
import 'package:hasanat/core/widgets/page_shell/shell_navigation_bar.dart';
import 'package:hasanat/core/widgets/page_shell/shell_sidebar.dart';
import 'package:hasanat/core/widgets/responsive_widget.dart';
import 'package:hasanat/core/widgets/window_controls.dart';
import 'package:window_manager/window_manager.dart';

/// The main shell of the application.
///
/// This widget is responsible for displaying the main layout of the application,
/// including the app bar, sidebar, and bottom navigation bar.
class PageShell extends StatelessWidget {
  /// The child to display in the shell.
  final Widget child;

  /// Creates a new instance of [PageShell].
  const PageShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: make the sidebar collapsible
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) {
            windowManager.startDragging();
          },
          child: ColoredBox(
            color: context.theme.colors.background,
            child: const Padding(
              padding: EdgeInsets.all(6.0),
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
            sidebar:
                ResponsiveContainer.isDesktop(context) ||
                    ResponsiveContainer.isTablet(context)
                ? const ShellSidebar()
                : null,
            footer: ResponsiveContainer.isMobile(context)
                ? const ShellBottomNavigationBar()
                : null,
            child: child,
          ),
        ),
      ],
    );
  }
}
