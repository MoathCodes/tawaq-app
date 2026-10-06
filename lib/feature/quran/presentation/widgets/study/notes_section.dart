import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
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
  const new({required this.ayahId, required this.narrowPanel, super.key});

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
        .whenData((notes) => ayahId == null ? null : notes[ayahId]);
    final draft = ref.watch(quranNotesStoreProvider).value?.drafts[ayahId];
    final initialText = draft?.text ?? note.value?.text ?? '';
    final controller = useTextEditingController(text: initialText);
    final hasSynced = useRef(note.hasValue);
    final store = ref.read(quranNotesStoreProvider.notifier);
    useEffect(() {
      return () {
        if (ayahId != null) {
          unawaited(store.flushAyah(ayahId!).catchError((Object _) {}));
        }
      };
    }, [ayahId]);
    useEffect(() {
      if (note.hasValue && !hasSynced.value) {
        controller.text = draft?.text ?? note.value?.text ?? '';
        hasSynced.value = true;
      }
      return null;
    }, [note]);

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
              if (ayahId != null) store.edit(ayahId!, value.text);
            },
          ),
          enabled: enabled && !note.isLoading,
          description: enabled ? null : Text(l10n.selectVerseToAddReflection),
          minLines: noteMinLines,
          maxLines: noteMaxLines,
          hint: l10n.reflectionPlaceholder,
          onEditingComplete: () {
            final id = ayahId;
            if (id != null) {
              unawaited(store.flushAyah(id).catchError((Object _) {}));
            }
          },
          style: const .delta(
            contentPadding: .value(EdgeInsets.all(AppSpacing.md)),
          ),
        ),
        if (draft != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              switch (draft.status) {
                QuranNoteSaveStatus.pending ||
                QuranNoteSaveStatus.saving => l10n.notesSavePending,
                QuranNoteSaveStatus.saved => l10n.notesSaveSucceeded,
                QuranNoteSaveStatus.failed => l10n.notesSaveFailed,
              },
              style: typography.body.sm.copyWith(
                color: draft.status == QuranNoteSaveStatus.failed
                    ? colors.destructive
                    : colors.mutedForeground,
              ),
            ),
          ),
          if (draft.status == QuranNoteSaveStatus.failed)
            FButton(
              variant: .secondary,
              onPress: () => store.flushAyah(ayahId!).catchError((Object _) {}),
              child: Text(l10n.retryAction),
            ),
        ],
      ],
    );
  }
}
