import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/page_shell/app_bar.dart';
import 'package:hasanat/core/widgets/page_shell/shell_navigation_bar.dart';
import 'package:hasanat/core/widgets/page_shell/shell_sidebar.dart';
import 'package:hasanat/core/widgets/responsive_widget.dart';

/// The main shell of the application.
///
/// This widget is responsible for displaying the main layout of the application,
/// including the app bar, sidebar, and bottom navigation bar.
class PageShell extends StatelessWidget {
  /// Creates a new instance of [PageShell].
  const PageShell({required this.child, super.key});

  /// The child to display in the shell.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO: make the sidebar collapsible
    return FScaffold(
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
    );
  }
}