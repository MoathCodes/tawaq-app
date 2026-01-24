import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/feature/quran/presentation/widgets/content_accordion.dart';
import 'package:hasanat/feature/quran/presentation/widgets/notes_section.dart';
import 'package:hasanat/feature/quran/presentation/widgets/study_panel_header.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// A study companion panel for the Quran screen.
class StudyPanel extends HookConsumerWidget {
  /// Creates a study panel.
  const StudyPanel({
    required this.controller,
    super.key,
  });

  /// The mushaf reader controller.
  final MushafReaderController controller;

  /// Maximum ayah ID in the Quran.
  static const int _maxAyahId = 6236;

  void _navigateAyah(WidgetRef ref, int delta) {
    final current = ref.read(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.selectedAyah,
      ),
    );
    if (current == null) {
      // If no ayah selected, select first ayah on current page
      controller.getPage(controller.currentPage).then((page) {
        if (page.surahs.isNotEmpty) {
          final firstFragment = page.surahs.first.ayahs.firstOrNull;
          if (firstFragment != null) {
            controller.getAyah(firstFragment.ayahId).then((ayah) {
              ref.read(stateSettingsProvider.notifier).selectAyah(ayah);
              unawaited(controller.jumpToAyah(ayah.ayahId, select: true));
            });
          }
        }
      });
      return;
    }

    final newAyahId = (current.ayahId + delta).clamp(1, _maxAyahId);
    if (newAyahId == current.ayahId) return;

    controller.getAyah(newAyahId).then((ayah) {
      ref.read(stateSettingsProvider.notifier).selectAyah(ayah);
      unawaited(controller.jumpToAyah(ayah.ayahId, select: true));
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final typography = theme.typography;

    // Read quranState from provider - contains both pageInfo and selectedAyah
    final quranState = ref.watch(
      stateSettingsProvider.select((value) => value.value?.quranState),
    );
    final pageInfo = quranState?.pageInfo;
    final selectedAyah = quranState?.selectedAyah;

    // Get surah and ayah numbers for fetching content
    final sura = selectedAyah?.surahNumber ?? 1;
    final aya = selectedAyah?.numberInSurah ?? 1;
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

    final scrollContent = SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContentAccordion(
            colors: colors,
            typography: typography,
            sura: sura,
            aya: aya,
            hasSelectedAyah: selectedAyah != null,
          ),
          const SizedBox(height: AppSpacing.xl),
          NotesSection(
            colors: colors,
            typography: typography,
            ayahId: ayaId,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );

    final panelContent = StaticCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudyPanelHeader(
            colors: colors,
            typography: typography,
            controller: controller,
            surahName: pageInfo?.primarySurahName,
            ayahNumber: selectedAyah?.numberInSurah,
            currentAyahId: ayaId,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                // Check if this is the incoming or outgoing widget
                final isIncoming = child.key == ValueKey(ayaId);
                final direction = slideDirection.value.toDouble();

                // Incoming slides from opposite direction, outgoing slides out
                final beginOffset = isIncoming
                    ? Offset(-direction * 0.15, 0)
                    : Offset(direction * 0.15, 0);

                final slideOffset = Tween<Offset>(
                  begin: beginOffset,
                  end: Offset.zero,
                ).animate(animation);

                return SlideTransition(
                  position: slideOffset,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Align(
                alignment: Alignment.topCenter,
                child: KeyedSubtree(
                  key: ValueKey(ayaId),
                  child: scrollContent,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap with keyboard shortcuts and gesture navigation
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Arrow keys for ayah navigation
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _navigateAyah(ref, 1), // Next ayah (RTL Quran)
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _navigateAyah(ref, -1), // Previous ayah (RTL Quran)
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _navigateAyah(ref, 1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _navigateAyah(ref, -1),
      },
      child: Focus(
        autofocus: true,
        child: GestureDetector(
          // Horizontal swipe for ayah navigation
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 100) return; // Threshold
            // Swipe left = next ayah, swipe right = previous (RTL)
            _navigateAyah(ref, velocity < 0 ? 1 : -1);
          },
          child: panelContent,
        ),
      ),
    );
  }
}
