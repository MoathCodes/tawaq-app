import 'package:hasanat/core/widgets/page_shell/shell_navigation_bar.dart';
import 'package:hasanat/core/widgets/page_shell/shell_sidebar.dart';
import 'package:hasanat/core/widgets/responsive_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class PageShell extends StatelessWidget {
  final Widget child;
  const PageShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Center(
        child: ResponsiveContainer(
          desktopChild: ShellSidebar(child: child),
          mobileChild: ShellNavigationBar(
            child: child,
          ),
        ),
      ),
    );
  }
}
