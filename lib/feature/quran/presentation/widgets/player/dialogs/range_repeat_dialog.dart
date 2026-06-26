import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/core/widgets/numeric_step_button.dart';
import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';
import 'package:tawaq/feature/quran/domain/models/range_scope_preset.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_mode.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_pick_intent.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/lifted_surah_ayah_selectors.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_pick_resolver.dart';
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

    final seedSurah = initial?.surah ?? playback.surah ?? 1;
    final seedAyah =
        initial?.startAyah ?? playback.rangeStart ?? playback.currentAyah ?? 1;

    final reciter = initial?.reciter ?? playback.reciter ?? selectedReciter;
    final savedMoshafId =
        initial?.moshaf.id ?? playback.moshaf?.id ?? settings?.moshafId;
    final resolvedMoshaf = reciter?.resolveMoshafForIntent(
      savedMoshafId,
      RecitationPickIntent.ayahLevel,
    );
    final hasTiming =
        resolvedMoshaf?.hasTiming ?? catalog.any((r) => r.hasTiming);
    final hasSeedContext = initial != null || playback.active;

    final savedPreset = settings?.lastRangePreset;
    final preset = useState(
      savedPreset ??
          (hasSeedContext
              ? RangeScopePreset.thisAyah
              : RangeScopePreset.custom),
    );
    final fromSurah = useState(
      settings?.lastRangeFromSurah ??
          playback.rangeFrom?.surah ??
          initial?.surah ??
          playback.surah ??
          seedSurah,
    );
    final fromAyah = useState(
      settings?.lastRangeFromAyah ??
          playback.rangeFrom?.ayah ??
          initial?.startAyah ??
          playback.rangeStart ??
          playback.currentAyah ??
          seedAyah,
    );
    final toSurah = useState(
      settings?.lastRangeToSurah ??
          playback.rangeTo?.surah ??
          initial?.surah ??
          playback.surah ??
          seedSurah,
    );
    final toAyah = useState(
      settings?.lastRangeToAyah ??
          playback.rangeTo?.ayah ??
          initial?.startAyah ??
          playback.rangeEnd ??
          playback.currentAyah ??
          seedAyah,
    );
    final repeat = useState(settings?.repeatCount ?? 1);
    final mode = useState(settings?.mode ?? RecitationMode.stopAtEnd);
    final isResolving = useState(false);
    final presetGeneration = useRef(0);

    bool presetEnabled(RangeScopePreset p) => switch (p) {
      RangeScopePreset.thisAyah ||
      RangeScopePreset.thisSurah => hasTiming && hasSeedContext,
      _ => hasTiming,
    };

    final isOpenEnded = preset.value == RangeScopePreset.continueFromHere;

    String presetLabel(RangeScopePreset p) => switch (p) {
      RangeScopePreset.thisAyah => l10n.quranRangePresetAyah,
      RangeScopePreset.thisSurah => l10n.quranRangePresetSurah,
      RangeScopePreset.thisJuz => l10n.quranRangePresetJuz,
      RangeScopePreset.thisHizb => l10n.quranRangePresetHizb,
      RangeScopePreset.continueFromHere =>
        l10n.quranRangePresetContinueFromHere,
      RangeScopePreset.custom => l10n.quranRangePresetCustom,
    };

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
      required DivisionRangeResolveResult result,
      required String numberNotFoundMessage,
      required String boundsNotFoundMessage,
    }) {
      if (generation != presetGeneration.value) return;

      switch (result) {
        case DivisionRangeResolved(:final from, :final to):
          fromSurah.value = from.surah;
          fromAyah.value = from.ayah;
          toSurah.value = to.surah;
          toAyah.value = to.ayah;
          finishPresetResolution(generation);
        case DivisionNumberNotFound():
          if (context.mounted) showPresetError(numberNotFoundMessage);
          revertPreset(revertTo);
          finishPresetResolution(generation);
        case DivisionBoundsNotFound():
          if (context.mounted) showPresetError(boundsNotFoundMessage);
          revertPreset(revertTo);
          finishPresetResolution(generation);
        case DivisionResolveFailed():
          if (context.mounted) showPresetError(l10n.quranRangePresetFailed);
          revertPreset(revertTo);
          finishPresetResolution(generation);
      }
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
          fromSurah.value = seedSurah;
          fromAyah.value = seedAyah;
        case RangeScopePreset.custom:
          presetGeneration.value++;
          isResolving.value = false;
      }
    }

    void syncFromAyah(int ayah) {
      preset.value = RangeScopePreset.custom;
      fromAyah.value = ayah;
      final from = AyahReference(surah: fromSurah.value, ayah: ayah);
      if (!isOpenEnded) {
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

    final fromRef = AyahReference(surah: fromSurah.value, ayah: fromAyah.value);
    final toRef = isOpenEnded
        ? null
        : AyahReference(surah: toSurah.value, ayah: toAyah.value);
    final rangeSummary = formatAyahRangeLabel(
      mushaf: mushaf,
      l10n: l10n,
      from: fromRef,
      to: toRef,
    );
    final presetIndex = RangeScopePreset.values.indexOf(preset.value);

    return PlayerDialogShell(
      title: l10n.quranRangeTitle,
      subtitle: rangeSummary,
      maxHeight: 720,
      width: context.theme.breakpoints.sm,
      scrollableBody: true,
      footer: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: FButton(
          onPress: isResolving.value
              ? null
              : () => _save(
                  context,
                  ref,
                  from: fromRef,
                  to: toRef,
                  preset: preset.value,
                  repeat: repeat.value,
                  mode: mode.value,
                  reciter: reciter,
                  moshaf: resolvedMoshaf,
                ),
          prefix: isResolving.value ? const Icon(FLucideIcons.save) : null,
          child: isResolving.value
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
                _SectionLabel(
                  icon: FLucideIcons.bookOpen,
                  label: l10n.quranRangeScope,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (narrow)
                  _PresetList(
                    presetIndex: presetIndex,
                    isResolving: isResolving.value,
                    presetEnabled: presetEnabled,
                    presetLabel: presetLabel,
                    onPresetSelected: applyPreset,
                  )
                else
                  FTabs(
                    control: FTabControl.lifted(
                      index: presetIndex,
                      onChange: (index) {
                        if (isResolving.value) return;
                        final p = RangeScopePreset.values[index];
                        if (!presetEnabled(p)) return;
                        applyPreset(p);
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
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    border: Border.all(
                      color: preset.value == RangeScopePreset.custom
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
                        surah: fromSurah.value,
                        ayah: fromAyah.value,
                        surahLabel: l10n.quranRangeFromSurah,
                        ayahLabel: l10n.quranRangeFromAyah,
                        onSurahChanged: (s) {
                          presetGeneration.value++;
                          isResolving.value = false;
                          fromSurah.value = s;
                          final max = mushaf.getSurahSync(s)?.ayahCount ?? 1;
                          if (fromAyah.value > max) fromAyah.value = max;
                          syncFromAyah(fromAyah.value);
                        },
                        onAyahChanged: syncFromAyah,
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
                          surah: toSurah.value,
                          ayah: toAyah.value,
                          surahLabel: l10n.quranRangeToSurah,
                          ayahLabel: l10n.quranRangeToAyah,
                          onSurahChanged: (s) {
                            presetGeneration.value++;
                            isResolving.value = false;
                            toSurah.value = s;
                            final max = mushaf.getSurahSync(s)?.ayahCount ?? 1;
                            if (toAyah.value > max) toAyah.value = max;
                            syncToAyah(toAyah.value);
                          },
                          onAyahChanged: syncToAyah,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _ModeSection(
                  mode: mode.value,
                  narrow: narrow,
                  onChanged: (value) => mode.value = value,
                ),
                const SizedBox(height: AppSpacing.xl),
                _RepeatSection(
                  count: repeat.value,
                  narrow: narrow,
                  enabled: mode.value == RecitationMode.repeatSelection,
                  onChanged: (value) {
                    repeat.value = value.clamp(1, 99);
                    if (value > 1 &&
                        mode.value != RecitationMode.repeatSelection) {
                      mode.value = RecitationMode.repeatSelection;
                    }
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
    required int repeat,
    required RecitationMode mode,
    required Reciter? reciter,
    required Moshaf? moshaf,
  }) async {
    ref.read(recitationSettingsProvider.notifier).setRepeatCount(repeat);
    ref.read(recitationSettingsProvider.notifier).setMode(mode);
    final controller = ref.read(recitationControllerProvider.notifier);

    var r = reciter;
    var m = moshaf;
    if (r == null || m == null || !m.hasTiming) {
      final pick = await resolveReciterForAyahPlayback(context, ref);
      if (pick == null) return;
      r = pick.reciter;
      m = pick.moshaf;
    }

    // Save the range and stop current playback — user presses play to start.
    await controller.saveRange(from: from, to: to, preset: preset);
    if (context.mounted) unawaited(Navigator.of(context).maybePop());
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

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

class _RepeatSection extends StatelessWidget {
  const _RepeatSection({
    required this.count,
    required this.onChanged,
    this.narrow = false,
    this.enabled = true,
  });

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

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (narrow)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionLabel(
                    icon: FLucideIcons.repeat,
                    label: l10n.quranRangeRepeatWhole,
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
                    child: _SectionLabel(
                      icon: FLucideIcons.repeat,
                      label: l10n.quranRangeRepeatWhole,
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
        ),
      ),
    );
  }
}

class _ModeSection extends StatelessWidget {
  const _ModeSection({
    required this.mode,
    required this.onChanged,
    this.narrow = false,
  });

  final RecitationMode mode;
  final ValueChanged<RecitationMode> onChanged;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    Widget chip(RecitationMode value, String label) {
      final active = mode == value;
      return FButton(
        variant: active ? FButtonVariant.primary : FButtonVariant.outline,
        size: FButtonSizeVariant.sm,
        mainAxisSize: MainAxisSize.min,
        onPress: () => onChanged(value),
        child: Text(label),
      );
    }

    final stopLabel = l10n.quranRecitationModeStopAtEnd;
    final repeatLabel = l10n.quranRecitationModeRepeat;
    final continueLabel = l10n.quranRecitationModeContinue;

    final chips = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip(RecitationMode.stopAtEnd, stopLabel),
        const SizedBox(width: AppSpacing.xs),
        chip(RecitationMode.repeatSelection, repeatLabel),
        const SizedBox(width: AppSpacing.xs),
        chip(RecitationMode.continueToNextSurah, continueLabel),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (narrow)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel(
                icon: FLucideIcons.arrowRightToLine,
                label: l10n.quranRangeModeLabel,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  chip(RecitationMode.stopAtEnd, stopLabel),
                  chip(RecitationMode.repeatSelection, repeatLabel),
                  chip(RecitationMode.continueToNextSurah, continueLabel),
                ],
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _SectionLabel(
                  icon: FLucideIcons.arrowRightToLine,
                  label: l10n.quranRangeModeLabel,
                ),
              ),
              chips,
            ],
          ),
      ],
    );
  }
}

class _PresetList extends StatelessWidget {
  const _PresetList({
    required this.presetIndex,
    required this.isResolving,
    required this.presetEnabled,
    required this.presetLabel,
    required this.onPresetSelected,
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
