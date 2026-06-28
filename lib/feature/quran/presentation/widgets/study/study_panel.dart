import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';
import 'package:tawaq/core/widgets/reading_swipe_viewport.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/content_accordion.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/notes_section.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel_header.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel_width_scope.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// A study companion panel for the Quran screen.
class StudyPanel extends HookConsumerWidget {
  /// Creates a study panel.
  const StudyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAyah = ref.watch(
      quranScreenSettingsProvider.select(
        (value) => value.value?.selectedAyah,
      ),
    );
    final ayaId = selectedAyah?.ayahId;
    final navigation = useStudyAyahNavigation(ref);

    final prevAyahId = usePrevious(ayaId);
    final slideDirection = useState(0);

    useEffect(
      () {
        if (prevAyahId != null && ayaId != null && prevAyahId != ayaId) {
          slideDirection.value = ayaId > prevAyahId ? -1 : 1;
        }
        return null;
      },
      [ayaId],
    );

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
                    canGoNext: navigation.canGoNext,
                    canGoPrevious: navigation.canGoPrevious,
                    onNext: () => unawaited(navigation.navigateAyah(1)),
                    onPrevious: () => unawaited(navigation.navigateAyah(-1)),
                    child: DirectionalContentSwitcher(
                      currentKey: ayaId,
                      slideDirection: slideDirection.value,
                      child: StudyPanelWidthScope(
                        width: constraints.maxWidth,
                        child: const _StudyPanelBody(),
                      ),
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
        AppShortcut.quranAyahNext,
        AppShortcut.quranAyahPrev,
      },
      handlers: {
        AppShortcut.quranAyahNext: () => unawaited(navigation.navigateAyah(1)),
        AppShortcut.quranAyahPrev: () => unawaited(navigation.navigateAyah(-1)),
      },
      child: panelContent,
    );
  }
}

class _StudyPanelBody extends StatelessWidget {
  const _StudyPanelBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContentAccordion(),
        SizedBox(height: AppSpacing.xl),
        NotesSection(),
      ],
    );
  }
}
