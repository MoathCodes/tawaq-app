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
    final debounceTimer = useRef<Timer?>(null);

    useEffect(
      () =>
          () => debounceTimer.value?.cancel(),
      const [],
    );

    // On ayah change: cancel pending save, reset field, then allow re-sync.
    useEffect(
      () {
        debounceTimer.value?.cancel();
        debounceTimer.value = null;
        hasSynced.value = false;
        controller.text = '';
        // Text assignment notifies listeners; drop any save it scheduled.
        debounceTimer.value?.cancel();
        debounceTimer.value = null;
        return null;
      },
      [ayahId],
    );

    // Sync controller with provider when note loads (after ayah reset).
    useEffect(
      () {
        if (note.hasValue && !hasSynced.value) {
          controller.text = note.value ?? '';
          hasSynced.value = true;
          debounceTimer.value?.cancel();
          debounceTimer.value = null;
        }
        return null;
      },
      [ayahId, note],
    );

    void saveNote(int id) {
      unawaited(
        ref.read(quranNotesProvider(id).notifier).addNote(controller.text),
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
