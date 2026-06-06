import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/use_cases/navigate_study_ayah.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

/// Keeps [MushafReaderController] highlight aligned with persisted selection.
void useQuranAyahSelectionSync(
  WidgetRef ref,
  MushafReaderController controller,
) {
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
void setQuranSelectedAyah(
  WidgetRef ref,
  MushafReaderController controller,
  Ayah? ayah,
) {
  ref.read(quranScreenSettingsProvider.notifier).selectAyah(ayah);
  if (ayah == null) {
    controller.clearSelection();
  } else {
    controller.selectAyah(ayah.ayahId);
  }
}

/// Jumps to an ayah and selects it in both mushaf and persisted state.
Future<void> jumpToQuranAyah(
  WidgetRef ref,
  MushafReaderController controller,
  Ayah ayah,
) async {
  ref.read(quranScreenSettingsProvider.notifier).selectAyah(ayah);
  await controller.jumpToAyah(ayah.ayahId, select: true);
}

/// Toggles selection for the tapped ayah across mushaf and persisted state.
void toggleQuranAyahSelection(
  WidgetRef ref,
  MushafReaderController controller,
  Ayah ayah,
) {
  final previousId = ref.read(
    quranScreenSettingsProvider.select(
      (v) => v.value?.selectedAyah?.ayahId,
    ),
  );
  if (previousId == ayah.ayahId) {
    setQuranSelectedAyah(ref, controller, null);
  } else {
    setQuranSelectedAyah(ref, controller, ayah);
  }
}

/// Moves study-mode ayah selection by [delta] (-1 / +1), or selects the first
/// ayah on the current page when nothing is selected.
Future<void> navigateStudyAyah({
  required WidgetRef ref,
  required MushafReaderController controller,
  required int? currentAyahId,
  required int delta,
}) async {
  if (currentAyahId == null) {
    final page = await controller.getPage(controller.currentPage);
    if (page.surahs.isEmpty) return;

    final firstFragment = page.surahs.first.ayahs.firstOrNull;
    if (firstFragment == null) return;

    final ayah = await controller.getAyah(firstFragment.ayahId);
    await jumpToQuranAyah(ref, controller, ayah);
    return;
  }

  final newAyahId = nextStudyAyahId(currentAyahId: currentAyahId, delta: delta);
  if (newAyahId == null) return;

  final ayah = await controller.getAyah(newAyahId);
  await jumpToQuranAyah(ref, controller, ayah);
}
