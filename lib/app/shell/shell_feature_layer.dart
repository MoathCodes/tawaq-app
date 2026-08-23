import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/app/routing/route_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_drawer.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport.dart';

/// Injected title-bar center content (Quran recitation transport).
class ShellTitleBarCenter extends ConsumerWidget {
  /// Creates the shell title-bar center slot.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const RecitationTransport();
  }
}

/// Wraps shell route content with feature toast listeners.
class ShellContentWrapper extends ConsumerWidget {
  /// Creates a shell content wrapper.
  const new({required this.child, super.key});

  /// Route content to wrap.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RecitationErrorToastListener(child: child);
  }
}

/// Full-screen overlay stacked above shell content (recitation drawer).
class ShellContentOverlay extends ConsumerWidget {
  /// Creates the shell content overlay.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RecitationDrawerOverlay(
      onGoToQuran: () => const QuranRoute().go(context),
    );
  }
}
