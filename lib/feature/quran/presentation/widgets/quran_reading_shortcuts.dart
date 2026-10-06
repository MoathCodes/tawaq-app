import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';

/// One reading scope for the header, Mushaf, and study pane. Editable fields
/// and separate dialog/popover focus scopes keep their own keyboard behavior.
class QuranReadingShortcuts extends HookConsumerWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final selecting = useRef(false);
    final focus = useFocusNode(debugLabel: 'Quran reading');

    void movePage(int delta) => unawaited(
      controller.animateToPage(
        controller.currentPage + delta * controller.pagesPerViewport,
      ),
    );

    Future<void> moveAyah(int delta) async {
      if (selecting.value) return;
      selecting.value = true;
      try {
        await navigateStudyAyah(
          ref: ref,
          currentAyahId: ref.read(quranSelectedAyahIdProvider),
          delta: delta,
        );
      } on Object {
        if (context.mounted) {
          showFToast(
            context: context,
            variant: .destructive,
            title: Text(context.l10n.studySelectionLoadFailed),
          );
        }
      } finally {
        selecting.value = false;
      }
    }

    useEffect(() {
      final handlers = <ShortcutDef, VoidCallback>{
        AppShortcut.quranPageNext: () => movePage(1),
        AppShortcut.quranPagePrev: () => movePage(-1),
        AppShortcut.quranPageNextSpace: () => movePage(1),
        AppShortcut.quranAyahNext: () => unawaited(moveAyah(1)),
        AppShortcut.quranAyahPrev: () => unawaited(moveAyah(-1)),
      };
      KeyEventResult handle(KeyEvent event) {
        if ((event is! KeyDownEvent && event is! KeyRepeatEvent) ||
            ModalRoute.of(context)?.isCurrent == false ||
            ref.read(recitationDrawerProvider)) {
          return KeyEventResult.ignored;
        }
        final primary = FocusManager.instance.primaryFocus;
        final rootFocused = primary == FocusManager.instance.rootScope;
        // Desktop focus can fall back to the root after traversal or an
        // overlay closes. This current route still owns the reading keys.
        if (!focus.hasFocus && !rootFocused) return KeyEventResult.ignored;
        // Portal controls have their own scope and arrow-key navigation.
        if (!rootFocused && primary?.enclosingScope != focus.enclosingScope) {
          return KeyEventResult.ignored;
        }
        final editable = primary?.context
            ?.findAncestorWidgetOfExactType<EditableText>();
        if (editable != null && !editable.readOnly) {
          return KeyEventResult.ignored;
        }
        for (final entry in handlers.entries) {
          if (entry.key.activators.any(
            (key) => key.accepts(event, HardwareKeyboard.instance),
          )) {
            entry.value();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      }

      // Read-only selectable prose and focused buttons otherwise consume these
      // keys before a parent shortcut sees them. Limit early handling to this
      // mounted route and its reading scope, never to the whole application.
      FocusManager.instance.addEarlyKeyEventHandler(handle);
      return () => FocusManager.instance.removeEarlyKeyEventHandler(handle);
    }, [controller, focus]);

    return Focus(focusNode: focus, autofocus: true, child: child);
  }
}
