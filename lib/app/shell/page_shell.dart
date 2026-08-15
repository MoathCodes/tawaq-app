import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/app/shell/app_bar.dart';
import 'package:tawaq/app/shell/shell_navigation_bar.dart';
import 'package:tawaq/app/shell/shell_shortcut_scope.dart';
import 'package:tawaq/app/shell/shell_sidebar.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/app/desktop/widgets/title_bar_drag_area.dart';
import 'package:tawaq/app/desktop/widgets/window_controls.dart';
import 'package:tawaq/feature/settings/presentation/provider/desktop_settings_provider.dart';

/// The main shell of the application.
///
/// Layout-only chrome: sidebar, title bar, bottom nav, and content area.
/// Feature-specific widgets (recitation transport, toasts, overlays) are injected
/// via [titleBarCenter], [contentWrapper], and [contentOverlay].
class PageShell extends ConsumerWidget {
  /// Creates a new instance of [PageShell].
  const PageShell({
    required this.child,
    this.titleBarCenter = const SizedBox.shrink(),
    this.contentWrapper,
    this.contentOverlay = const SizedBox.shrink(),
    super.key,
  });

  /// The child to display in the shell.
  final Widget child;

  /// Optional widget centered in the title bar (e.g. recitation transport).
  final Widget titleBarCenter;

  /// Optional wrapper around route content (e.g. toast listeners).
  final Widget Function(Widget child)? contentWrapper;

  /// Optional overlay stacked above the content area (e.g. recitation drawer).
  final Widget contentOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = isLessThan(context, FBreakpoint.sm);
    final colors = context.theme.colors;
    final borderWidth = context.theme.style.borderWidth;

    // Window controls sit on a fixed physical side, independent of locale
    // direction: macOS on the left, Windows/Linux on the right. The title bar
    // is forced LTR below, so changing language never mirrors their position
    // or button order.
    final forceMacStyle = ref.watch(
      desktopSettingsProvider.select(
        (s) => s.value?.forceMacStyleWindowControls ?? false,
      ),
    );
    final controlsOnLeft = Platform.isMacOS || forceMacStyle;
    const dragArea = TitleBarDragArea();
    final controls = WindowControls(forceMacStyle: forceMacStyle);
    // The shell actions (location, date, language, theme) live on the title
    // bar row with the window controls to reclaim vertical space.
    const actions = ShellAppBar(dragArea: dragArea);
    // Reserve space on each side so the centered transport never overlaps the
    // window controls or shell action clusters.
    const titleBarSideReserve = 200.0;

    final wrappedChild = contentWrapper?.call(child) ?? child;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        NonSelectable(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border(
                bottom: BorderSide(color: colors.border, width: borderWidth),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gap = constraints.maxWidth - titleBarSideReserve * 2;
                final maxTransportWidth = gap > 0 ? gap : 0.0;
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        children: controlsOnLeft
                            ? [
                                controls,
                                const SizedBox(width: 8),
                                const Expanded(child: actions),
                              ]
                            : [
                                const Expanded(child: actions),
                                const SizedBox(width: 8),
                                controls,
                              ],
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxTransportWidth,
                        ),
                        child: titleBarCenter,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              FScaffold(
                scaffoldStyle: FScaffoldStyleDelta.delta(
                  sidebarBackgroundColor: colors.card,
                  childPadding: const .value(.zero),
                ),
                sidebar: isAtLeast(context, FBreakpoint.sm)
                    ? const NonSelectable(child: ShellSidebar())
                    : null,
                footer: isMobile
                    ? const NonSelectable(child: ShellBottomNavigationBar())
                    : null,
                child: RepaintBoundary(
                  child: ShellShortcutScope(child: wrappedChild),
                ),
              ),
              Positioned.fill(child: contentOverlay),
            ],
          ),
        ),
      ],
    );
  }
}
