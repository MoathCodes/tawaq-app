import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/routing/route_provider.dart';

/// The bottom navigation bar for the main shell.
class ShellBottomNavigationBar extends ConsumerWidget {
  /// Creates a new instance of [ShellBottomNavigationBar].
  const ShellBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(mainRoutesProvider);
    final currentLocation = GoRouter.of(context).state.fullPath;
    final selectedIndex = routes.indexWhere(
      (route) => route.containsLocation(currentLocation),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: FBottomNavigationBar(
        index: selectedIndex < 0 ? 0 : selectedIndex,
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
