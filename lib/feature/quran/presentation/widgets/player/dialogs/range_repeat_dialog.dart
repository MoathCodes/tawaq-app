import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/timed_riwayat_suggestions.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_range_formatters.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/range_endpoint_row.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';
import 'package:tawaq/core/widgets/numeric_step_button.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog.dart';



/// Seeds the range dialog from a selected ayah when nothing is playing yet.
class RangeRepeatInit {
  /// Creates a [RangeRepeatInit].
  const RangeRepeatInit({
    required this.reciter,
    required this.moshaf,
    required this.surah,
    required this.startAyah,
  });

  /// Reciter to play the range with.
  final Reciter reciter;

  /// Moshaf (riwayah) to play the range with.
  final Moshaf moshaf;

  /// Surah number (1-114).
  final int surah;

  /// Ayah the range defaults to (from = to = this).
  final int startAyah;
}

/// Opens the range & repeat dialog. With no [initial] it targets the active
/// recitation; with [initial] it is seeded from a selected ayah.
Future<void> showRangeRepeatDialog(
  BuildContext context, {
  RangeRepeatInit? initial,
}) => showFDialog<void>(
  context: context,
  useRootNavigator: true,
  builder: (context, style, animation) => _RangeRepeatDialog(initial: initial),
);

class _RangeRepeatDialog extends HookConsumerWidget {
  const _RangeRepeatDialog({this.initial});

  final RangeRepeatInit? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.theme.colors;
    final playback = ref.watch(recitationControllerProvider);
    final settings = ref.watch(recitationSettingsProvider).value;
    final selectedReciter = ref.watch(selectedReciterProvider).value;
    final catalog = ref.watch(recitersProvider).value ?? const <Reciter>[];
    final mushaf = ref.read(quranMushafControllerProvider);

    final seedSurah = initial?.surah ??
        playback.surah ??
        ref.watch(quranScreenSettingsProvider).value?.selectedAyah?.surahNumber ??
        1;
    final seedAyah =
        initial?.startAyah ??
        playback.rangeFrom?.ayah ??
        playback.currentAyah ??
        ref.watch(quranScreenSettingsProvider).value?.selectedAyah?.numberInSurah ??
        1;

    final reciter = useState(
      initial?.reciter ?? playback.reciter ?? selectedReciter,
    );
    final savedMoshafId =
        initial?.moshaf.id ?? playback.moshaf?.id ?? settings?.moshafId;
    final moshafState = useState(reciter.value?.resolveMoshaf(savedMoshafId));
    final hasTiming = moshafState.value?.hasTiming ?? false;
    final hasSeedContext = initial != null || playback.active;

    final savedPreset = settings?.lastRangePreset;
    final initialPreset =
        savedPreset ??
        (hasSeedContext
            ? RangeScopePreset.thisAyah
            : RangeScopePreset.custom);

    final viewedAyah = initial == null
        ? ref.watch(quranScreenSettingsProvider).value?.selectedAyah
        : null;

    final range = _useRangePresetResolver(
      context: context,
      ref: ref,
      seedSurah: seedSurah,
      seedAyah: seedAyah,
      initialPreset: initialPreset,
      initialFromSurah:
          viewedAyah?.surahNumber ??
          settings?.lastRangeFromSurah ??
          playback.rangeFrom?.surah ??
          initial?.surah ??
          playback.surah ??
          seedSurah,
      initialFromAyah:
          viewedAyah?.numberInSurah ??
          settings?.lastRangeFromAyah ??
          playback.rangeFrom?.ayah ??
          initial?.startAyah ??
          playback.currentAyah ??
          seedAyah,
      initialToSurah:
          viewedAyah?.surahNumber ??
          settings?.lastRangeToSurah ??
          playback.rangeTo?.surah ??
          initial?.surah ??
          playback.surah ??
          seedSurah,
      initialToAyah:
          viewedAyah?.numberInSurah ??
          settings?.lastRangeToAyah ??
          playback.rangeTo?.ayah ??
          initial?.startAyah ??
          playback.currentAyah ??
          seedAyah,
    );

    final ayahRepeat = useState(settings?.ayahRepeatCount ?? 1);
    final rangeRepeat = useState(settings?.rangeRepeatCount ?? 1);

    final timedSuggestions = useMemoized(
      () => buildTimedRiwayatSuggestions(reciter.value, catalog),
      [reciter.value, catalog],
    );
    final timedSuggestionsAvailable = timedSuggestions.isNotEmpty;

    bool presetNeedsTiming(RangeScopePreset p) =>
        p != RangeScopePreset.thisSurah &&
        !(p == RangeScopePreset.continueFromHere && range.fromAyah.value == 1);

    bool presetEnabled(RangeScopePreset p) {
      if (p == RangeScopePreset.thisSurah) return hasSeedContext;
      return hasTiming || timedSuggestionsAvailable;
    }

    final isOpenEnded =
        range.preset.value == RangeScopePreset.continueFromHere;
    final showTimedPicker =
        presetNeedsTiming(range.preset.value) && !hasTiming;

    String presetLabel(RangeScopePreset p) => switch (p) {
      RangeScopePreset.thisAyah => l10n.quranRangePresetAyah,
      RangeScopePreset.thisSurah => l10n.quranRangePresetSurah,
      RangeScopePreset.thisJuz => l10n.quranRangePresetJuz,
      RangeScopePreset.thisHizb => l10n.quranRangePresetHizb,
      RangeScopePreset.continueFromHere =>
        l10n.quranRangePresetContinueFromHere,
      RangeScopePreset.custom => l10n.quranRangePresetCustom,
    };

    final fromRef = AyahReference(
      surah: range.fromSurah.value,
      ayah: range.fromAyah.value,
    );
    final toRef = isOpenEnded
        ? null
        : AyahReference(
            surah: range.toSurah.value,
            ayah: range.toAyah.value,
          );
    final rangeSummary = formatAyahRangeLabel(
      mushaf: mushaf,
      l10n: l10n,
      from: fromRef,
      to: toRef,
    );
    final presetIndex = RangeScopePreset.values.indexOf(range.preset.value);

    return PlayerDialogShell(
      title: l10n.quranRangeTitle,
      subtitle: rangeSummary,
      maxHeight: 720,
      width: context.theme.breakpoints.sm,
      scrollableBody: true,
      footer: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: FButton(
          onPress: range.isResolving.value ||
                  showTimedPicker ||
                  reciter.value == null ||
                  moshafState.value == null
              ? null
              : () => _save(
                  context,
                  ref,
                  from: fromRef,
                  to: toRef,
                  preset: range.preset.value,
                  ayahRepeat: ayahRepeat.value,
                  rangeRepeat: rangeRepeat.value,
                  reciter: reciter.value,
                  moshaf: moshafState.value,
                ),
          prefix: range.isResolving.value
              ? const Icon(FLucideIcons.save)
              : null,
          child: range.isResolving.value
              ? const FCircularProgress(
                  size: FCircularProgressSizeVariant.sm,
                )
              : Text(l10n.quranRangeSave),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 480;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!hasTiming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: FAlert(
                      icon: const Icon(FLucideIcons.info),
                      title: Text(l10n.quranRecitationNoTiming),
                    ),
                  ),
                _RangeRepeatSectionLabel(
                  icon: FLucideIcons.bookOpen,
                  label: l10n.quranRangeScope,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (narrow)
                  _RangeRepeatPresetList(
                    presetIndex: presetIndex,
                    isResolving: range.isResolving.value,
                    presetEnabled: presetEnabled,
                    presetLabel: presetLabel,
                    onPresetSelected: range.applyPreset,
                  )
                else
                  FTabs(
                    control: FTabControl.lifted(
                      index: presetIndex,
                      onChange: (index) {
                        if (range.isResolving.value) return;
                        final p = RangeScopePreset.values[index];
                        if (!presetEnabled(p)) return;
                        range.applyPreset(p);
                      },
                    ),
                    style: const .delta(
                      padding: .value(EdgeInsets.all(2)),
                      indicatorSize: FTabBarIndicatorSize.tab,
                    ),
                    children: [
                      for (final p in RangeScopePreset.values)
                        FTabEntry(
                          label: Opacity(
                            opacity: presetEnabled(p) ? 1 : 0.45,
                            child: Text(presetLabel(p)),
                          ),
                          child: const SizedBox.shrink(),
                        ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (showTimedPicker)
                  _TimedRiwayatPicker(
                    suggestions: timedSuggestions,
                    selectedReciterId: reciter.value?.id,
                    selectedMoshafId: moshafState.value?.id,
                    onPick: (r, m) {
                      reciter.value = r;
                      moshafState.value = m;
                      ref
                          .read(recitationSettingsProvider.notifier)
                          .setReciter(
                            reciterId: r.id,
                            moshafId: m.id,
                          );
                    },
                  ),
                if (showTimedPicker) const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    border: Border.all(
                      color: range.preset.value == RangeScopePreset.custom
                          ? colors.primary.withValues(alpha: 0.5)
                          : colors.border,
                    ),
                    borderRadius: context.theme.radii.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RangeEndpointRow(
                        prefix: l10n.quranRangeFromShort,
                        surah: range.fromSurah.value,
                        ayah: range.fromAyah.value,
                        surahLabel: l10n.quranRangeFromSurah,
                        ayahLabel: l10n.quranRangeFromAyah,
                        onSurahChanged: (s) {
                          range.presetGeneration.value++;
                          range.isResolving.value = false;
                          range.fromSurah.value = s;
                          final max =
                              mushaf.getSurahSync(s)?.ayahCount ?? 1;
                          if (range.fromAyah.value > max) {
                            range.fromAyah.value = max;
                          }
                          if (isOpenEnded) {
                            range.fromAyah.value =
                                range.fromAyah.value.clamp(1, max);
                          } else {
                            range.syncFromAyah(range.fromAyah.value);
                          }
                        },
                        onAyahChanged: range.syncFromAyah,
                      ),
                      if (!isOpenEnded) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Container(
                            height: 1,
                            color: colors.border.withValues(alpha: 0.6),
                          ),
                        ),
                        RangeEndpointRow(
                          prefix: l10n.quranRangeToShort,
                          surah: range.toSurah.value,
                          ayah: range.toAyah.value,
                          surahLabel: l10n.quranRangeToSurah,
                          ayahLabel: l10n.quranRangeToAyah,
                          onSurahChanged: (s) {
                            range.presetGeneration.value++;
                            range.isResolving.value = false;
                            range.toSurah.value = s;
                            final max = mushaf.getSurahSync(s)?.ayahCount ?? 1;
                            if (range.toAyah.value > max) {
                              range.toAyah.value = max;
                            }
                            range.syncToAyah(range.toAyah.value);
                          },
                          onAyahChanged: range.syncToAyah,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _RangeRepeatCountRow(
                  label: l10n.quranRangeRepeatEachAyah,
                  count: ayahRepeat.value,
                  narrow: narrow,
                  enabled: hasTiming,
                  onChanged: (value) {
                    ayahRepeat.value = value.clamp(1, 99);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                _RangeRepeatCountRow(
                  label: l10n.quranRangeRepeatSelection,
                  count: rangeRepeat.value,
                  narrow: narrow,
                  onChanged: (value) {
                    rangeRepeat.value = value.clamp(1, 99);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    required AyahReference from,
    required AyahReference? to,
    required RangeScopePreset preset,
    required int ayahRepeat,
    required int rangeRepeat,
    required Reciter? reciter,
    required Moshaf? moshaf,
  }) async {
    ref.read(recitationSettingsProvider.notifier).setAyahRepeatCount(ayahRepeat);
    ref
        .read(recitationSettingsProvider.notifier)
        .setRangeRepeatCount(rangeRepeat);
    ref.read(recitationSettingsProvider.notifier).setLastRangePreset(preset);

    final r = reciter;
    final m = moshaf;
    if (r == null || m == null) return;

    await ref.read(recitationControllerProvider.notifier).playFromRangePreset(
      preset: preset,
      reciter: r,
      moshaf: m,
      from: from,
      to: to,
    );
    if (context.mounted) unawaited(Navigator.of(context).maybePop());
  }
}



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
}) _useRangePresetResolver({
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


class _RangeRepeatSectionLabel extends StatelessWidget {
  const _RangeRepeatSectionLabel({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: context.theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
      ],
    );
  }
}

class _RangeRepeatPresetList extends StatelessWidget {
  const _RangeRepeatPresetList({
    required this.presetIndex,
    required this.isResolving,
    required this.presetEnabled,
    required this.presetLabel,
    required this.onPresetSelected,
    super.key,
  });

  final int presetIndex;
  final bool isResolving;
  final bool Function(RangeScopePreset) presetEnabled;
  final String Function(RangeScopePreset) presetLabel;
  final ValueChanged<RangeScopePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, p) in RangeScopePreset.values.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index < RangeScopePreset.values.length - 1
                  ? AppSpacing.xs
                  : 0,
            ),
            child: FButton(
              variant: presetIndex == index
                  ? FButtonVariant.primary
                  : FButtonVariant.outline,
              onPress: isResolving || !presetEnabled(p)
                  ? null
                  : () => onPresetSelected(p),
              child: Text(presetLabel(p)),
            ),
          ),
        if (isResolving) ...[
          const SizedBox(height: AppSpacing.sm),
          const Center(
            child: FCircularProgress(size: FCircularProgressSizeVariant.sm),
          ),
        ],
      ],
    );
  }
}

class _TimedRiwayatPicker extends StatelessWidget {
  const _TimedRiwayatPicker({
    required this.suggestions,
    required this.selectedReciterId,
    required this.selectedMoshafId,
    required this.onPick,
    super.key,
  });

  final List<ReciterPick> suggestions;
  final int? selectedReciterId;
  final int? selectedMoshafId;
  final void Function(Reciter reciter, Moshaf moshaf) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RangeRepeatSectionLabel(
          icon: FLucideIcons.audioLines,
          label: l10n.quranRecitationNoTiming,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.secondary,
            border: Border.all(color: colors.border),
            borderRadius: context.theme.radii.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, suggestion) in suggestions.indexed) ...[
                FTile(
                  title: Text(
                    '${suggestion.reciter.name} · ${suggestion.moshaf.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  suffix: selectedReciterId == suggestion.reciter.id &&
                          selectedMoshafId == suggestion.moshaf.id
                      ? Icon(
                          FLucideIcons.check,
                          size: 16,
                          color: colors.primary,
                        )
                      : null,
                  onPress: () => onPick(suggestion.reciter, suggestion.moshaf),
                ),
                if (index < suggestions.length - 1)
                  Container(height: 1, color: colors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RangeRepeatCountRow extends StatelessWidget {
  const _RangeRepeatCountRow({
    required this.label,
    required this.count,
    required this.onChanged,
    this.narrow = false,
    this.enabled = true,
    super.key,
  });

  final String label;
  final int count;
  final ValueChanged<int> onChanged;
  final bool narrow;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    Widget chip(int value) {
      final active = count == value;
      return FButton(
        variant: active ? FButtonVariant.primary : FButtonVariant.outline,
        size: FButtonSizeVariant.sm,
        mainAxisSize: MainAxisSize.min,
        onPress: enabled ? () => onChanged(value) : null,
        child: Text(l10n.quranRangeRepeatChip(value)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (narrow)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RangeRepeatSectionLabel(
                icon: FLucideIcons.repeat,
                label: label,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [chip(1), chip(3), chip(5)],
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _RangeRepeatSectionLabel(
                  icon: FLucideIcons.repeat,
                  label: label,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  chip(1),
                  const SizedBox(width: AppSpacing.xs),
                  chip(3),
                  const SizedBox(width: AppSpacing.xs),
                  chip(5),
                ],
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.secondary,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              NumericStepButton(
                icon: FLucideIcons.minus,
                size: NumericStepButtonSize.large,
                enabled: enabled && count > 1,
                onPress: () => onChanged(count - 1),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '×',
                          style: typography.body.lg.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$count',
                          style: typography.body.lg.copyWith(
                            color: colors.foreground,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      repeatCountLabel(l10n, count),
                      style: typography.body.sm.copyWith(
                        color: colors.mutedForeground,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              NumericStepButton(
                icon: FLucideIcons.plus,
                size: NumericStepButtonSize.large,
                enabled: enabled && count < 99,
                onPress: () => onChanged(count + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
