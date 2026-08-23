import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Notes section for the study panel.
///
/// Remount per ayah via [ValueKey] from the parent so the text controller is
/// not shared across ayah changes (no clear-then-assign races).
class NotesSection extends HookConsumerWidget {
  /// Creates a [NotesSection] instance.
  const new({
    required this.ayahId,
    required this.narrowPanel,
    super.key,
  });

  /// Ayah this editor is bound to, or null when nothing is selected.
  final int? ayahId;

  /// Whether the study panel is narrower than the small breakpoint.
  final bool narrowPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;

    final enabled = ayahId != null;
    final note = ref
        .watch(quranNotesStoreProvider)
        .whenData(
          (notes) => ayahId == null ? null : notes[ayahId],
        );
    final initialText = note.hasValue ? (note.value?.text ?? '') : '';
    final controller = useTextEditingController(text: initialText);
    final hasSynced = useRef(note.hasValue);
    final lastPersistedText = useRef(initialText);
    final debounceTimer = useRef<Timer?>(null);

    useEffect(
      () {
        return () {
          final pending = debounceTimer.value;
          debounceTimer.value = null;
          pending?.cancel();
          // Flush unsaved edits when the editor unmounts (ayah change / leave).
          final id = ayahId;
          final text = controller.text;
          if (id != null &&
              hasSynced.value &&
              text != lastPersistedText.value) {
            lastPersistedText.value = text;
            unawaited(
              ref.read(quranNotesStoreProvider.notifier).save(id, text),
            );
          }
        };
      },
      [ayahId],
    );

    // Sync once when the note finishes loading for this remounted editor.
    useEffect(
      () {
        if (note.hasValue && !hasSynced.value) {
          final text = note.value?.text ?? '';
          controller.text = text;
          lastPersistedText.value = text;
          hasSynced.value = true;
          debounceTimer.value?.cancel();
          debounceTimer.value = null;
        }
        return null;
      },
      [note],
    );

    void saveNote(int id) {
      final text = controller.text;
      lastPersistedText.value = text;
      unawaited(
        ref.read(quranNotesStoreProvider.notifier).save(id, text),
      );
    }

    void scheduleSave() {
      final id = ayahId;
      if (id == null) return;
      debounceTimer.value?.cancel();
      debounceTimer.value = Timer(
        const Duration(milliseconds: 500),
        () => saveNote(id),
      );
    }

    final noteMinLines = narrowPanel ? 3 : 5;
    final noteMaxLines = narrowPanel ? 6 : 10;
    final persistedText = note.value?.text ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuranSemantics.sectionHeader(
          label: l10n.addReflection,
          child: Row(
            children: [
              QuranSemantics.decorative(
                Icon(FLucideIcons.penLine, size: 16, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.addReflection,
                style: typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FTextField(
          control: FTextFieldControl.managed(
            controller: controller,
            onChange: (value) {
              if (persistedText != value.text) {
                scheduleSave();
              }
            },
          ),
          enabled: enabled && !note.isLoading,
          description: enabled ? null : Text(l10n.selectVerseToAddReflection),
          minLines: noteMinLines,
          maxLines: noteMaxLines,
          hint: l10n.reflectionPlaceholder,
          onEditingComplete: () {
            final id = ayahId;
            if (id != null) saveNote(id);
          },
          style: const .delta(
            contentPadding: .value(EdgeInsets.all(AppSpacing.md)),
          ),
        ),
      ],
    );
  }
}
