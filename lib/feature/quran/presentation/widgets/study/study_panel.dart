import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/lazy_tab_content.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';
import 'package:tawaq/core/widgets/reading_swipe_viewport.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/notes_browser.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/notes_section.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_content_section.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel_header.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/tafsir_text.dart';
import 'package:tawaq/theme/theme.dart';

/// A study companion panel for the Quran screen.
class StudyPanel extends HookConsumerWidget {
  /// Creates a study panel.
  const StudyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAyah = ref.watch(quranSelectedAyahProvider).value;
    final ayaId = selectedAyah?.ayahId;
    final navigation = useStudyAyahNavigation(ref);
    final activeTab = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.activeStudyTab ?? StudyPanelTab.currentAyah,
      ),
    );
    final notesCount = ref.watch(
      quranAllNotesProvider.select((v) => v.value?.length ?? 0),
    );

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

    // Selecting an ayah anywhere (mushaf tap, search, note card) surfaces its
    // study content instead of leaving the reflections list open.
    // Deferred: Riverpod forbids provider writes during build/effect flush.
    useEffect(
      () {
        if (ayaId == null || activeTab == StudyPanelTab.currentAyah) {
          return null;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(quranScreenSettingsProvider.notifier)
              .setActiveStudyTab(StudyPanelTab.currentAyah);
        });
        return null;
      },
      [ayaId],
    );

    final theme = context.theme;
    final l10n = context.l10n;
    final tabIndex = activeTab.index;
    final onCurrentAyahTab = activeTab == StudyPanelTab.currentAyah;

    final panelContent = QuranSemantics.landmark(
      label: l10n.studyMode,
      child: StaticCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StudyPanelHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: FTabs(
                  expands: true,
                  style: theme.tabs.primary,
                  control: FTabControl.lifted(
                    index: tabIndex,
                    onChange: (index) {
                      final tab = StudyPanelTab.values[index];
                      ref
                          .read(quranScreenSettingsProvider.notifier)
                          .setActiveStudyTab(tab);
                    },
                  ),
                  children: [
                    FTabEntry(
                      label: Text(l10n.studyTabCurrentAyah),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final narrowPanel =
                              constraints.maxWidth <
                              context.theme.breakpoints.sm;
                          return ReadingSwipeViewport(
                            viewportMinHeight: constraints.maxHeight,
                            horizontalPadding: 0,
                            topPadding: AppSpacing.md,
                            bottomPadding: AppSpacing.lg + AppSpacing.xl,
                            textDirection: kReadingPageTurnDirection,
                            canGoNext: onCurrentAyahTab && navigation.canGoNext,
                            canGoPrevious:
                                onCurrentAyahTab && navigation.canGoPrevious,
                            onNext: () => unawaited(navigation.navigateAyah(1)),
                            onPrevious: () =>
                                unawaited(navigation.navigateAyah(-1)),
                            child: DirectionalContentSwitcher(
                              currentKey: ayaId,
                              slideDirection: slideDirection.value,
                              child: _StudyPanelBody(
                                ayahId: ayaId,
                                narrowPanel: narrowPanel,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    FTabEntry(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.studyTabMyReflections),
                          if (notesCount > 0) ...[
                            const SizedBox(width: AppSpacing.sm),
                            FBadge(child: Text('$notesCount')),
                          ],
                        ],
                      ),
                      child: LazyPanelContent.indexed(
                        selectedIndex: tabIndex,
                        index: StudyPanelTab.reflections.index,
                        builder: () => const Padding(
                          padding: EdgeInsets.only(
                            top: AppSpacing.md,
                            bottom: AppSpacing.lg,
                          ),
                          child: NotesBrowser(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return AppShortcutScope(
      autofocus: true,
      shortcuts: {
        if (onCurrentAyahTab) ...{
          AppShortcut.quranAyahNext,
          AppShortcut.quranAyahPrev,
        },
      },
      handlers: {
        if (onCurrentAyahTab) ...{
          AppShortcut.quranAyahNext: () =>
              unawaited(navigation.navigateAyah(1)),
          AppShortcut.quranAyahPrev: () =>
              unawaited(navigation.navigateAyah(-1)),
        },
      },
      child: panelContent,
    );
  }
}

class _StudyPanelBody extends StatelessWidget {
  const _StudyPanelBody({
    required this.ayahId,
    required this.narrowPanel,
  });

  final int? ayahId;
  final bool narrowPanel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StudyContentAccordion(narrowPanel: narrowPanel),
        const SizedBox(height: AppSpacing.xl),
        NotesSection(
          key: ValueKey(ayahId ?? 'no-ayah'),
          ayahId: ayahId,
          narrowPanel: narrowPanel,
        ),
      ],
    );
  }
}

/// Tafsir and translation accordion for the selected ayah.
class _StudyContentAccordion extends ConsumerWidget {
  const _StudyContentAccordion({required this.narrowPanel});

  final bool narrowPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;

    final selectedAyah = ref.watch(quranSelectedAyahProvider).value;
    final hasSelectedAyah = selectedAyah != null;
    final sura = selectedAyah?.surahNumber ?? 1;
    final aya = selectedAyah?.numberInSurah ?? 1;

    final tafsirEnabled = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.tafsirEnabled ?? true,
      ),
    );
    final translationEnabled = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.translationEnabled ?? true,
      ),
    );
    final selectedTafsir = ref.watch(
      quranScreenSettingsProvider.select((v) => v.value?.selectedTafsir),
    );
    final selectedTranslation = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.selectedTranslation ?? kDefaultTranslationId,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AbsorbPointer(
          absorbing: !hasSelectedAyah,
          child: Opacity(
            opacity: hasSelectedAyah ? 1 : 0.45,
            child: FAccordion(
              control: FAccordionControl.lifted(
                expanded: (index) =>
                    hasSelectedAyah &&
                    switch (index) {
                      0 => tafsirEnabled,
                      1 => translationEnabled,
                      _ => false,
                    },
                onChange: (index, isExpanded) {
                  if (!hasSelectedAyah) return;
                  switch (index) {
                    case 0:
                      ref
                          .read(quranScreenSettingsProvider.notifier)
                          .setTafsirEnabled(enabled: isExpanded);
                    case 1:
                      ref
                          .read(quranScreenSettingsProvider.notifier)
                          .setTranslationEnabled(enabled: isExpanded);
                  }
                },
              ),
              style: .delta(
                dividerStyle: .delta(
                  color: colors.border,
                  padding: const .value(EdgeInsets.zero),
                ),
              ),
              children: [
                FAccordionItem(
                  title: studyAccordionTitle(
                    context,
                    label: l10n.tafsir,
                    icon: FLucideIcons.messageSquare,
                    hasSelectedAyah: hasSelectedAyah,
                    expanded: tafsirEnabled,
                  ),
                  child: TafsirStudySection(
                    sura: sura,
                    aya: aya,
                    source: selectedTafsir,
                    enabled: hasSelectedAyah && tafsirEnabled,
                    narrowPanel: narrowPanel,
                  ),
                ),
                FAccordionItem(
                  title: studyAccordionTitle(
                    context,
                    label: l10n.translation,
                    icon: FLucideIcons.languages,
                    hasSelectedAyah: hasSelectedAyah,
                    expanded: translationEnabled,
                  ),
                  child: TranslationAccordionSection(
                    sura: sura,
                    aya: aya,
                    source: selectedTranslation,
                    enabled: hasSelectedAyah && translationEnabled,
                    narrowPanel: narrowPanel,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!hasSelectedAyah) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  FLucideIcons.info,
                  size: 16,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.selectAyahToSeeContent,
                    style: typography.body.sm.copyWith(
                      color: colors.mutedForeground,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
