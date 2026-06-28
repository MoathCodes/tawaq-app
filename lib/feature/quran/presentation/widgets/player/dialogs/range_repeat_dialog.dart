import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';
import 'package:tawaq/feature/quran/domain/models/range_scope_preset.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/range_repeat_sections.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/timed_riwayat_suggestions.dart';
import 'package:tawaq/feature/quran/presentation/hooks/use_range_preset_resolver.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_range_formatters.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/range_endpoint_row.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

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

    final range = useRangePresetResolver(
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
                RangeRepeatSectionLabel(
                  icon: FLucideIcons.bookOpen,
                  label: l10n.quranRangeScope,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (narrow)
                  RangeRepeatPresetList(
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
                  TimedRiwayatPicker(
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
                RangeRepeatCountRow(
                  label: l10n.quranRangeRepeatEachAyah,
                  count: ayahRepeat.value,
                  narrow: narrow,
                  enabled: hasTiming,
                  onChanged: (value) {
                    ayahRepeat.value = value.clamp(1, 99);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                RangeRepeatCountRow(
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
