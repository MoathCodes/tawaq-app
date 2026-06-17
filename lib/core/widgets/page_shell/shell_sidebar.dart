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
import 'package:tawaq/core/widgets/page_shell/shell_providers.dart';
import 'package:tawaq/core/widgets/shell_a11y.dart';
import 'package:tawaq/feature/settings/presentation/provider/ui_state_settings_providers.dart';
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
) =>
    SlideTransition(
      textDirection: Directionality.of(context),
      position: Tween(begin: _kSlideOffset, end: Offset.zero)
          .animate(animation),
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
    final mainRoutes = ref.watch(mainRoutesProvider);
    final secondaryRoutes = ref.watch(secondaryRoutesProvider);
    final theme = FTheme.of(context);
    final router = GoRouter.of(context);
    final duration = _sidebarAnimDuration(context);
    final isTablet = isLessThan(context, FBreakpoint.lg);
    final isCollapsed = ref.watch(shellSidebarCollapsedProvider(isTablet));

    useListenable(router.routeInformationProvider);

    final controller = useAnimationController(duration: duration);
    final animation = CurveTween(curve: Curves.easeInOut).animate(controller);

    useEffect(() {
      isCollapsed
          ? unawaited(controller.reverse())
          : unawaited(controller.forward());
      return null;
    }, [isCollapsed]);
    useEffect(() {
      if (isTablet && context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
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
        final isExpanded = animation.isForwardOrCompleted;
        final width =
            _kCollapsed + (animation.value * (_kExpanded - _kCollapsed));

        return FSidebar(
          style: FSidebarStyleDelta.delta(
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
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        theme.typography.lg.fontSize! +
                        (animation.value *
                            (theme.typography.xl2.fontSize! -
                                theme.typography.lg.fontSize!)),
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
              transitionBuilder: (child, anim) =>
                  _sidebarSlideTransition(context, child, anim),
              child: isExpanded
                  ? FButton(
                      key: ValueKey(isExpanded),
                      variant: .outline,
                      style: const .delta(
                        contentStyle: .delta(
                          padding: .value(
                            EdgeInsets.all(AppSpacing.sm),
                          ),
                        ),
                      ),
                      onPress: toggle,
                      prefix: const Icon(FLucideIcons.panelRightOpen),
                      child: Text(context.l10n.collapse, overflow: .clip),
                    )
                  : MergedActionSemantics(
                      key: ValueKey(isExpanded),
                      label: ShellA11y.expandSidebarLabel(context.l10n),
                      child: FButton.icon(
                        onPress: toggle,
                        child: const Icon(FLucideIcons.panelRightOpen),
                      ),
                    ),
            ),
          ),
          children: [
            for (final (key, routes) in [
              ('main', mainRoutes),
              ('secondary', secondaryRoutes),
            ])
              _RouteGroup(routes: routes, groupKey: key),
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
  });
  final List<AppNavigationRoute> routes;
  final String groupKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isTablet = isLessThan(context, FBreakpoint.lg);
    final isCollapsed = ref.watch(shellSidebarCollapsedProvider(isTablet));
    final isExpanded = !isCollapsed;
    final itemStyle = _sidebarItemStyle(context);

    return AnimatedSwitcher(
      duration: _sidebarAnimDuration(context),
      transitionBuilder: (child, anim) =>
          _sidebarSlideTransition(context, child, anim),
      child: FSidebarGroup(
        key: ValueKey('$groupKey-${isExpanded ? 'expanded' : 'collapsed'}'),
        children: [
          for (final r in routes)
            isExpanded
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
    children: [
      if (route.subRoutes.isNotEmpty)
        ...route.subRoutes.map(
          (sub) {
            final subEnabled = sub.navigationEnabled;
            final subSelected = sub.containsLocation(currentPath);
            final subItem = FSidebarItem(
              key: ValueKey(sub.path),
              style: itemStyle,
              onPress: subEnabled ? () => sub.activate(context) : null,
              icon: Icon(sub.icon),
              selected: subSelected,
              label: Text(sub.localizedLabel(l10n)),
            );
            if (subEnabled) {
              return subItem;
            }
            return Semantics(
              hint: ShellA11y.navDisabledHint(l10n),
              enabled: false,
              child: subItem,
            );
          },
        ),
    ],
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
