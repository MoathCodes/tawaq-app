import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/logging/talker_provider.dart';

enum DefaultBreakpoint { mobile, tablet, desktop }

class ResponsiveContainer extends ConsumerWidget {
  final Widget? desktopChild;
  final Widget? mobileChild;
  final Widget? tabletChild;
  final DefaultBreakpoint defaultBreakpoint;
  const ResponsiveContainer(
      {super.key,
      this.desktopChild,
      this.mobileChild,
      this.tabletChild,
      this.defaultBreakpoint = DefaultBreakpoint.desktop});

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
      ref.read(talkerNotifierProvider).handle(e, stackTrace);
      throw Exception('Default breakpoint child cannot be null');
    }
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 767;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1024;
}
