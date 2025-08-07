import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/routing/route_provider.dart';
import 'package:hasanat/core/widgets/window_controls.dart';
import 'package:hasanat/gen/fonts.gen.dart';

class ShellSidebar extends ConsumerStatefulWidget {
  const ShellSidebar({super.key});

  @override
  ConsumerState<ShellSidebar> createState() => _ShellSidebarState();
}

class _ShellSidebarState extends ConsumerState<ShellSidebar> {
  @override
  Widget build(BuildContext context) {
    final mainRoutes = ref.read(mainRoutesProvider(context.l10n));
    final secondaryRoutes = ref.read(secondaryRoutesProvider(context.l10n));
    final theme = FTheme.of(context);
    FSidebarItemStyle style(FSidebarItemStyle p0) => p0.copyWith(
          backgroundColor: FWidgetStateMap({
            WidgetState.disabled: Colors.transparent,
            WidgetState.selected | WidgetState.hovered | WidgetState.pressed:
                theme.colors.hover(theme.colors.secondary),
            WidgetState.any: Colors.transparent,
          }),
        );
    return FSidebar(
      style: (p0) => p0.copyWith(
        headerPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WindowControls(),
          FLabel(
              axis: Axis.vertical,
              child: Text(
                'توّاق',
                style: TextStyle(
                    fontFamily: FontFamily.zain,
                    fontWeight: FontWeight.bold,
                    fontSize: 36.sp),
                textAlign: TextAlign.center,
              )),
          const FDivider(),
        ],
      ),
      children: [
        FSidebarGroup(
          children: [
            ...mainRoutes.map(
              (e) => FSidebarItem(
                style: style,
                onPress: () {
                  setState(() {});
                  context.go(e.path);
                },
                icon: Icon(e.icon),
                selected: GoRouter.of(context).state.fullPath == e.path,
                label: Text(e.label),
                key: ValueKey(e.path),
              ),
            ),
          ],
        ),
        FSidebarGroup(
            children: secondaryRoutes
                .map(
                  (e) => FSidebarItem(
                    style: style,
                    onPress: () {
                      setState(() {});
                      context.go(e.path);
                    },
                    icon: Icon(e.icon),
                    selected: GoRouter.of(context).state.fullPath == e.path,
                    label: Text(e.label),
                    key: ValueKey(e.path),
                  ),
                )
                .toList())
      ],
    );
  }
}
