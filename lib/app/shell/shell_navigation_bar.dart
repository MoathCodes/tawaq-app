import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/app/routing/route_provider.dart';
import 'package:tawaq/core/locale/locale_extension.dart';

/// The bottom navigation bar for the main shell.
class ShellBottomNavigationBar extends HookConsumerWidget {
  /// Creates a new instance of [ShellBottomNavigationBar].
  const ShellBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const routes = kMainRoutes;
    final router = GoRouter.of(context);
    // go_router 17: rebuild when routeInformationProvider notifies (sidebar).
    useListenable(router.routeInformationProvider);
    final currentLocation = router.state.fullPath;
    final selectedIndex = routes.indexWhere(
      (route) => route.containsLocation(currentLocation),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: FBottomNavigationBar(
        // -1 when outside [kMainRoutes] so no main tab is selected.
        index: selectedIndex,
        onChange: (value) {
          final route = routes[value];
          if (route.navigationEnabled) {
            route.go(context);
          }
        },
        children: [
          ...routes.map(
            (route) => _buildButton(
              route.localizedLabel(context.l10n),
              route.icon,
              route.path,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a bottom navigation bar item.
  FBottomNavigationBarItem _buildButton(
    String label,
    IconData icon,
    String path,
  ) {
    return FBottomNavigationBarItem(
      key: ValueKey('$label-$path-button'),
      label: Text(label),
      icon: Icon(icon),
    );
  }
}
