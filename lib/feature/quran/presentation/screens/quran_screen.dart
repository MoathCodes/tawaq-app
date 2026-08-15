import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_header_widget.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_mushaf_pane.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study_mode_layout.dart';
import 'package:tawaq/theme/theme.dart';

/// Screen that displays the Quran with various view modes.
class QuranScreen extends HookConsumerWidget {
  /// Creates a [QuranScreen] instance.
  const QuranScreen({this.page, this.onPageChanged, super.key});

  /// Optional mushaf page to open; null opens the default/persisted page.
  final int? page;

  /// Replaces the Quran route with the settled page.
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranScreenSettingsProvider);
    final checkpoint = settings.value?.lastPageNumber;
    final resolvedPage = (page ?? checkpoint)?.clamp(1, 604);

    useEffect(() {
      if (resolvedPage == null || page == resolvedPage) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPageChanged?.call(resolvedPage);
      });
      return null;
    }, [page, resolvedPage, onPageChanged]);

    useQuranAyahSelectionSync(ref, page: resolvedPage);
    _usePlaybackFollower(ref);

    final viewMode = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.layout ?? QuranReadingLayout.studyMode,
      ),
    );

    final mushafPane = QuranMushafPane(
      key: const ValueKey('quran-mushaf-pane'),
      onPageChanged: (nextPage) {
        ref
            .read(quranScreenSettingsProvider.notifier)
            .setLastPageNumber(nextPage);
        if (page != nextPage) onPageChanged?.call(nextPage);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const QuranHeaderWidget(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: switch (viewMode) {
              QuranReadingLayout.doublePage => mushafPane,
              QuranReadingLayout.studyMode => StudyModeLayout(
                mushaf: mushafPane,
              ),
            },
          ),
        ),
      ],
    );
  }
}

/// Projects playback highlighting into the mounted Quran reader only.
void _usePlaybackFollower(WidgetRef ref) {
  final controller = ref.watch(quranMushafControllerProvider);
  final target = ref.watch(
    recitationControllerProvider.select((s) => (s.surah, s.currentAyah)),
  );
  final preferences = ref.watch(recitationSettingsProvider).value;
  final highlight = preferences?.highlightAyah ?? true;
  final autoScroll = preferences?.autoScroll ?? true;

  useEffect(() {
    final surah = target.$1;
    final ayahNumber = target.$2;
    if (surah == null || ayahNumber == null || (!highlight && !autoScroll)) {
      return null;
    }
    var cancelled = false;
    unawaited(
      Future<void>(() async {
        final ayah = await mushafAyahOrNull(controller, surah, ayahNumber);
        if (cancelled || ayah == null) return;
        if (highlight) {
          ref.read(quranSelectedAyahIdProvider.notifier).select(ayah.ayahId);
        }
        if (autoScroll) {
          await controller.jumpToAyah(ayah.ayahId, select: highlight);
        }
      }),
    );
    return () => cancelled = true;
  }, [controller, target, highlight, autoScroll]);
}
