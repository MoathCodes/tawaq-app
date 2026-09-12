import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/core/widgets/numeric_step_button.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_range_formatters.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/range_endpoint_row.dart';
import 'package:tawaq/theme/theme.dart';

/// Display order for range preset tabs (decoupled from enum declaration order).
const _presetTabOrder = <RangeScopePreset>[
  RangeScopePreset.continueFromHere,
  RangeScopePreset.thisJuz,
  RangeScopePreset.thisHizb,
  RangeScopePreset.thisSurah,
  RangeScopePreset.thisAyah,
  RangeScopePreset.custom,
];

/// Seeds the range dialog from a selected ayah when nothing is playing yet.
class RangeRepeatInit {
  /// Creates a [RangeRepeatInit].
  const new({
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

/// The initial range values shown by the range dialog.
///
/// This is deliberately a display seed. It does not represent persisted
/// settings and is only applied when the dialog is opened.
class RangeRepeatSeed {
  /// Creates a [RangeRepeatSeed].
  const RangeRepeatSeed({
    required this.seedSurah,
    required this.seedAyah,
    required this.initialPreset,
    required this.isSuggestion,
    required this.fromSurah,
    required this.fromAyah,
    required this.toSurah,
    required this.toAyah,
  });

  /// Surah used as the anchor for preset changes.
  final int seedSurah;

  /// Ayah used as the anchor for preset changes.
  final int seedAyah;

  /// Preset selected when the dialog opens.
  final RangeScopePreset initialPreset;

  /// Whether these values are an unpersisted suggestion.
  final bool isSuggestion;

  /// Initial from-surah value.
  final int fromSurah;

  /// Initial from-ayah value.
  final int fromAyah;

  /// Initial to-surah value.
  final int toSurah;

  /// Initial to-ayah value.
  final int toAyah;
}

/// Resolves the display-only seed for the range dialog.
///
/// An explicit [initial] ayah always wins. Otherwise a saved range is
/// restored, then active playback/current reading is used, and finally a
/// safe surah-one fallback is shown. [ayahCount] keeps whole-surah defaults
/// accurate even when the repository has not populated [Surah.ayahCount].
RangeRepeatSeed resolveRangeRepeatSeed({
  required RangeRepeatInit? initial,
  required RecitationState playback,
  required RecitationSettings? settings,
  required Ayah? selectedAyah,
  required int Function(int surah) ayahCount,
}) {
  final hasSavedRange =
      settings?.lastRangePreset != null ||
      settings?.lastRangeFromSurah != null ||
      settings?.lastRangeFromAyah != null ||
      settings?.lastRangeToSurah != null ||
      settings?.lastRangeToAyah != null;
  final isSuggestion = initial == null && !hasSavedRange;

  final playbackFrom = playback.rangeFrom;
  final playbackTo = playback.rangeTo;
  final playbackHasRange = playbackFrom != null;
  final currentSurah = playback.surah ?? playbackFrom?.surah;
  final currentAyah = playback.currentAyah ?? playbackFrom?.ayah;
  final readingSurah = selectedAyah?.surahNumber;
  final readingAyah = selectedAyah?.numberInSurah;

  final seedSurah =
      initial?.surah ??
      currentSurah ??
      readingSurah ??
      settings?.lastSurah ??
      1;
  final seedAyah = initial?.startAyah ?? currentAyah ?? readingAyah ?? 1;

  final initialPreset = initial != null
      ? RangeScopePreset.thisAyah
      : settings?.lastRangePreset ??
            (playbackHasRange
                ? (playbackTo == null
                      ? RangeScopePreset.continueFromHere
                      : RangeScopePreset.custom)
                : (currentSurah != null || selectedAyah != null
                      ? RangeScopePreset.thisAyah
                      : RangeScopePreset.thisSurah));

  if (initial != null) {
    return RangeRepeatSeed(
      seedSurah: seedSurah,
      seedAyah: seedAyah,
      initialPreset: initialPreset,
      isSuggestion: false,
      fromSurah: initial.surah,
      fromAyah: initial.startAyah,
      toSurah: initial.surah,
      toAyah: initial.startAyah,
    );
  }

  final savedFromSurah = settings?.lastRangeFromSurah;
  final savedFromAyah = settings?.lastRangeFromAyah;
  final savedToSurah = settings?.lastRangeToSurah;
  final savedToAyah = settings?.lastRangeToAyah;

  final fromSurah = hasSavedRange
      ? savedFromSurah ??
            (initialPreset == RangeScopePreset.thisSurah
                ? settings?.lastSurah
                : null) ??
            playbackFrom?.surah ??
            seedSurah
      : playbackHasRange
      ? playbackFrom.surah
      : currentSurah ?? readingSurah ?? seedSurah;
  final fromAyah = hasSavedRange
      ? savedFromAyah ??
            (initialPreset == RangeScopePreset.thisSurah
                ? 1
                : playbackFrom?.ayah ?? seedAyah)
      : playbackHasRange
      ? playbackFrom.ayah
      : currentAyah ?? readingAyah ?? seedAyah;
  final toSurah = hasSavedRange
      ? savedToSurah ??
            (initialPreset == RangeScopePreset.thisSurah
                ? settings?.lastSurah
                : null) ??
            playbackTo?.surah ??
            fromSurah
      : playbackHasRange
      ? playbackTo?.surah ?? fromSurah
      : fromSurah;

  final wholeSurah = initialPreset == RangeScopePreset.thisSurah;
  final toAyah = wholeSurah
      ? ayahCount(toSurah)
      : hasSavedRange
      ? savedToAyah ?? playbackTo?.ayah ?? fromAyah
      : playbackHasRange
      ? playbackTo?.ayah ?? fromAyah
      : fromAyah;

  return RangeRepeatSeed(
    seedSurah: seedSurah,
    seedAyah: seedAyah,
    initialPreset: initialPreset,
    isSuggestion: isSuggestion,
    fromSurah: fromSurah,
    fromAyah: fromAyah,
    toSurah: toSurah,
    toAyah: toAyah,
  );
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
  const new({this.initial});

  final RangeRepeatInit? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialization = ref.watch(
      recitationControllerProvider.select(
        (state) => (
          status: state.initializationStatus,
          error: state.initializationError,
        ),
      ),
    );
    if (initialization.status == RecitationInitializationStatus.initializing) {
      return const _RangeRepeatDialogLoading();
    }
    if (initialization.status == RecitationInitializationStatus.failed) {
      return _RangeRepeatDialogFailure(error: initialization.error);
    }

    final l10n = context.l10n;
    final colors = context.theme.colors;
    final mushaf = ref.read(quranMushafControllerProvider);

    // Seed dialog fields once at open — do not live-track playback/selection.
    final seed = useMemoized(() {
      final playback = ref.read(recitationControllerProvider);
      final settings = ref.read(recitationSettingsProvider).value;
      final selectedReciter = ref
          .read(selectedRecitationProvider)
          .value
          ?.reciter;
      final selectedAyah = ref.read(quranSelectedAyahProvider).value;
      final resolved = resolveRangeRepeatSeed(
        initial: initial,
        playback: playback,
        settings: settings,
        selectedAyah: selectedAyah,
        ayahCount: (surah) =>
            mushaf.getSurahSync(surah)?.ayahCount ??
            (surah >= 1 && surah <= AyahIdResolver.ayahsPerSurah.length
                ? AyahIdResolver.ayahsPerSurah[surah - 1]
                : 1),
      );

      return (
        seedSurah: resolved.seedSurah,
        seedAyah: resolved.seedAyah,
        initialPreset: resolved.initialPreset,
        isSuggestion: resolved.isSuggestion,
        reciter: initial?.reciter ?? playback.reciter ?? selectedReciter,
        moshafId:
            initial?.moshaf.id ?? playback.moshaf?.id ?? settings?.moshafId,
        initialMoshaf: initial?.moshaf ?? playback.moshaf,
        ayahRepeat: settings?.ayahRepeatCount ?? 1,
        rangeRepeat: settings?.rangeRepeatCount ?? 1,
        fromSurah: resolved.fromSurah,
        fromAyah: resolved.fromAyah,
        toSurah: resolved.toSurah,
        toAyah: resolved.toAyah,
      );
    }, [initial]);

    final reciter = useState(seed.reciter);
    final moshafState = useState(
      seed.initialMoshaf ?? reciter.value?.resolveMoshaf(seed.moshafId),
    );
    final hasTiming = moshafState.value?.hasTiming ?? false;

    final range = _useRangePresetResolver(
      context: context,
      ref: ref,
      seedSurah: seed.seedSurah,
      seedAyah: seed.seedAyah,
      initialPreset: seed.initialPreset,
      initialFromSurah: seed.fromSurah,
      initialFromAyah: seed.fromAyah,
      initialToSurah: seed.toSurah,
      initialToAyah: seed.toAyah,
    );

    final ayahRepeat = useState(seed.ayahRepeat);
    final rangeRepeat = useState(seed.rangeRepeat);

    final isOpenEnded = range.preset.value == RangeScopePreset.continueFromHere;

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
        : AyahReference(surah: range.toSurah.value, ayah: range.toAyah.value);
    final rangeSummary = formatAyahRangeLabel(
      mushaf: mushaf,
      l10n: l10n,
      from: fromRef,
      to: toRef,
    );
    final presetIndex = _presetTabOrder.indexOf(range.preset.value);

    final needsTiming = rangeNeedsAyahTiming(
      preset: range.preset.value,
      from: fromRef,
      to: toRef,
      mushaf: mushaf,
    );
    final showTimingAlert = !hasTiming && needsTiming;
    final saveEnabled =
        !range.isResolving.value &&
        reciter.value != null &&
        moshafState.value != null &&
        (!needsTiming || hasTiming);

    Future<void> pickSyncedReciter() async {
      final pick = await showReciterDialog(
        context,
        intent: RecitationPickIntent.ayahLevel,
        initialTimedFilter: true,
        pickOnly: true,
      );
      if (pick == null || !context.mounted) return;
      reciter.value = pick.reciter;
      moshafState.value = pick.moshaf;
    }

    Future<void> pickReciter() async {
      final pick = await showReciterDialog(context, pickOnly: true);
      if (pick == null || !context.mounted) return;
      reciter.value = pick.reciter;
      moshafState.value = pick.moshaf;
    }

    return TawaqDialogShell(
      title: l10n.quranRangeTitle,
      subtitle: rangeSummary,
      maxHeight: 720,
      width: context.theme.breakpoints.md,
      scrollableBody: true,
      footer: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            FButton(
              onPress: saveEnabled
                  ? () => _save(
                      context,
                      ref,
                      from: fromRef,
                      to: toRef,
                      preset: range.preset.value,
                      ayahRepeat: hasTiming ? ayahRepeat.value : 1,
                      rangeRepeat: rangeRepeat.value,
                      reciter: reciter.value,
                      moshaf: moshafState.value,
                    )
                  : null,
              prefix: range.isResolving.value
                  ? const Icon(FLucideIcons.save)
                  : null,
              child: range.isResolving.value
                  ? const FCircularProgress(
                      size: FCircularProgressSizeVariant.sm,
                    )
                  : Text(l10n.quranRangeSave),
            ),
          ],
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
                if (seed.isSuggestion)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: FAlert(
                      icon: const Icon(FLucideIcons.info),
                      title: Text(l10n.quranRangeSuggestedHint),
                    ),
                  ),
                if (reciter.value == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: FButton(
                      onPress: pickReciter,
                      child: Text(l10n.quranSelectReciter),
                    ),
                  ),
                if (showTimingAlert)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: FAlert(
                      icon: const Icon(FLucideIcons.info),
                      title: Text(l10n.quranRangeRequiresTimedReciter),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          FButton(
                            onPress: pickSyncedReciter,
                            child: Text(l10n.quranRangeChooseSyncedReciter),
                          ),
                        ],
                      ),
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
                    presetLabel: presetLabel,
                    onPresetSelected: range.applyPreset,
                  )
                else
                  FTabs(
                    control: FTabControl.lifted(
                      index: presetIndex,
                      onChange: (index) {
                        if (range.isResolving.value) return;
                        range.applyPreset(_presetTabOrder[index]);
                      },
                    ),
                    style: context.theme.tabs.compact,
                    children: [
                      for (final p in _presetTabOrder)
                        FTabEntry(
                          label: Text(presetLabel(p)),
                          child: const SizedBox.shrink(),
                        ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.lg),
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
                        onSurahChanged: range.editFromSurah,
                        onAyahChanged: range.editFromAyah,
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
                          onSurahChanged: range.editToSurah,
                          onAyahChanged: range.editToAyah,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _RangeRepeatSectionLabel(
                  icon: FLucideIcons.repeat,
                  label: l10n.quranRecitationRangeRepeat,
                ),
                const SizedBox(height: AppSpacing.sm),
                _RangeRepeatControls(
                  ayahRepeat: ayahRepeat.value,
                  rangeRepeat: rangeRepeat.value,
                  narrow: narrow,
                  ayahEnabled: hasTiming,
                  ayahLabel: l10n.quranRecitationRepeatScopeEachAyah,
                  rangeLabel: l10n.quranRecitationRepeatScopeSelection,
                  onAyahChanged: (v) => ayahRepeat.value = v.clamp(1, 99),
                  onRangeChanged: (v) => rangeRepeat.value = v.clamp(1, 99),
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
    ref
        .read(recitationSettingsProvider.notifier)
        .setAyahRepeatCount(ayahRepeat);
    ref
        .read(recitationSettingsProvider.notifier)
        .setRangeRepeatCount(rangeRepeat);
    ref.read(recitationSettingsProvider.notifier).setLastRangePreset(preset);

    final r = reciter;
    final m = moshaf;
    if (r == null || m == null) return;

    final autoHighlight = ref
        .read(recitationSettingsProvider.notifier)
        .setReciter(reciterId: r.id, moshafId: m.id, moshafName: m.name);

    await ref
        .read(recitationControllerProvider.notifier)
        .playFromRangePreset(
          preset: preset,
          reciter: r,
          moshaf: m,
          from: from,
          to: to,
        );
    if (autoHighlight != null && context.mounted) {
      showRecitationHighlightAutoChangeToast(context, enabled: autoHighlight);
    }
    if (context.mounted) Navigator.of(context).maybePop();
  }
}

class _RangeRepeatDialogLoading extends StatelessWidget {
  const _RangeRepeatDialogLoading();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TawaqDialogShell(
      title: l10n.quranRangeTitle,
      maxHeight: 720,
      width: context.theme.breakpoints.md,
      scrollableBody: true,
      footer: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: FButton(onPress: null, child: Text(l10n.quranRangeSave)),
      ),
      child: FSkeletonizer(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Range summary'),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 36, color: context.theme.colors.secondary),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 132, color: context.theme.colors.secondary),
              const SizedBox(height: AppSpacing.xl),
              Container(height: 64, color: context.theme.colors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeRepeatDialogFailure extends ConsumerWidget {
  const _RangeRepeatDialogFailure({this.error});

  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return TawaqDialogShell(
      title: l10n.quranRangeTitle,
      maxHeight: 720,
      width: context.theme.breakpoints.md,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: FAlert(
          variant: .destructive,
          icon: const Icon(FLucideIcons.triangleAlert),
          title: Text(l10n.quranRecitationInitializationFailed),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(error!),
              ],
              const SizedBox(height: AppSpacing.md),
              FButton(
                onPress: () => ref
                    .read(recitationControllerProvider.notifier)
                    .retryInitialization(),
                child: Text(l10n.quranRecitationRetryInitialization),
              ),
            ],
          ),
        ),
      ),
    );
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
  void Function(int surah) editFromSurah,
  void Function(int ayah) editFromAyah,
  void Function(int surah) editToSurah,
  void Function(int ayah) editToAyah,
})
_useRangePresetResolver({
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
  // Mutable anchor so presets follow the user's chosen "from" endpoint.
  final anchorSurah = useRef(seedSurah);
  final anchorAyah = useRef(seedAyah);

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

  int surahAyahCount(int surah) =>
      mushaf.getSurahSync(surah)?.ayahCount ??
      (surah >= 1 && surah <= AyahIdResolver.ayahsPerSurah.length
          ? AyahIdResolver.ayahsPerSurah[surah - 1]
          : 1);

  void clampFromAyahToSurah() {
    final max = surahAyahCount(fromSurah.value);
    if (fromAyah.value > max) fromAyah.value = max;
    if (fromAyah.value < 1) fromAyah.value = 1;
  }

  void clampToAyahToSurah() {
    final max = surahAyahCount(toSurah.value);
    if (toAyah.value > max) toAyah.value = max;
    if (toAyah.value < 1) toAyah.value = 1;
  }

  void ensureFromBeforeTo() {
    final from = AyahReference(surah: fromSurah.value, ayah: fromAyah.value);
    final to = AyahReference(surah: toSurah.value, ayah: toAyah.value);
    if (to.isBefore(from)) {
      toSurah.value = fromSurah.value;
      toAyah.value = fromAyah.value;
    }
  }

  void ensureToAfterFrom() {
    final from = AyahReference(surah: fromSurah.value, ayah: fromAyah.value);
    final to = AyahReference(surah: toSurah.value, ayah: toAyah.value);
    if (to.isBefore(from)) {
      fromSurah.value = toSurah.value;
      fromAyah.value = toAyah.value;
    }
  }

  void snapToSurah(int surah) {
    final count = surahAyahCount(surah);
    fromSurah.value = surah;
    fromAyah.value = 1;
    toSurah.value = surah;
    toAyah.value = count;
  }

  void snapToSingleAyah(int surah, int ayah) {
    final clamped = ayah.clamp(1, surahAyahCount(surah));
    fromSurah.value = surah;
    fromAyah.value = clamped;
    toSurah.value = surah;
    toAyah.value = clamped;
  }

  void resolveDivisionFromFrom(RangeScopePreset divisionPreset) {
    final generation = ++presetGeneration.value;
    isResolving.value = true;
    if (divisionPreset == RangeScopePreset.thisJuz) {
      unawaited(resolveJuzPreset(generation, preset.value));
    } else {
      unawaited(resolveHizbPreset(generation, preset.value));
    }
  }

  void updateAnchorFromFrom() {
    anchorSurah.value = fromSurah.value;
    anchorAyah.value = fromAyah.value;
  }

  void applyPreset(RangeScopePreset p) {
    final previousPreset = preset.value;
    preset.value = p;
    switch (p) {
      case RangeScopePreset.thisAyah:
        presetGeneration.value++;
        isResolving.value = false;
        fromSurah.value = anchorSurah.value;
        fromAyah.value = anchorAyah.value;
        toSurah.value = anchorSurah.value;
        toAyah.value = anchorAyah.value;
      case RangeScopePreset.thisSurah:
        presetGeneration.value++;
        isResolving.value = false;
        final count = surahAyahCount(anchorSurah.value);
        fromSurah.value = anchorSurah.value;
        fromAyah.value = 1;
        toSurah.value = anchorSurah.value;
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
          fromSurah.value = anchorSurah.value;
          fromAyah.value = anchorAyah.value;
        }
      case RangeScopePreset.custom:
        presetGeneration.value++;
        isResolving.value = false;
        ensureFromBeforeTo();
    }
  }

  void editFromSurah(int surah) {
    presetGeneration.value++;
    isResolving.value = false;
    switch (preset.value) {
      case RangeScopePreset.custom:
        fromSurah.value = surah;
        fromAyah.value = 1;
        ensureFromBeforeTo();
      case RangeScopePreset.continueFromHere:
        fromSurah.value = surah;
        fromAyah.value = 1;
      case RangeScopePreset.thisAyah:
        snapToSingleAyah(surah, 1);
      case RangeScopePreset.thisSurah:
        snapToSurah(surah);
      case RangeScopePreset.thisJuz:
        fromSurah.value = surah;
        fromAyah.value = 1;
        resolveDivisionFromFrom(RangeScopePreset.thisJuz);
      case RangeScopePreset.thisHizb:
        fromSurah.value = surah;
        fromAyah.value = 1;
        resolveDivisionFromFrom(RangeScopePreset.thisHizb);
    }
    updateAnchorFromFrom();
  }

  void editFromAyah(int ayah) {
    presetGeneration.value++;
    isResolving.value = false;
    switch (preset.value) {
      case RangeScopePreset.custom:
        fromAyah.value = ayah;
        clampFromAyahToSurah();
        ensureFromBeforeTo();
      case RangeScopePreset.continueFromHere:
        fromAyah.value = ayah.clamp(1, surahAyahCount(fromSurah.value));
      case RangeScopePreset.thisAyah:
        snapToSingleAyah(fromSurah.value, ayah);
      case RangeScopePreset.thisSurah:
        if (ayah == 1) {
          fromAyah.value = 1;
        } else {
          preset.value = RangeScopePreset.custom;
          fromAyah.value = ayah.clamp(1, surahAyahCount(fromSurah.value));
          ensureFromBeforeTo();
        }
      case RangeScopePreset.thisJuz:
        fromAyah.value = ayah.clamp(1, surahAyahCount(fromSurah.value));
        resolveDivisionFromFrom(RangeScopePreset.thisJuz);
      case RangeScopePreset.thisHizb:
        fromAyah.value = ayah.clamp(1, surahAyahCount(fromSurah.value));
        resolveDivisionFromFrom(RangeScopePreset.thisHizb);
    }
    updateAnchorFromFrom();
  }

  void editToSurah(int surah) {
    presetGeneration.value++;
    isResolving.value = false;
    if (preset.value != RangeScopePreset.custom) {
      preset.value = RangeScopePreset.custom;
    }
    toSurah.value = surah;
    // Selecting a "to" surah usually means "through the end of that surah".
    toAyah.value = surahAyahCount(surah);
    ensureToAfterFrom();
  }

  void editToAyah(int ayah) {
    presetGeneration.value++;
    isResolving.value = false;
    if (preset.value != RangeScopePreset.custom) {
      preset.value = RangeScopePreset.custom;
    }
    toAyah.value = ayah;
    clampToAyahToSurah();
    ensureToAfterFrom();
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
    editFromSurah: editFromSurah,
    editFromAyah: editFromAyah,
    editToSurah: editToSurah,
    editToAyah: editToAyah,
  );
}

class _RangeRepeatSectionLabel extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
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
  const new({
    required this.presetIndex,
    required this.isResolving,
    required this.presetLabel,
    required this.onPresetSelected,
  });

  final int presetIndex;
  final bool isResolving;
  final String Function(RangeScopePreset) presetLabel;
  final ValueChanged<RangeScopePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, p) in _presetTabOrder.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index < _presetTabOrder.length - 1 ? AppSpacing.xs : 0,
            ),
            child: FButton(
              variant: presetIndex == index
                  ? FButtonVariant.primary
                  : FButtonVariant.outline,
              onPress: isResolving ? null : () => onPresetSelected(p),
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

class _RangeRepeatControls extends StatelessWidget {
  const new({
    required this.ayahRepeat,
    required this.rangeRepeat,
    required this.ayahLabel,
    required this.rangeLabel,
    required this.onAyahChanged,
    required this.onRangeChanged,
    this.narrow = false,
    this.ayahEnabled = true,
  });

  final int ayahRepeat;
  final int rangeRepeat;
  final String ayahLabel;
  final String rangeLabel;
  final ValueChanged<int> onAyahChanged;
  final ValueChanged<int> onRangeChanged;
  final bool narrow;
  final bool ayahEnabled;

  @override
  Widget build(BuildContext context) {
    final eachAyah = _CompactRepeatStepper(
      icon: FLucideIcons.audioLines,
      label: ayahLabel,
      count: ayahRepeat,
      enabled: ayahEnabled,
      onChanged: onAyahChanged,
    );
    final selection = _CompactRepeatStepper(
      icon: FLucideIcons.repeat,
      label: rangeLabel,
      count: rangeRepeat,
      onChanged: onRangeChanged,
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          eachAyah,
          const SizedBox(height: AppSpacing.md),
          selection,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: eachAyah),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: selection),
      ],
    );
  }
}

class _CompactRepeatStepper extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.count,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final int count;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.secondary,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.xs.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NumericStepButton(
                icon: FLucideIcons.minus,
                enabled: enabled && count > 1,
                onPress: () => onChanged(count - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  '×$count',
                  style: typography.body.md.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                ),
              ),
              NumericStepButton(
                icon: FLucideIcons.plus,
                enabled: enabled && count < 99,
                onPress: () => onChanged(count + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
