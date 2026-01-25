import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/routing/route_provider.dart';

/// The bottom navigation bar for the main shell.
class ShellBottomNavigationBar extends ConsumerWidget {
  /// Creates a new instance of [ShellBottomNavigationBar].
  const ShellBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = [
      ...ref.read(mainRoutesProvider(context.l10n)),
      ...ref.read(secondaryRoutesProvider(context.l10n)),
    ];

    return FBottomNavigationBar(
      index: routes.indexWhere(
        (value) => GoRouter.of(context).state.fullPath == value.path,
      ),
      onChange: (value) => context.go(routes[value].path),
      children: [
        ...routes.map(
          (route) => _buildButton(
            route.label,
            route.icon,
            route.path,
          ),
        ),
      ],
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
