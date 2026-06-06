import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_scope.dart';

/// Page prev/next keyboard shortcuts shared by single- and double-page layouts.
class MushafPageShortcutScope extends StatelessWidget {
  /// Creates a [MushafPageShortcutScope].
  const MushafPageShortcutScope({
    required this.controller,
    required this.child,
    super.key,
  });

  /// The mushaf reader controller.
  final MushafReaderController controller;

  /// Content receiving page navigation shortcuts.
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
