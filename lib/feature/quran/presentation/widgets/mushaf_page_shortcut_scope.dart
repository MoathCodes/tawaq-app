import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_scope.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';

/// Page prev/next keyboard shortcuts shared by single- and double-page layouts.
class MushafPageShortcutScope extends ConsumerWidget {
  /// Creates a [MushafPageShortcutScope].
  const MushafPageShortcutScope({
    required this.child,
    super.key,
  });

  /// Content receiving page navigation shortcuts.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quranMushafControllerProvider);

    return AppShortcutScope(
      autofocus: true,
      shortcuts: const {
        AppShortcutId.quranPageNext,
        AppShortcutId.quranPagePrev,
        AppShortcutId.quranPageNextSpace,
      },
      handlers: {
        AppShortcutId.quranPageNext: () => unawaited(
          controller.animateToPage(controller.currentPage + 1),
        ),
        AppShortcutId.quranPagePrev: () => unawaited(
          controller.animateToPage(controller.currentPage - 1),
        ),
        AppShortcutId.quranPageNextSpace: () => unawaited(
          controller.animateToPage(controller.currentPage + 1),
        ),
      },
      child: child,
    );
  }
}
