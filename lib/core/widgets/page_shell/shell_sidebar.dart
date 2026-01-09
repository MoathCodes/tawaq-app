import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/routing/route.dart';
import 'package:hasanat/core/routing/route_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/gen/fonts.gen.dart';
import 'package:hasanat/theme/spacing.dart';
import 'package:hasanat/theme/theme_extensions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _kCollapsedWidth = 100.0;
const _kExpandedWidth = 250.0;
const _kSlideOffset = Offset(-0.2, 0);

/// The sidebar for the main shell.
class ShellSidebar extends HookConsumerWidget {
  /// Creates a new instance of [ShellSidebar].
  const ShellSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainRoutes = ref.read(mainRoutesProvider(context.l10n));
    final secondaryRoutes = ref.read(secondaryRoutesProvider(context.l10n));
    final theme = FTheme.of(context);
    final router = GoRouter.of(context);
    final isRtl = ref.watch(localeProvider).value?.languageCode == 'ar';
    final duration = context.theme.durations.fast;
    final textDirection = isRtl ? TextDirection.rtl : TextDirection.ltr;

    final isTablet =
        MediaQuery.sizeOf(context).width <= Breakpoints.bootstrap.lg;

    useListenable(router.routeInformationProvider);

    final controller = useAnimationController(
      duration: duration,
      initialValue: 1,
    );

    final animation = CurveTween(curve: Curves.easeInOut).animate(controller);

    useEffect(() {
      if (isTablet) {
        controller.reverse();
      } else {
        controller.forward();
      }
      return null;
    }, [isTablet]);

    final itemStyle = useMemoized(
      () =>
          (FSidebarItemStyle p0) => p0.copyWith(
            backgroundColor: FWidgetStateMap({
              WidgetState.disabled: Colors.transparent,
              WidgetState.selected | WidgetState.hovered | WidgetState.pressed:
                  theme.colors.hover(theme.colors.secondary),
              WidgetState.any: Colors.transparent,
            }),
          ),
      [theme],
    );

    Widget slideTransition(Widget child, Animation<double> anim) =>
        SlideTransition(
          textDirection: textDirection,
          position: Tween(begin: _kSlideOffset, end: Offset.zero).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final isExpanded = animation.isForwardOrCompleted;
        final currentPath = router.state.fullPath;
        final width =
            _kCollapsedWidth +
            (animation.value * (_kExpandedWidth - _kCollapsedWidth));

        return FSidebar(
          style: (p0) => p0.copyWith(
            headerPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            constraints: BoxConstraints.tightFor(width: width),
          ),
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FLabel(
                axis: Axis.vertical,
                child: Text(
                  'توّاق',
                  style: TextStyle(
                    fontFamily: FontFamily.iBMPlexSansArabic,
                    fontWeight: FontWeight.bold,
                    fontSize: 24.sp + (animation.value * 12.sp),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const FDivider(),
            ],
          ),
          footer: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AnimatedSwitcher(
              duration: duration,
              transitionBuilder: slideTransition,
              child: isExpanded
                  ? FButton(
                      key: const ValueKey('expanded'),
                      style: (style) => style.copyWith(
                        iconContentStyle:
                            theme.buttonStyles.outline.iconContentStyle.call,
                        decoration: theme.buttonStyles.outline.decoration,
                        contentStyle: theme.buttonStyles.outline.contentStyle
                            .copyWith(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                            )
                            .call,
                      ),
                      onPress: controller.toggle,
                      prefix: const Icon(FIcons.panelRightOpen),
                      child: Text(context.l10n.collapse),
                    )
                  : FButton.icon(
                      key: const ValueKey('collapsed'),
                      style: FButtonStyle.outline(),
                      onPress: controller.toggle,
                      child: const Icon(FIcons.panelRightOpen),
                    ),
            ),
          ),
          children: [
            for (final (key, routes) in [
              ('main', mainRoutes),
              ('secondary', secondaryRoutes),
            ])
              _RouteGroup(
                routes: routes,
                groupKey: key,
                duration: duration,
                isExpanded: isExpanded,
                currentPath: currentPath,
                slideTransition: slideTransition,
                itemStyle: itemStyle,
                onNavigate: context.go,
              ),
          ],
        );
      },
    );
  }
}

class _RouteGroup extends StatelessWidget {
  const _RouteGroup({
    required this.routes,
    required this.groupKey,
    required this.isExpanded,
    required this.currentPath,
    required this.duration,
    required this.slideTransition,
    required this.itemStyle,
    required this.onNavigate,
  });

  final List<AppRoute> routes;
  final String groupKey;
  final bool isExpanded;
  final String? currentPath;
  final Duration duration;
  final Widget Function(Widget, Animation<double>) slideTransition;
  final FSidebarItemStyle Function(FSidebarItemStyle) itemStyle;
  final void Function(String) onNavigate;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: slideTransition,
      child: FSidebarGroup(
        key: ValueKey('$groupKey-${isExpanded ? 'expanded' : 'collapsed'}'),
        children: [
          for (final route in routes)
            if (isExpanded)
              FSidebarItem(
                key: ValueKey(route.path),
                style: itemStyle,
                onPress: () => onNavigate(route.path),
                icon: Icon(route.icon),
                selected: currentPath == route.path,
                label: Text(route.label),
              )
            else
              FButton.icon(
                key: ValueKey(route.path),
                onPress: () => onNavigate(route.path),
                style: currentPath == route.path
                    ? FButtonStyle.secondary()
                    : FButtonStyle.ghost(),
                child: Center(child: Icon(route.icon)),
              ),
        ],
      ),
    );
  }
}
