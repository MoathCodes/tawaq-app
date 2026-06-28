import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';

/// Last global ayah id in the standard Mushaf (Al-Fatiha:1 … An-Nas:6).
const kMaxQuranAyahId = 6236;

/// Computes the next study-mode ayah id after applying [delta], or null if unchanged.
int? nextStudyAyahId({
  required int? currentAyahId,
  required int delta,
}) {
  if (currentAyahId == null) return null;

  final newAyahId = (currentAyahId + delta).clamp(1, kMaxQuranAyahId);
  if (newAyahId == currentAyahId) return null;
  return newAyahId;
}

/// Keeps [MushafReaderController] highlight aligned with persisted selection.
void useQuranAyahSelectionSync(WidgetRef ref) {
  final controller = ref.watch(quranMushafControllerProvider);
  final selectedAyahId = ref.watch(
    quranScreenSettingsProvider.select(
      (v) => v.value?.selectedAyah?.ayahId,
    ),
  );

  useEffect(() {
    if (controller.selectedAyahId == selectedAyahId) return null;
    if (selectedAyahId == null) {
      controller.clearSelection();
    } else {
      controller.selectAyah(selectedAyahId);
    }
    return null;
  }, [selectedAyahId]);
}

/// Updates mushaf highlight and persisted ayah selection together.
void setQuranSelectedAyah(WidgetRef ref, Ayah? ayah) {
  final controller = ref.read(quranMushafControllerProvider);
  ref.read(quranScreenSettingsProvider.notifier).selectAyah(ayah);
  if (ayah == null) {
    controller.clearSelection();
  } else {
    controller.selectAyah(ayah.ayahId);
  }
}

/// Jumps to an ayah and selects it in both mushaf and persisted state.
Future<void> jumpToQuranAyah(WidgetRef ref, Ayah ayah) async {
  final controller = ref.read(quranMushafControllerProvider);
  ref.read(quranScreenSettingsProvider.notifier).selectAyah(ayah);
  await controller.jumpToAyah(ayah.ayahId, select: true);
}

/// Toggles selection for the tapped ayah across mushaf and persisted state.
void toggleQuranAyahSelection(WidgetRef ref, Ayah ayah) {
  final previousId = ref.read(
    quranScreenSettingsProvider.select(
      (v) => v.value?.selectedAyah?.ayahId,
    ),
  );
  if (previousId == ayah.ayahId) {
    setQuranSelectedAyah(ref, null);
  } else {
    setQuranSelectedAyah(ref, ayah);
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
  if (currentAyahId == null) {
    final page = await controller.getPage(controller.currentPage);
    if (page.surahs.isEmpty) return;

    final firstFragment = page.surahs.first.ayahs.firstOrNull;
    if (firstFragment == null) return;

    final ayah = await controller.getAyah(firstFragment.ayahId);
    await jumpToQuranAyah(ref, ayah);
    return;
  }

  final newAyahId = nextStudyAyahId(currentAyahId: currentAyahId, delta: delta);
  if (newAyahId == null) return;

  final ayah = await controller.getAyah(newAyahId);
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
  final currentAyahId = ref.watch(
    quranScreenSettingsProvider.select(
      (v) => v.value?.selectedAyah?.ayahId,
    ),
  );

  return (
    currentAyahId: currentAyahId,
    canGoNext: currentAyahId == null || currentAyahId < kMaxQuranAyahId,
    canGoPrevious: currentAyahId == null || currentAyahId > 1,
    navigateAyah: (delta) => navigateStudyAyah(
      ref: ref,
      currentAyahId: currentAyahId,
      delta: delta,
    ),
  );
}
