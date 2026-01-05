import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/logging/logger_provider.dart';

/// The default breakpoint to use if no child is provided for the current
/// screen size.
enum DefaultBreakpoint {
  /// The mobile breakpoint.
  mobile,

  /// The tablet breakpoint.
  tablet,

  /// The desktop breakpoint.
  desktop,
}

/// A widget that displays a different child depending on the screen size.
class ResponsiveContainer extends ConsumerWidget {
  /// Creates a responsive container.
  const ResponsiveContainer({
    super.key,
    this.desktopChild,
    this.mobileChild,
    this.tabletChild,
    this.defaultBreakpoint = DefaultBreakpoint.desktop,
  });

  /// The widget to display on desktop screens.
  final Widget? desktopChild;

  /// The widget to display on mobile screens.
  final Widget? mobileChild;

  /// The widget to display on tablet screens.
  final Widget? tabletChild;

  /// The default breakpoint to use if no child is provided for the current
  /// screen size.
  final DefaultBreakpoint defaultBreakpoint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (desktopChild != null && isDesktop(context)) return desktopChild!;
    if (tabletChild != null && isTablet(context)) return tabletChild!;
    if (mobileChild != null && isMobile(context)) return mobileChild!;

    try {
      return switch (defaultBreakpoint) {
        DefaultBreakpoint.mobile => mobileChild!,
        DefaultBreakpoint.tablet => tabletChild!,
        DefaultBreakpoint.desktop => desktopChild!,
      };
    } catch (e, stackTrace) {
      ref
          .read(loggerProvider)
          .e(
            'Default breakpoint child cannot be null',
            error: e,
            stackTrace: stackTrace,
          );
      throw Exception('Default breakpoint child cannot be null');
    }
  }

  /// Whether the current screen size is a desktop screen.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  /// Whether the current screen size is a mobile screen.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 767;

  /// Whether the current screen size is a tablet screen.
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1024;
}
