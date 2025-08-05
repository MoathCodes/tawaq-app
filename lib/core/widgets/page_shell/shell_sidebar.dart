import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/routing/route_provider.dart';
import 'package:hasanat/core/widgets/hover_card.dart';

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
                theme.colors.hover(theme.colors.background),
            WidgetState.any: Colors.transparent,
          }),
        );
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: HoverCard(
        // backgroundColor: Colors.transparent,
        padding: const EdgeInsets.all(0),
        child: FSidebar(
          style: (p0) => p0.copyWith(
              decoration: p0.decoration.copyWith(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.transparent))),
          header: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FLabel(
                    axis: Axis.vertical,
                    child: Text(
                      'توّاق',
                      style: TextStyle(fontFamily: 'Zain', fontSize: 36.sp),
                      textAlign: TextAlign.center,
                    )),
                FDivider(
                    style: context.theme.dividerStyles.horizontalStyle
                        .copyWith(padding: EdgeInsets.zero)
                        .call),
              ],
            ),
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
        ),
      ),
    );
  }
}
