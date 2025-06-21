import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/routing/route_provider.dart';
import 'package:hasanat/core/widgets/page_shell/app_bar.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ShellNavigationBar extends ConsumerWidget {
  final Widget child;
  const ShellNavigationBar({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(routesProvider(context.l10n));

    return Scaffold(
      headers: [const ShellAppBar()],
      footers: [
        const Divider(),
        NavigationBar(
          alignment: NavigationBarAlignment.spaceBetween,
          labelType: NavigationLabelType.selected,
          expanded: true,
          expands: true,
          index: routes.indexWhereOrNull(
                (value) => GoRouter.of(context).state.fullPath == value.path,
              ) ??
              -1,
          onSelected: (value) {
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
        ),
      ],
      child: child,
    );
  }

  NavigationItem buildButton(String label, IconData icon, String path) {
    return NavigationItem(
      key: ValueKey("$label-$path-button"),
      style: const ButtonStyle.muted(density: ButtonDensity.icon),
      selectedStyle: const ButtonStyle.fixed(density: ButtonDensity.icon),
      label: Text(label),
      child: Icon(icon),
    );
  }
}
