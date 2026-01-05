import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/routing/route_provider.dart';
import 'package:hasanat/gen/fonts.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The sidebar for the main shell.
class ShellSidebar extends HookConsumerWidget {
  /// Creates a new instance of [ShellSidebar].
  const ShellSidebar({super.key});

  /// Whether to hide the window controls.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainRoutes = ref.read(mainRoutesProvider(context.l10n));
    final secondaryRoutes = ref.read(secondaryRoutesProvider(context.l10n));
    final theme = FTheme.of(context);

    // Listen to route changes to trigger rebuilds when navigation occurs
    useListenable(GoRouter.of(context).routeInformationProvider);
    FSidebarItemStyle style(FSidebarItemStyle p0) => p0.copyWith(
      backgroundColor: FWidgetStateMap({
        WidgetState.disabled: Colors.transparent,
        WidgetState.selected | WidgetState.hovered | WidgetState.pressed: theme
            .colors
            .hover(theme.colors.secondary),
        WidgetState.any: Colors.transparent,
      }),
    );
    return FSidebar(
      style: (p0) => p0.copyWith(
        headerPadding: const .symmetric(horizontal: 10, vertical: 8),
      ),
      header: Column(
        crossAxisAlignment: .stretch,
        children: [
          FLabel(
            axis: .vertical,
            child: Text(
              'توّاق',
              style: TextStyle(
                fontFamily: FontFamily.iBMPlexSansArabic,
                fontWeight: FontWeight.bold,
                fontSize: 36.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const FDivider(),
        ],
      ),
      children: [
        FSidebarGroup(
          children: [
            ...mainRoutes.map(
              (e) {
                return FSidebarItem(
                  style: style,
                  onPress: () => context.go(e.path),
                  icon: Icon(e.icon),
                  selected: GoRouter.of(context).state.fullPath == e.path,
                  label: Text(e.label),
                  key: ValueKey(e.path),
                );
              },
            ),
          ],
        ),
        FSidebarGroup(
          children: secondaryRoutes.map(
            (e) {
              return FSidebarItem(
                style: style,
                onPress: () => context.go(e.path),
                icon: Icon(e.icon),
                selected: GoRouter.of(context).state.fullPath == e.path,
                label: Text(e.label),
                key: ValueKey(e.path),
              );
            },
          ).toList(),
        ),
      ],
    );
  }
}
