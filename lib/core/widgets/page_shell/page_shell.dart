import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/page_shell/app_bar.dart';
import 'package:tawaq/core/widgets/page_shell/shell_navigation_bar.dart';
import 'package:tawaq/core/widgets/page_shell/shell_shortcut_scope.dart';
import 'package:tawaq/core/widgets/page_shell/shell_sidebar.dart';
import 'package:tawaq/core/widgets/page_shell/title_bar_drag_area.dart';
import 'package:tawaq/core/widgets/window_controls.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/adhan/adhan_alert_toast_listener.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_drawer.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport.dart';

/// The main shell of the application.
///
/// This widget is responsible for displaying the
///  main layout of the application,
/// including the app bar, sidebar, and bottom navigation bar.
class PageShell extends ConsumerWidget {
  /// Creates a new instance of [PageShell].
  const PageShell({required this.child, super.key});

  /// The child to display in the shell.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = isLessThan(context, FBreakpoint.sm);
    final colors = context.theme.colors;
    final borderWidth = context.theme.style.borderWidth;

    // Window controls sit on a fixed physical side, independent of locale
    // direction: macOS on the left, Windows/Linux on the right. The title bar
    // is forced LTR below, so changing language never mirrors their position
    // or button order.
    final controlsOnLeft = Platform.isMacOS;
    const dragArea = TitleBarDragArea();
    const controls = WindowControls();
    // The shell actions (location, date, language, theme) live on the title
    // bar row with the window controls to reclaim vertical space.
    const actions = ShellAppBar(dragArea: dragArea);
    // Reserve space on each side so the centered transport never overlaps the
    // window controls or shell action clusters.
    const titleBarSideReserve = 200.0;

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
                        child: const RecitationTransport(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          // The recitation drawer overlays the content (below the title bar)
          // so the full player drops down from the transport on any screen.
          child: Stack(
            children: [
              FScaffold(
                // The sidebar adopts the same chrome surface as the title bar;
                // the content keeps `background`. Forui's sidebar already draws
                // a trailing hairline, completing the two sleek dividers.
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
                // RepaintBoundary prevents child from rebuilding when the
                // sidebar changes.
                child: RepaintBoundary(
                  child: RecitationErrorToastListener(
                    child: AdhanAlertToastListener(
                      child: ShellShortcutScope(child: child),
                    ),
                  ),
                ),
              ),
              const Positioned.fill(child: RecitationDrawerOverlay()),
            ],
          ),
        ),
      ],
    );
  }
}
