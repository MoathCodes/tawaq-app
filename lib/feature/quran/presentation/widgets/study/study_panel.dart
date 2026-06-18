import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_scope.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';
import 'package:tawaq/core/widgets/reading_swipe_viewport.dart';
import 'package:tawaq/feature/quran/domain/use_cases/navigate_study_ayah.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/content_accordion.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/notes_section.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel_header.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// A study companion panel for the Quran screen.
class StudyPanel extends HookConsumerWidget {
  /// Creates a study panel.
  const StudyPanel({super.key});

  Future<void> _navigateAyah(WidgetRef ref, int delta) async {
    final currentAyahId = ref.read(
      quranScreenSettingsProvider.select(
        (v) => v.value?.selectedAyah?.ayahId,
      ),
    );
    await navigateStudyAyah(
      ref: ref,
      currentAyahId: currentAyahId,
      delta: delta,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAyah = ref.watch(
      quranScreenSettingsProvider.select(
        (value) => value.value?.selectedAyah,
      ),
    );
    final ayaId = selectedAyah?.ayahId;

    // Track previous ayahId to determine animation direction
    final prevAyahId = usePrevious(ayaId);
    final slideDirection = useState(0); // -1 = left (next), 1 = right (prev)

    // Update slide direction when ayahId changes
    useEffect(
      () {
        if (prevAyahId != null && ayaId != null && prevAyahId != ayaId) {
          slideDirection.value = ayaId > prevAyahId ? -1 : 1;
        }
        return null;
      },
      [ayaId],
    );

    const studyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContentAccordion(),
        SizedBox(height: AppSpacing.xl),
        NotesSection(),
      ],
    );

    final canGoNext = ayaId == null || ayaId < kMaxQuranAyahId;
    final canGoPrevious = ayaId == null || ayaId > 1;

    final l10n = context.l10n;
    final panelContent = QuranSemantics.landmark(
      label: l10n.studyMode,
      child: StaticCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StudyPanelHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ReadingSwipeViewport(
                    viewportMinHeight: constraints.maxHeight,
                    horizontalPadding: AppSpacing.lg,
                    topPadding: AppSpacing.lg,
                    bottomPadding: AppSpacing.lg + AppSpacing.xl,
                    textDirection: kReadingPageTurnDirection,
                    canGoNext: canGoNext,
                    canGoPrevious: canGoPrevious,
                    onNext: () => unawaited(_navigateAyah(ref, 1)),
                    onPrevious: () => unawaited(_navigateAyah(ref, -1)),
                    child: DirectionalContentSwitcher(
                      currentKey: ayaId,
                      slideDirection: slideDirection.value,
                      child: studyContent,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    return AppShortcutScope(
      autofocus: true,
      shortcuts: const {
        AppShortcutId.quranAyahNext,
        AppShortcutId.quranAyahPrev,
      },
      handlers: {
        AppShortcutId.quranAyahNext: () => unawaited(_navigateAyah(ref, 1)),
        AppShortcutId.quranAyahPrev: () => unawaited(_navigateAyah(ref, -1)),
      },
      child: panelContent,
    );
  }
}
