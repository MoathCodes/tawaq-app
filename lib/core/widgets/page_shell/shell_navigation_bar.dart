import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/routing/route_provider.dart';

class ShellBottomNavigationBar extends ConsumerStatefulWidget {
  const ShellBottomNavigationBar({super.key});

  @override
  ConsumerState<ShellBottomNavigationBar> createState() =>
      _ShellBottomNavigationBarState();
}

class _ShellBottomNavigationBarState
    extends ConsumerState<ShellBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(mainRoutesProvider(context.l10n));

    return FBottomNavigationBar(
      index: routes.indexWhere(
        (value) => GoRouter.of(context).state.fullPath == value.path,
      ),
      onChange: (value) {
        setState(() {});
        context.go(routes[value].path);
      },
      children: [
        ...routes.map(
          (route) => buildButton(
            route.label,
            route.icon,
            route.path,
          ),
        ),
      ],
    );
  }

  FBottomNavigationBarItem buildButton(
      String label, IconData icon, String path) {
    return FBottomNavigationBarItem(
      key: ValueKey("$label-$path-button"),
      label: Text(label),
      icon: Icon(icon),
    );
  }
}
