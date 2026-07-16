import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/widgets/merged_action_semantics.dart';
import 'package:tawaq/core/widgets/page_shell/sidebar_settings_provider.dart';
import 'package:tawaq/core/widgets/shell_a11y.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/spacing.dart';
import 'package:tawaq/theme/theme_extensions.dart';

const _kCollapsed = 105.0;
const _kExpanded = 250.0;
const _kSlideOffset = Offset(-0.2, 0);

Duration _sidebarAnimDuration(BuildContext context) =>
    context.theme.durations.fast;

Widget _sidebarSlideTransition(
  BuildContext context,
  Widget child,
  Animation<double> animation,
) => SlideTransition(
  textDirection: Directionality.of(context),
  position: Tween(begin: _kSlideOffset, end: Offset.zero).animate(animation),
  child: FadeTransition(opacity: animation, child: child),
);

FSidebarItemStyleDelta _sidebarItemStyle(BuildContext context) {
  final theme = FTheme.of(context);
  return FSidebarItemStyleDelta.delta(
    backgroundColor: FVariants(
      Colors.transparent,
      variants: {
        [.selected, .hovered, .pressed]: theme.colors.hover(
          theme.colors.secondary,
        ),
        [.disabled]: Colors.transparent,
      },
    ),
  );
}

/// The sidebar for the main shell.
class ShellSidebar extends HookConsumerWidget {
  /// Creates a new instance of [ShellSidebar].
  const ShellSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const mainRoutes = kMainRoutes;
    const secondaryRoutes = kSecondaryRoutes;
    final theme = FTheme.of(context);
    final router = GoRouter.of(context);
    final duration = _sidebarAnimDuration(context);
    final isTablet = isLessThan(context, FBreakpoint.lg);
    final isCollapsed = ref.watch(
      sidebarSettingsProvider.select((s) => s.value ?? isTablet),
    );
    final wasTablet = useRef<bool?>(null);

    useListenable(router.routeInformationProvider);

    final controller = useAnimationController(
      duration: duration,
      initialValue: isCollapsed ? 0.0 : 1.0,
    );
    final animation = useMemoized(
      () => CurveTween(curve: Curves.easeInOut).animate(controller),
      [controller],
    );

    useEffect(() {
      isCollapsed
          ? unawaited(controller.reverse())
          : unawaited(controller.forward());
      return null;
    }, [isCollapsed]);

    useEffect(() {
      final previous = wasTablet.value;
      wasTablet.value = isTablet;
      if (previous != null && !previous && isTablet) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ref
              .read(sidebarSettingsProvider.notifier)
              .setCollapsed(collapsed: true);
        });
      }
      return null;
    }, [isTablet]);

    void toggle() => WidgetsBinding.instance.addPostFrameCallback(
      (_) async => ref
          .read(sidebarSettingsProvider.notifier)
          .setCollapsed(collapsed: !isCollapsed),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        // Defer expanded chrome until the width animation finishes so labels
        // and the footer button are not laid out in a still-narrow sidebar.
        final isVisuallyExpanded =
            animation.status == AnimationStatus.completed;
        final width =
            _kCollapsed + (animation.value * (_kExpanded - _kCollapsed));

        return FSidebar(
          style: FSidebarStyleDelta.delta(
            // Adopt the "chrome" surface so the sidebar reads as one piece with
            // the title bar. Forui's default paints `colors.background`, which
            // would erase the scaffold's sidebar colour — so we set it here and
            // keep the trailing hairline toward the content.
            decoration: .value(
              BoxDecoration(
                color: theme.colors.card,
                border: BorderDirectional(
                  end: BorderSide(
                    color: theme.colors.border,
                    width: theme.style.borderWidth,
                  ),
                ),
              ),
            ),
            headerPadding: const .value(
              EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            constraints: BoxConstraints.tightFor(width: width),
          ),
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FLabel(
                layout: .vertical,
                child: Text(
                  'توّاق',
                  style: theme.typography.body.lg.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        theme.typography.body.lg.fontSize! +
                        (animation.value *
                            (theme.typography.body.xl2.fontSize! -
                                theme.typography.body.lg.fontSize!)),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const FDivider(),
            ],
          ),
          footer: Column(
            children: [
              for (final (key, route) in [
                ('secondary', secondaryRoutes),
              ])
                _RouteGroup(
                  routes: route,
                  groupKey: key,
                  expanded: isVisuallyExpanded,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, anim) =>
                      _sidebarSlideTransition(context, child, anim),
                  child: isVisuallyExpanded
                      ? FButton(
                          key: ValueKey(isVisuallyExpanded),
                          variant: .ghost,
                          style: .delta(
                            decoration: .delta([
                              .all(.boxDelta(color: theme.colors.background)),
                            ]),
                            contentStyle: const .delta(
                              padding: .value(
                                EdgeInsets.all(AppSpacing.sm),
                              ),
                            ),
                          ),
                          mainAxisAlignment: .spaceBetween,
                          onPress: toggle,
                          suffix: const Icon(FLucideIcons.panelRightOpen),
                          child: Text(context.l10n.collapse, overflow: .clip),
                        )
                      : MergedActionSemantics(
                          key: ValueKey(isVisuallyExpanded),
                          label: ShellA11y.expandSidebarLabel(context.l10n),
                          child: FButton.icon(
                            onPress: toggle,
                            variant: .ghost,
                            style: .delta(
                              decoration: .delta([
                                .all(.boxDelta(color: theme.colors.background)),
                              ]),
                            ),
                            child: const Icon(FLucideIcons.panelRightClose),
                          ),
                        ),
                ),
              ),
            ],
          ),
          children: [
            for (final (key, routes) in [
              ('main', mainRoutes),
            ])
              _RouteGroup(
                routes: routes,
                groupKey: key,
                expanded: isVisuallyExpanded,
              ),
          ],
        );
      },
    );
  }
}

class _RouteGroup extends ConsumerWidget {
  const _RouteGroup({
    required this.routes,
    required this.groupKey,
    required this.expanded,
  });
  final List<AppNavigationRoute> routes;
  final String groupKey;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final itemStyle = _sidebarItemStyle(context);

    return AnimatedSwitcher(
      duration: _sidebarAnimDuration(context),
      transitionBuilder: (child, anim) =>
          _sidebarSlideTransition(context, child, anim),
      child: FSidebarGroup(
        key: ValueKey('$groupKey-${expanded ? 'expanded' : 'collapsed'}'),
        children: [
          for (final r in routes)
            expanded
                ? _expandedSidebarItem(
                    context: context,
                    route: r,
                    itemStyle: itemStyle,
                    l10n: l10n,
                  )
                : _collapsedSidebarItem(
                    context: context,
                    route: r,
                    l10n: l10n,
                  ),
        ],
      ),
    );
  }
}

Widget _expandedSidebarItem({
  required BuildContext context,
  required AppNavigationRoute route,
  required FSidebarItemStyleDelta itemStyle,
  required AppLocalizations l10n,
}) {
  final currentPath = GoRouter.of(context).state.fullPath;
  final selected = route.containsLocation(currentPath);
  final enabled = route.navigationEnabled;
  final item = FSidebarItem(
    key: ValueKey(route.path),
    style: itemStyle,
    onPress: enabled ? () => route.activate(context) : null,
    icon: Icon(route.icon),
    selected: selected,
    label: Text(route.localizedLabel(l10n)),
  );
  if (enabled) {
    return item;
  }
  return Semantics(
    hint: ShellA11y.navDisabledHint(l10n),
    enabled: false,
    child: item,
  );
}

Widget _collapsedSidebarItem({
  required BuildContext context,
  required AppNavigationRoute route,
  required AppLocalizations l10n,
}) {
  final currentPath = GoRouter.of(context).state.fullPath;
  final selected = route.containsLocation(currentPath);
  final enabled = route.navigationEnabled;
  return MergedActionSemantics(
    key: ValueKey(route.path),
    label: ShellA11y.navItemLabel(route.localizedLabel(l10n)),
    hint: enabled ? null : ShellA11y.navDisabledHint(l10n),
    selected: selected,
    enabled: enabled,
    child: FButton.icon(
      onPress: enabled ? () => route.activate(context) : null,
      selected: selected,
      variant: selected ? .secondary : .ghost,
      child: Icon(route.icon),
    ),
  );
}
