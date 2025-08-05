import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/utils/gradient_background.dart';
import 'package:hasanat/core/widgets/page_shell/app_bar.dart';
import 'package:hasanat/core/widgets/page_shell/shell_navigation_bar.dart';
import 'package:hasanat/core/widgets/page_shell/shell_sidebar.dart';
import 'package:hasanat/core/widgets/responsive_widget.dart';

class PageShell extends StatelessWidget {
  final Widget child;
  const PageShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: FScaffold(
        scaffoldStyle: (p0) => p0.copyWith(
            backgroundColor: Colors.transparent,
            sidebarBackgroundColor: Colors.transparent),
        header: const ShellAppBar(),
        sidebar: ResponsiveContainer.isDesktop(context) ||
                ResponsiveContainer.isTablet(context)
            ? const ShellSidebar()
            : null,
        footer: ResponsiveContainer.isMobile(context)
            ? const ShellBottomNavigationBar()
            : null,
        child: child,
      ),
    );
  }
}
