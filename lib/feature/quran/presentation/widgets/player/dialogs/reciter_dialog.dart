import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_pick_intent.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/reciter_tags.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

enum _ReciterRowKind { header, moshaf }

class _ReciterRow {
  const _ReciterRow.header({
    required this.reciter,
    required this.single,
    required this.isApplied,
    required this.expanded,
    required this.allMoshafs,
    required this.selectableMoshaf,
  }) : kind = _ReciterRowKind.header,
       moshaf = null,
       selectable = true,
       appliedMoshaf = false;

  const _ReciterRow.moshaf({
    required this.reciter,
    required this.moshaf,
    required this.selectable,
    required this.appliedMoshaf,
  }) : kind = _ReciterRowKind.moshaf,
       single = false,
       isApplied = false,
       expanded = false,
       allMoshafs = const [],
       selectableMoshaf = null;

  final _ReciterRowKind kind;
  final Reciter reciter;
  final Moshaf? moshaf;
  final bool single;
  final bool isApplied;
  final bool expanded;
  final List<Moshaf> allMoshafs;
  final Moshaf? selectableMoshaf;
  final bool selectable;
  final bool appliedMoshaf;
}

/// The reciter/riwayah a user picked.
typedef ReciterPick = ({Reciter reciter, Moshaf moshaf});

/// Opens the reciter & riwayah picker.
///
/// When [pickOnly] is true the user's pick is returned without applying playback
/// changes (ayah-level flows). Otherwise the chosen reciter is applied to the
/// active recitation and null is returned.
Future<ReciterPick?> showReciterDialog(
  BuildContext context, {
  RecitationPickIntent intent = RecitationPickIntent.general,
  bool pickOnly = false,
}) => showFDialog<ReciterPick>(
  context: context,
  builder: (context, _, _) =>
      _ReciterDialog(intent: intent, pickOnly: pickOnly),
);

class _ReciterDialog extends HookConsumerWidget {
  const _ReciterDialog({
    required this.intent,
    required this.pickOnly,
  });

  final RecitationPickIntent intent;
  final bool pickOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colors = theme.colors;

    final query = useState('');
    final filtersOpen = useState(false);
    final downloadedFilter = useState(false);
    final styleFilter = useState<Set<RecitationStyle>>(const {});
    final riwayahFilter = useState<Set<String>>(const {});
    final expandedId = useState<int?>(null);

    final recitersAsync = ref.watch(recitersProvider);
    final reciters = recitersAsync.value ?? const <Reciter>[];
    final settings = ref.watch(recitationSettingsProvider).value;
    final selectedReciterId = settings?.reciterId;
    final selectedMoshafId = settings?.moshafId;

    final cached = ref.watch(cachedRecitationsProvider).value ?? const [];
    final downloadedKeys = useMemoized(
      () => cached.map((c) => (c.reciterId, c.moshafId)).toSet(),
      [cached],
    );

    final riwayahOptions = useMemoized(() {
      final set = <String>{};
      for (final r in reciters) {
        for (final m in r.moshaf) {
          final t = moshafTags(m.name).riwayah;
          if (t != null) set.add(t);
        }
      }
      return set.toList()..sort();
    }, [reciters]);

    final filter = query.value.trim().toLowerCase();
    bool matches(Reciter r) {
      if (filter.isNotEmpty && !r.name.toLowerCase().contains(filter)) {
        return false;
      }
      if (downloadedFilter.value &&
          !r.moshaf.any(
            (m) => downloadedKeys.contains((r.id, m.id)),
          )) {
        return false;
      }
      if (styleFilter.value.isNotEmpty &&
          !r.moshaf.any(
            (m) => styleFilter.value.contains(moshafTags(m.name).style),
          )) {
        return false;
      }
      if (riwayahFilter.value.isNotEmpty &&
          !r.moshaf.any(
            (m) => riwayahFilter.value.contains(moshafTags(m.name).riwayah),
          )) {
        return false;
      }
      return true;
    }

    var filtered = reciters.where(matches).toList();
    if (intent == RecitationPickIntent.ayahLevel) {
      filtered = [
        ...filtered.where((r) => r.hasTiming),
        ...filtered.where((r) => !r.hasTiming),
      ];
    }

    final activeFilterCount = [
      if (downloadedFilter.value) 1,
      styleFilter.value.length,
      riwayahFilter.value.length,
    ].fold<int>(0, (sum, n) => sum + n);

    Future<void> apply(Reciter r, Moshaf m) async {
      final resolved = intent == RecitationPickIntent.ayahLevel
          ? r.resolveMoshafForIntent(m.id, intent)
          : m;
      if (resolved == null) return;

      ref
          .read(recitationSettingsProvider.notifier)
          .setReciter(
            reciterId: r.id,
            moshafId: resolved.id,
          );

      if (pickOnly) {
        if (!context.mounted) return;
        Navigator.of(context).pop((reciter: r, moshaf: resolved));
        return;
      }

      final controller = ref.read(recitationControllerProvider.notifier);
      final playback = ref.read(recitationControllerProvider);
      final surah = playback.surah;
      if (surah == null) return;

      if (playback.isCrossSurahRange) {
        await controller.playAyahRange(
          reciter: r,
          moshaf: resolved,
          from: playback.rangeFrom!,
          to: playback.rangeTo!,
        );
      } else if (playback.isRange) {
        await controller.playRange(
          reciter: r,
          moshaf: resolved,
          surah: surah,
          startAyah: playback.rangeStart!,
          endAyah: playback.rangeEnd!,
        );
      } else {
        await controller.playSurah(reciter: r, moshaf: resolved, surah: surah);
      }
    }

    final rowEntries = useMemoized(
      () => _reciterRowEntries(
        filtered: filtered,
        intent: intent,
        selectedReciterId: selectedReciterId,
        selectedMoshafId: selectedMoshafId,
        expandedId: expandedId.value,
      ),
      [
        filtered,
        intent,
        selectedReciterId,
        selectedMoshafId,
        expandedId.value,
      ],
    );

    return PlayerDialogShell(
      title: l10n.quranReciterRiwayahTitle,
      width: 560,
      maxHeight: 680,
      scrollableBody: true,
      headerBottom: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 480;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              FTextField(
                hint: l10n.quranReciterSearchHint,
                control: FTextFieldControl.managed(
                  onChange: (value) => query.value = value.text,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (narrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FButton(
                      variant: filtersOpen.value || activeFilterCount > 0
                          ? FButtonVariant.primary
                          : FButtonVariant.outline,
                      size: FButtonSizeVariant.sm,
                      onPress: () => filtersOpen.value = !filtersOpen.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(FLucideIcons.slidersHorizontal, size: 14),
                          const SizedBox(width: AppSpacing.xs),
                          Text(l10n.quranReciterFilters),
                          if (activeFilterCount > 0) ...[
                            const SizedBox(width: AppSpacing.xs),
                            FBadge(
                              variant: FBadgeVariant.secondary,
                              child: Text('$activeFilterCount'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (filtersOpen.value) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ReciterFilterChips(
                        downloadedFilter: downloadedFilter,
                        styleFilter: styleFilter,
                        riwayahFilter: riwayahFilter,
                        riwayahOptions: riwayahOptions,
                        stackVertically: true,
                      ),
                    ],
                  ],
                )
              else ...[
                Row(
                  children: [
                    FButton(
                      variant: filtersOpen.value || activeFilterCount > 0
                          ? FButtonVariant.primary
                          : FButtonVariant.outline,
                      size: FButtonSizeVariant.sm,
                      onPress: () => filtersOpen.value = !filtersOpen.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(FLucideIcons.slidersHorizontal, size: 14),
                          const SizedBox(width: AppSpacing.xs),
                          Text(l10n.quranReciterFilters),
                          if (activeFilterCount > 0) ...[
                            const SizedBox(width: AppSpacing.xs),
                            FBadge(
                              variant: FBadgeVariant.secondary,
                              child: Text('$activeFilterCount'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (filtersOpen.value) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ReciterFilterChips(
                    downloadedFilter: downloadedFilter,
                    styleFilter: styleFilter,
                    riwayahFilter: riwayahFilter,
                    riwayahOptions: riwayahOptions,
                  ),
                ],
              ],
            ],
          );
        },
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: recitersAsync.isLoading && reciters.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: FCircularProgress()),
              )
            : filtered.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  l10n.quranNoMatchingReciters,
                  textAlign: TextAlign.center,
                  style: theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rowEntries.length,
                itemBuilder: (context, index) {
                  final row = rowEntries[index];
                  return switch (row.kind) {
                    _ReciterRowKind.header => FTile(
                      title: Text(row.reciter.name),
                      subtitle: row.expanded
                          ? null
                          : Text(
                              row.allMoshafs.map((m) => m.name).join('  ·  '),
                            ),
                      suffix: _reciterSuffix(
                        theme: theme,
                        single: row.single,
                        isApplied: row.isApplied,
                        expanded: row.expanded,
                      ),
                      selected: row.isApplied,
                      onPress: () {
                        if (row.single && row.selectableMoshaf != null) {
                          unawaited(apply(row.reciter, row.selectableMoshaf!));
                        } else {
                          expandedId.value = expandedId.value == row.reciter.id
                              ? null
                              : row.reciter.id;
                        }
                      },
                    ),
                    _ReciterRowKind.moshaf => FTile(
                      prefix: const SizedBox(width: AppSpacing.lg),
                      title: Text(
                        row.moshaf!.name,
                        style: row.selectable
                            ? null
                            : theme.typography.body.sm.copyWith(
                                color: colors.mutedForeground,
                              ),
                      ),
                      subtitle: row.selectable
                          ? null
                          : Text(
                              l10n.quranReciterSurahOnly,
                              style: theme.typography.body.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                      suffix: row.appliedMoshaf
                          ? _SelectedMark(theme: theme)
                          : null,
                      selected: row.appliedMoshaf,
                      onPress: row.selectable
                          ? () => unawaited(apply(row.reciter, row.moshaf!))
                          : null,
                    ),
                  };
                },
              ),
      ),
    );
  }

  static List<_ReciterRow> _reciterRowEntries({
    required List<Reciter> filtered,
    required RecitationPickIntent intent,
    required int? selectedReciterId,
    required int? selectedMoshafId,
    required int? expandedId,
  }) {
    final rows = <_ReciterRow>[];
    for (final reciter in filtered) {
      final allMoshafs = reciter.moshaf;
      if (allMoshafs.isEmpty) continue;

      final ayahIntent = intent == RecitationPickIntent.ayahLevel;
      final selectableMoshafs = ayahIntent
          ? allMoshafs.where((m) => m.hasTiming).toList()
          : allMoshafs;
      if (ayahIntent && selectableMoshafs.isEmpty) continue;

      final single = selectableMoshafs.length == 1;
      final isApplied = selectedReciterId == reciter.id;
      final expanded = !single && (expandedId == reciter.id || isApplied);

      rows.add(
        _ReciterRow.header(
          reciter: reciter,
          single: single,
          isApplied: isApplied,
          expanded: expanded,
          allMoshafs: allMoshafs,
          selectableMoshaf: single ? selectableMoshafs.first : null,
        ),
      );

      if (expanded) {
        for (final m in allMoshafs) {
          rows.add(
            _ReciterRow.moshaf(
              reciter: reciter,
              moshaf: m,
              selectable: !ayahIntent || m.hasTiming,
              appliedMoshaf: isApplied && selectedMoshafId == m.id,
            ),
          );
        }
      }
    }
    return rows;
  }

  static Set<T> _toggle<T>(Set<T> set, T value) {
    final next = {...set};
    if (!next.remove(value)) next.add(value);
    return next;
  }

  Widget? _reciterSuffix({
    required FThemeData theme,
    required bool single,
    required bool isApplied,
    required bool expanded,
  }) {
    final children = <Widget>[
      if (single && isApplied)
        _SelectedMark(theme: theme)
      else if (!single)
        Icon(
          expanded ? FLucideIcons.chevronUp : FLucideIcons.chevronDown,
          size: 16,
          color: theme.colors.mutedForeground,
        ),
    ];
    if (children.isEmpty) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: children,
    );
  }
}

class _ReciterFilterChips extends StatelessWidget {
  const _ReciterFilterChips({
    required this.downloadedFilter,
    required this.styleFilter,
    required this.riwayahFilter,
    required this.riwayahOptions,
    this.stackVertically = false,
  });

  final ValueNotifier<bool> downloadedFilter;
  final ValueNotifier<Set<RecitationStyle>> styleFilter;
  final ValueNotifier<Set<String>> riwayahFilter;
  final List<String> riwayahOptions;
  final bool stackVertically;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = <Widget>[
      _FilterChip(
        label: l10n.quranReciterFilterDownloaded,
        active: downloadedFilter.value,
        onPress: () => downloadedFilter.value = !downloadedFilter.value,
      ),
      _FilterChip(
        label: l10n.quranReciterStyleMurattal,
        active: styleFilter.value.contains(RecitationStyle.murattal),
        onPress: () => styleFilter.value = _ReciterDialog._toggle(
          styleFilter.value,
          RecitationStyle.murattal,
        ),
      ),
      _FilterChip(
        label: l10n.quranReciterStyleMujawwad,
        active: styleFilter.value.contains(RecitationStyle.mujawwad),
        onPress: () => styleFilter.value = _ReciterDialog._toggle(
          styleFilter.value,
          RecitationStyle.mujawwad,
        ),
      ),
      for (final riwayah in riwayahOptions)
        _FilterChip(
          label: riwayah,
          active: riwayahFilter.value.contains(riwayah),
          onPress: () => riwayahFilter.value = _ReciterDialog._toggle(
            riwayahFilter.value,
            riwayah,
          ),
        ),
    ];

    if (stackVertically) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, chip) in chips.indexed)
            Padding(
              padding: EdgeInsets.only(
                bottom: index < chips.length - 1 ? AppSpacing.xs : 0,
              ),
              child: chip,
            ),
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark({required this.theme});

  final FThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: theme.colors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        FLucideIcons.check,
        size: 13,
        color: theme.colors.primaryForeground,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onPress,
  });

  final String label;
  final bool active;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return FButton(
      variant: active ? FButtonVariant.primary : FButtonVariant.outline,
      size: FButtonSizeVariant.sm,
      mainAxisSize: MainAxisSize.min,
      onPress: onPress,
      child: Text(label),
    );
  }
}
