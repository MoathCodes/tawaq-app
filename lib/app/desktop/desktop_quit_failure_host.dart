import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/app/desktop/desktop_shutdown.dart';
import 'package:tawaq/app/desktop/desktop_window_controller.dart';
import 'package:tawaq/core/locale/locale_extension.dart';

/// Keeps a failed quit visible without discarding an unsaved reflection.
class DesktopQuitFailureHost extends ConsumerWidget {
  const DesktopQuitFailureHost({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      if (ref.watch(desktopQuitFailureProvider))
        Semantics(
          liveRegion: true,
          child: FAlert(
            title: Text(context.l10n.quitSaveFailed),
            subtitle: FButton(
              variant: .outline,
              onPress: () =>
                  unawaited(ref.read(desktopWindowControllerProvider).quit()),
              child: Text(context.l10n.quitRetry),
            ),
          ),
        ),
      Expanded(child: child),
    ],
  );
}
