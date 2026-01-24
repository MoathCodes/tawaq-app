import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/quran/presentation/providers/quran_notes_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Notes section for the study panel.
class NotesSection extends HookConsumerWidget {
  /// Creates a [NotesSection] instance.
  const NotesSection({
    required this.colors,
    required this.typography,
    required this.ayahId,
    super.key,
  });

  /// The color scheme.
  final FColors colors;

  /// The typography styles.
  final FTypography typography;

  /// The ayah ID.
  final int? ayahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    void saveNote() {
      if (ayahId == null) return;
      ref.read(quranNotesProvider(ayahId).notifier).addNote(controller.text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(FIcons.penLine, size: 16, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              context.l10n.addReflection,
              style: typography.sm.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FTextField(
          control: FTextFieldControl.managed(
            controller: controller,
            onChange: (value) {
              if (note.value != value.text) {
                saveNote();
              }
            },
          ),
          enabled: enabled && !note.isLoading,
          description: enabled
              ? null
              : const Text('Please select a verse to add a reflection'),
          minLines: 5,
          maxLines: 10,
          hint: context.l10n.reflectionPlaceholder,
          onEditingComplete: saveNote,
          style: (style) => style.copyWith(
            contentPadding: const EdgeInsets.all(AppSpacing.md),
          ),
        ),
      ],
    );
  }
}
