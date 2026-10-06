import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';

/// Last global ayah id in the standard Mushaf (Al-Fatiha:1 … An-Nas:6).
const kMaxQuranAyahId = 6236;

/// Computes the next study-mode ayah id after applying [delta], or null if unchanged.
int? nextStudyAyahId({required int? currentAyahId, required int delta}) {
  if (currentAyahId == null) return null;

  final newAyahId = (currentAyahId + delta).clamp(1, kMaxQuranAyahId);
  if (newAyahId == currentAyahId) return null;
  return newAyahId;
}

/// Keeps [MushafReaderController] highlight aligned with session selection.
void useQuranAyahSelectionSync(WidgetRef ref, {int? page}) {
  final controller = ref.watch(quranMushafControllerProvider);
  final selectedAyahId = ref.watch(quranSelectedAyahIdProvider);

  // Jump only when [page] changes — not on every rebuild.
  useEffect(() {
    if (page != null) controller.jumpToPage(page);
    return null;
  }, [page, controller]);

  useEffect(() {
    if (controller.selectedAyahId == selectedAyahId) return null;
    if (selectedAyahId == null) {
      controller.clearSelection();
    } else {
      controller.selectAyah(selectedAyahId);
    }
    return null;
  }, [selectedAyahId, controller]);
}

/// Updates session ayah selection (mushaf follows via [useQuranAyahSelectionSync]).
void setQuranSelectedAyah(WidgetRef ref, Ayah? ayah) {
  ref.read(quranSelectedAyahIdProvider.notifier).select(ayah?.ayahId);
}

/// Jumps to an ayah and selects it in session + mushaf.
Future<void> jumpToQuranAyah(WidgetRef ref, Ayah ayah) async {
  final controller = ref.read(quranMushafControllerProvider);
  ref.read(quranSelectedAyahIdProvider.notifier).select(ayah.ayahId);
  await controller.jumpToAyah(ayah.ayahId, select: true);
}

/// Toggles selection for the tapped ayah across mushaf and session state.
void toggleQuranAyahSelection(WidgetRef ref, Ayah ayah) {
  final previousId = ref.read(quranSelectedAyahIdProvider);
  if (previousId == ayah.ayahId) {
    setQuranSelectedAyah(ref, null);
  } else {
    setQuranSelectedAyah(ref, ayah);
  }
}

/// Opens Study with the first visible ayah when the reader has no selection.
/// Selection is kept on the current page even if its first fragment started on
/// the previous page. A late page load never replaces a newer user selection.
Future<bool> revealQuranStudy(WidgetRef ref) async {
  try {
    if (ref.read(quranSelectedAyahIdProvider) == null) {
      final controller = ref.read(quranMushafControllerProvider);
      final pageNumber = controller.currentPage;
      final page = await controller.getPage(pageNumber);
      if (!ref.context.mounted) return false;
      if (controller.currentPage != pageNumber) return false;
      final firstId = page.surahs.expand((s) => s.ayahs).firstOrNull?.ayahId;
      if (firstId == null) throw StateError('Current Quran page has no ayah');
      final ayah = await controller.getAyah(firstId);
      if (!ref.context.mounted || controller.currentPage != pageNumber)
        return false;
      if (ref.read(quranSelectedAyahIdProvider) == null) {
        setQuranSelectedAyah(ref, ayah);
        controller.selectAyah(ayah.ayahId);
      }
    }
    if (!ref.context.mounted) return false;
    ref
        .read(quranScreenSettingsProvider.notifier)
        .setSidePanelCollapsed(collapsed: false);
    return true;
  } catch (_) {
    if (ref.context.mounted) {
      showFToast(
        context: ref.context,
        variant: .destructive,
        title: Text(ref.context.l10n.studySelectionLoadFailed),
      );
    }
    return false;
  }
}

/// Moves study-mode ayah selection by [delta] (-1 / +1), or selects the first
/// ayah on the current page when nothing is selected.
Future<void> navigateStudyAyah({
  required WidgetRef ref,
  required int? currentAyahId,
  required int delta,
}) async {
  final controller = ref.read(quranMushafControllerProvider);
  final pageNumber = controller.currentPage;
  bool unchanged() =>
      ref.context.mounted &&
      ref.read(quranSelectedAyahIdProvider) == currentAyahId &&
      controller.currentPage == pageNumber;
  if (currentAyahId == null) {
    final page = await controller.getPage(pageNumber);
    if (!unchanged()) return;
    if (page.surahs.isEmpty) return;

    final firstFragment = page.surahs.first.ayahs.firstOrNull;
    if (firstFragment == null) return;

    final ayah = await controller.getAyah(firstFragment.ayahId);
    if (!unchanged()) return;
    await jumpToQuranAyah(ref, ayah);
    return;
  }

  final newAyahId = nextStudyAyahId(currentAyahId: currentAyahId, delta: delta);
  if (newAyahId == null) return;

  final ayah = await controller.getAyah(newAyahId);
  if (!unchanged()) return;
  await jumpToQuranAyah(ref, ayah);
}

/// Study-panel ayah navigation state shared by the panel body and header.
({
  int? currentAyahId,
  bool canGoNext,
  bool canGoPrevious,
  Future<void> Function(int delta) navigateAyah,
})
useStudyAyahNavigation(WidgetRef ref) {
  final currentAyahId = ref.watch(quranSelectedAyahIdProvider);

  return (
    currentAyahId: currentAyahId,
    canGoNext: currentAyahId == null || currentAyahId < kMaxQuranAyahId,
    canGoPrevious: currentAyahId == null || currentAyahId > 1,
    navigateAyah: (delta) =>
        navigateStudyAyah(ref: ref, currentAyahId: currentAyahId, delta: delta),
  );
}
