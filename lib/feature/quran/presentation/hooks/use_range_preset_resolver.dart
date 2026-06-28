import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';
import 'package:tawaq/feature/quran/domain/models/range_scope_preset.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';

/// State and callbacks for resolving range presets in the range/repeat dialog.
({
  ObjectRef<int> presetGeneration,
  ValueNotifier<bool> isResolving,
  ValueNotifier<RangeScopePreset> preset,
  ValueNotifier<int> fromSurah,
  ValueNotifier<int> fromAyah,
  ValueNotifier<int> toSurah,
  ValueNotifier<int> toAyah,
  void Function(RangeScopePreset preset) applyPreset,
  void Function(int ayah) syncFromAyah,
  void Function(int ayah) syncToAyah,
}) useRangePresetResolver({
  required BuildContext context,
  required WidgetRef ref,
  required int seedSurah,
  required int seedAyah,
  required RangeScopePreset initialPreset,
  required int initialFromSurah,
  required int initialFromAyah,
  required int initialToSurah,
  required int initialToAyah,
}) {
  final mushaf = ref.read(quranMushafControllerProvider);
  final l10n = context.l10n;

  final preset = useState(initialPreset);
  final fromSurah = useState(initialFromSurah);
  final fromAyah = useState(initialFromAyah);
  final toSurah = useState(initialToSurah);
  final toAyah = useState(initialToAyah);
  final isResolving = useState(false);
  final presetGeneration = useRef(0);

  void showPresetError(String message) {
    showFToast(
      context: context,
      variant: .destructive,
      icon: const Icon(FLucideIcons.triangleAlert),
      title: Text(message),
    );
  }

  void revertPreset(RangeScopePreset previous) {
    preset.value = previous;
  }

  void finishPresetResolution(int generation) {
    if (generation == presetGeneration.value) {
      isResolving.value = false;
    }
  }

  void handleDivisionResult({
    required int generation,
    required RangeScopePreset revertTo,
    required ({DivisionRange? range, DivisionResolveError? error}) result,
    required String numberNotFoundMessage,
    required String boundsNotFoundMessage,
  }) {
    if (generation != presetGeneration.value) return;

    final range = result.range;
    if (range != null) {
      fromSurah.value = range.from.surah;
      fromAyah.value = range.from.ayah;
      toSurah.value = range.to.surah;
      toAyah.value = range.to.ayah;
      finishPresetResolution(generation);
      return;
    }

    final message = switch (result.error) {
      DivisionResolveError.numberNotFound => numberNotFoundMessage,
      DivisionResolveError.boundsNotFound => boundsNotFoundMessage,
      DivisionResolveError.failed || null => l10n.quranRangePresetFailed,
    };
    if (context.mounted) showPresetError(message);
    revertPreset(revertTo);
    finishPresetResolution(generation);
  }

  Future<void> resolveJuzPreset(
    int generation,
    RangeScopePreset revertTo,
  ) async {
    final result = await resolveJuzRangeForAyah(
      mushaf,
      fromSurah.value,
      fromAyah.value,
    );
    if (!context.mounted) return;
    handleDivisionResult(
      generation: generation,
      revertTo: revertTo,
      result: result,
      numberNotFoundMessage: l10n.quranRangeJuzNotFound,
      boundsNotFoundMessage: l10n.quranRangeJuzBoundsNotFound,
    );
  }

  Future<void> resolveHizbPreset(
    int generation,
    RangeScopePreset revertTo,
  ) async {
    final result = await resolveHizbRangeForAyah(
      mushaf,
      fromSurah.value,
      fromAyah.value,
    );
    if (!context.mounted) return;
    handleDivisionResult(
      generation: generation,
      revertTo: revertTo,
      result: result,
      numberNotFoundMessage: l10n.quranRangeHizbNotFound,
      boundsNotFoundMessage: l10n.quranRangeHizbBoundsNotFound,
    );
  }

  void applyPreset(RangeScopePreset p) {
    final previousPreset = preset.value;
    preset.value = p;
    switch (p) {
      case RangeScopePreset.thisAyah:
        presetGeneration.value++;
        isResolving.value = false;
        fromSurah.value = seedSurah;
        fromAyah.value = seedAyah;
        toSurah.value = seedSurah;
        toAyah.value = seedAyah;
      case RangeScopePreset.thisSurah:
        presetGeneration.value++;
        isResolving.value = false;
        final count = mushaf.getSurahSync(seedSurah)?.ayahCount ?? seedAyah;
        fromSurah.value = seedSurah;
        fromAyah.value = 1;
        toSurah.value = seedSurah;
        toAyah.value = count;
      case RangeScopePreset.thisJuz:
        final generation = ++presetGeneration.value;
        isResolving.value = true;
        unawaited(resolveJuzPreset(generation, previousPreset));
      case RangeScopePreset.thisHizb:
        final generation = ++presetGeneration.value;
        isResolving.value = true;
        unawaited(resolveHizbPreset(generation, previousPreset));
      case RangeScopePreset.continueFromHere:
        presetGeneration.value++;
        isResolving.value = false;
        if (previousPreset != RangeScopePreset.continueFromHere) {
          fromSurah.value = seedSurah;
          fromAyah.value = seedAyah;
        }
      case RangeScopePreset.custom:
        presetGeneration.value++;
        isResolving.value = false;
    }
  }

  void syncFromAyah(int ayah) {
    final openEnded = preset.value == RangeScopePreset.continueFromHere;
    if (!openEnded) {
      preset.value = RangeScopePreset.custom;
    }
    fromAyah.value = ayah;
    final from = AyahReference(surah: fromSurah.value, ayah: ayah);
    if (!openEnded) {
      final to = AyahReference(surah: toSurah.value, ayah: toAyah.value);
      if (to.isBefore(from)) {
        toSurah.value = fromSurah.value;
        toAyah.value = ayah;
      }
    }
  }

  void syncToAyah(int ayah) {
    preset.value = RangeScopePreset.custom;
    toAyah.value = ayah;
    final from = AyahReference(surah: fromSurah.value, ayah: fromAyah.value);
    final to = AyahReference(surah: toSurah.value, ayah: ayah);
    if (to.isBefore(from)) {
      fromSurah.value = toSurah.value;
      fromAyah.value = ayah;
    }
  }

  return (
    presetGeneration: presetGeneration,
    isResolving: isResolving,
    preset: preset,
    fromSurah: fromSurah,
    fromAyah: fromAyah,
    toSurah: toSurah,
    toAyah: toAyah,
    applyPreset: applyPreset,
    syncFromAyah: syncFromAyah,
    syncToAyah: syncToAyah,
  );
}
