import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/routing/route_provider.dart';
import 'package:hasanat/core/widgets/page_shell/app_bar.dart';
import 'package:hasanat/core/widgets/responsive_widget.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ShellSidebar extends ConsumerStatefulWidget {
  final Widget child;
  final bool? collapse;
  const ShellSidebar({required this.child, this.collapse, super.key});

  @override
  ConsumerState<ShellSidebar> createState() => _ShellSidebarState();
}

class _ShellSidebarState extends ConsumerState<ShellSidebar> {
  final ResizablePaneController controller =
      AbsoluteResizablePaneController(200);

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeNotifierProvider.notifier).isArabic();
    final routes = ref.watch(routesProvider(context.l10n));
    final alignment = isArabic ? Alignment.centerRight : Alignment.centerLeft;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ResponsiveContainer.isTablet(context) && !controller.collapsed) {
        controller.tryCollapse();
      }
    });

    return ResizablePanel.horizontal(
      children: [
        if (isArabic)
          ResizablePane.flex(
            key: const ValueKey('ltr-main-content'),
            child: Container(
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ShellAppBar(),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ResizablePane.controlled(
          minSize: 170,
          maxSize: 240,
          collapsedSize: 80,
          controller: controller,
          child: OutlinedContainer(
            borderRadius: const BorderRadius.all(Radius.zero),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return NavigationSidebar(
                  spacing: 8,
                  // roundedCorners: true,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  labelType: controller.collapsed
                      ? NavigationLabelType.tooltip
                      : NavigationLabelType.expanded,
                  labelPosition: NavigationLabelPosition.end,
                  // alignment: NavigationRailAlignment.start,
                  expanded: !controller.collapsed,
                  index: routes.indexWhereOrNull(
                        (value) =>
                            GoRouter.of(context).state.fullPath == value.path,
                      ) ??
                      -1,
                  onSelected: (value) {
                    context.go(routes[value].path);
                  },
                  children: [
                    NavigationDivider(
                      thickness: 0.2,
                      color: Theme.of(context).colorScheme.secondaryForeground,
                    ),
                    ...routes.map(
                      (e) => NavigationItem(
                          // index: routes.indexOf(e),
                          // selected:
                          //     GoRouter.of(context).state.fullPath == e.path,
                          label: Text(e.label),
                          key: ValueKey(e.path),
                          style: controller.collapsed
                              ? const ButtonStyle.fixed()
                              : const ButtonStyle.menubar(),
                          alignment: alignment,
                          selectedStyle: const ButtonStyle.primary(),
                          child: Icon(e.icon)),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (!isArabic)
          ResizablePane.flex(
            key: const ValueKey('rlt-main-content'),
            child: Container(
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ShellAppBar(),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    if (widget.collapse == true) controller.collapse();
    super.initState();
  }
}
