import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Notes section for the study panel.
class NotesSection extends HookConsumerWidget {
  /// Creates a [NotesSection] instance.
  const NotesSection({required this.narrowPanel, super.key});

  /// Whether the study panel is narrower than the small breakpoint.
  final bool narrowPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahId = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.selectedAyah?.ayahId,
      ),
    );
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;

    final enabled = ayahId != null;
    final note = ref.watch(quranNotesProvider(ayahId));
    final controller = useTextEditingController();
    final hasSynced = useRef(false);

    // Sync controller with provider when note loads or ayahId changes
    useEffect(
      () {
        if (note.hasValue && !hasSynced.value) {
          controller.text = note.value ?? '';
          hasSynced.value = true;
        }
        return null;
      },
      [note.value],
    );

    // Reset sync flag when ayahId changes
    useEffect(
      () {
        hasSynced.value = false;
        return null;
      },
      [ayahId],
    );

    final debounceTimer = useRef<Timer?>(null);

    useEffect(
      () =>
          () => debounceTimer.value?.cancel(),
      const [],
    );

    void saveNote() {
      if (ayahId == null) return;
      unawaited(
        ref.read(quranNotesProvider(ayahId).notifier).addNote(controller.text),
      );
    }

    void scheduleSave() {
      debounceTimer.value?.cancel();
      debounceTimer.value = Timer(const Duration(milliseconds: 500), saveNote);
    }

    final noteMinLines = narrowPanel ? 3 : 5;
    final noteMaxLines = narrowPanel ? 6 : 10;

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
              if (note.value != value.text) {
                scheduleSave();
              }
            },
          ),
          enabled: enabled && !note.isLoading,
          description: enabled ? null : Text(l10n.selectVerseToAddReflection),
          minLines: noteMinLines,
          maxLines: noteMaxLines,
          hint: l10n.reflectionPlaceholder,
          onEditingComplete: saveNote,
          style: const .delta(
            contentPadding: .value(EdgeInsets.all(AppSpacing.md)),
          ),
        ),
      ],
    );
  }
}
