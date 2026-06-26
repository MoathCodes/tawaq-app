import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/centered_viewport_shell.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/scroll_overflow_hint_viewport.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_pick_intent.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/reciter_tags.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Stable identity for a reciter + moshaf pair in [FSelectTileGroup].
@immutable
class _ReciterMoshafKey {
  const _ReciterMoshafKey(this.reciterId, this.moshafId);

  final int reciterId;
  final int moshafId;

  @override
  bool operator ==(Object other) =>
      other is _ReciterMoshafKey &&
      other.reciterId == reciterId &&
      other.moshafId == moshafId;

  @override
  int get hashCode => Object.hash(reciterId, moshafId);
}

/// The reciter/riwayah a user picked.
typedef ReciterPick = ({Reciter reciter, Moshaf moshaf});

/// Opens the reciter & riwayah picker.
Future<ReciterPick?> showReciterDialog(
  BuildContext context, {
  RecitationPickIntent intent = RecitationPickIntent.general,
  bool pickOnly = false,
}) => showFDialog<ReciterPick>(
  context: context,
  useRootNavigator: true,
  builder: (context, style, animation) => FDialog.raw(
    style: style,
    animation: animation,
    constraints: dialogConstraints(
      context,
      preferredWidth: 840,
      preferredHeight: 520,
      minWidth: 360,
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context, _) => _ReciterDialog(
      intent: intent,
      pickOnly: pickOnly,
    ),
  ),
);

const _reciterTileStyle = FItemStyleDelta.delta(
  contentStyle: .delta(
    titleSpacing: 2,
    suffixedPadding: .value(
      EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
    prefixIconSpacing: AppSpacing.sm,
  ),
);

const _riwayahTileStyle = FItemStyleDelta.delta(
  contentStyle: .delta(
    titleSpacing: 2,
    suffixedPadding: .value(
      EdgeInsetsDirectional.only(
        start: AppSpacing.xl,
        end: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
    ),
    prefixIconSpacing: AppSpacing.sm,
  ),
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

    final visibleReciters = useMemoized(
      () => _visibleReciters(filtered: filtered, intent: intent),
      [filtered, intent],
    );

    final initialFocusId = useMemoized(() {
      if (selectedReciterId == null) return null;
      final selected = visibleReciters
          .where((r) => r.id == selectedReciterId)
          .firstOrNull;
      if (selected == null) return null;
      return _selectableMoshafs(selected, intent).length > 1
          ? selected.id
          : null;
    }, [visibleReciters, selectedReciterId, intent]);

    final focusedReciterId = useState<int?>(initialFocusId);
    final applyingReciterId = useState<int?>(null);

    final activeFilterCount = [
      if (downloadedFilter.value) 1,
      styleFilter.value.length,
      riwayahFilter.value.length,
    ].fold<int>(0, (sum, n) => sum + n);

    Future<void> apply(Reciter r, Moshaf m) async {
      applyingReciterId.value = r.id;
      try {
        final resolved = intent == RecitationPickIntent.ayahLevel
            ? r.resolveMoshafForIntent(m.id, intent)
            : m;
        if (resolved == null) return;

        // Show a toast when the moshaf was auto-upgraded to a timed variant.
        if (resolved.id != m.id && context.mounted) {
          final riwayahName =
              moshafTags(resolved.name).riwayah ?? resolved.name;
          showFToast(
            context: context,
            icon: const Icon(FLucideIcons.info),
            title: Text(l10n.quranReciterRiwayahUpgraded(riwayahName)),
          );
        }

        // Skip if same reciter/moshaf already selected — just close.
        final currentSettings = ref.read(recitationSettingsProvider).value;
        final playback = ref.read(recitationControllerProvider);
        if (currentSettings?.reciterId == r.id &&
            currentSettings?.moshafId == resolved.id &&
            playback.surah != null) {
          if (context.mounted) Navigator.of(context).pop();
          return;
        }

        ref
            .read(recitationSettingsProvider.notifier)
            .setReciter(
              reciterId: r.id,
              moshafId: resolved.id,
            );

        // Just save the selection — playback starts when user presses play.
        ref.read(recitationControllerProvider.notifier).setReciter(r, resolved);

        if (pickOnly) {
          if (!context.mounted) return;
          Navigator.of(context).pop((reciter: r, moshaf: resolved));
          return;
        }

        if (context.mounted) Navigator.of(context).pop();
      } finally {
        applyingReciterId.value = null;
      }
    }

    void onPick(Reciter reciter, Moshaf moshaf) {
      unawaited(apply(reciter, moshaf));
    }

    void onReciterPress(Reciter reciter) {
      if (reciter.id == focusedReciterId.value) {
        focusedReciterId.value = null;
        return;
      }
      final selectable = _selectableMoshafs(reciter, intent);
      if (selectable.length == 1) {
        onPick(reciter, selectable.first);
        return;
      }
      focusedReciterId.value = reciter.id;
    }

    final focusedReciter = focusedReciterId.value == null
        ? null
        : visibleReciters
              .where((r) => r.id == focusedReciterId.value)
              .firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.quranReciterRiwayahTitle,
                  style: theme.typography.body.lg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ),
              FButton.icon(
                variant: .ghost,
                onPress: () => Navigator.of(context).maybePop(),
                child: Icon(
                  FLucideIcons.x,
                  size: 18,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FTextField(
                  hint: l10n.quranReciterSearchHint,
                  control: FTextFieldControl.managed(
                    onChange: (value) => query.value = value.text,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FButton.icon(
                variant: filtersOpen.value || activeFilterCount > 0
                    ? FButtonVariant.primary
                    : FButtonVariant.outline,
                onPress: () => filtersOpen.value = !filtersOpen.value,
                child: Badge(
                  isLabelVisible: activeFilterCount > 0,
                  label: Text('$activeFilterCount'),
                  backgroundColor: theme.colors.background,
                  offset: const Offset(-12, -12),
                  child: const Icon(FLucideIcons.slidersHorizontal, size: 16),
                ),
              ),
            ],
          ),
          if (filtersOpen.value) ...[
            const SizedBox(height: AppSpacing.sm),
            _ReciterFilterBar(
              downloadedFilter: downloadedFilter,
              styleFilter: styleFilter,
              riwayahFilter: riwayahFilter,
              riwayahOptions: riwayahOptions,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: colors.border),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: recitersAsync.isLoading && reciters.isEmpty
                ? const Center(child: FCircularProgress())
                : visibleReciters.isEmpty
                ? Center(
                    child: Text(
                      l10n.quranNoMatchingReciters,
                      textAlign: TextAlign.center,
                      style: theme.typography.body.sm.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final useSplit = isContainerAtLeast(
                        context,
                        constraints,
                        FBreakpoint.md,
                      );

                      if (useSplit) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 11,
                              child: _ReciterListPane(
                                reciters: visibleReciters,
                                intent: intent,
                                selectedReciterId: selectedReciterId,
                                selectedMoshafId: selectedMoshafId,
                                focusedReciterId: focusedReciterId.value,
                                downloadedKeys: downloadedKeys,
                                onReciterPress: onReciterPress,
                                applyingReciterId: applyingReciterId.value,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: Container(
                                width: 1,
                                color: colors.border.withValues(alpha: 0.65),
                              ),
                            ),
                            Expanded(
                              flex: 9,
                              child: _RiwayahDetailPane(
                                reciter: focusedReciter,
                                intent: intent,
                                selectedReciterId: selectedReciterId,
                                selectedMoshafId: selectedMoshafId,
                                downloadedKeys: downloadedKeys,
                                onPick: onPick,
                              ),
                            ),
                          ],
                        );
                      }

                      return _ReciterListPane(
                        reciters: visibleReciters,
                        intent: intent,
                        selectedReciterId: selectedReciterId,
                        selectedMoshafId: selectedMoshafId,
                        focusedReciterId: focusedReciterId.value,
                        downloadedKeys: downloadedKeys,
                        onReciterPress: onReciterPress,
                        inlineRiwayahFor: focusedReciter,
                        onPick: onPick,
                        applyingReciterId: applyingReciterId.value,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

List<Reciter> _visibleReciters({
  required List<Reciter> filtered,
  required RecitationPickIntent intent,
}) {
  final visible = <Reciter>[];
  for (final reciter in filtered) {
    if (_selectableMoshafs(reciter, intent).isEmpty) continue;
    visible.add(reciter);
  }
  return visible;
}

List<Moshaf> _selectableMoshafs(Reciter reciter, RecitationPickIntent intent) {
  if (intent == RecitationPickIntent.ayahLevel) {
    return reciter.moshaf.where((m) => m.hasTiming).toList();
  }
  return reciter.moshaf;
}

sealed class _ReciterListEntry {
  const _ReciterListEntry();
}

final class _ReciterRowEntry extends _ReciterListEntry {
  const _ReciterRowEntry(this.reciter);

  final Reciter reciter;
}

final class _InlineMoshafEntry extends _ReciterListEntry {
  const _InlineMoshafEntry(this.reciter, this.moshaf);

  final Reciter reciter;
  final Moshaf moshaf;
}

List<_ReciterListEntry> _reciterListEntries({
  required List<Reciter> reciters,
  required RecitationPickIntent intent,
  Reciter? inlineRiwayahFor,
}) {
  final entries = <_ReciterListEntry>[];
  for (final reciter in reciters) {
    entries.add(_ReciterRowEntry(reciter));
    if (inlineRiwayahFor?.id == reciter.id) {
      final selectable = _selectableMoshafs(reciter, intent);
      if (selectable.length > 1) {
        for (final moshaf in selectable) {
          entries.add(_InlineMoshafEntry(reciter, moshaf));
        }
      }
    }
  }
  return entries;
}

class _ReciterListPane extends StatelessWidget {
  const _ReciterListPane({
    required this.reciters,
    required this.intent,
    required this.selectedReciterId,
    required this.selectedMoshafId,
    required this.focusedReciterId,
    required this.downloadedKeys,
    required this.onReciterPress,
    this.inlineRiwayahFor,
    this.onPick,
    this.applyingReciterId,
  });

  final List<Reciter> reciters;
  final RecitationPickIntent intent;
  final int? selectedReciterId;
  final int? selectedMoshafId;
  final int? focusedReciterId;
  final Set<(int, int)> downloadedKeys;
  final ValueChanged<Reciter> onReciterPress;
  final Reciter? inlineRiwayahFor;
  final void Function(Reciter reciter, Moshaf moshaf)? onPick;
  final int? applyingReciterId;

  @override
  Widget build(BuildContext context) {
    final entries = _reciterListEntries(
      reciters: reciters,
      intent: intent,
      inlineRiwayahFor: inlineRiwayahFor,
    );

    return FTileGroup.builder(
      divider: FItemDivider.full,
      tileBuilder: (context, index) {
        if (index >= entries.length) return null;

        return switch (entries[index]) {
          _ReciterRowEntry(:final reciter) => _buildReciterTile(
            context,
            reciter: reciter,
            intent: intent,
            selectedReciterId: selectedReciterId,
            selectedMoshafId: selectedMoshafId,
            focusedReciterId: focusedReciterId,
            downloadedKeys: downloadedKeys,
            onReciterPress: onReciterPress,
            applying: applyingReciterId == reciter.id,
          ),
          _InlineMoshafEntry(:final reciter, :final moshaf) =>
            _buildInlineMoshafTile(
              context,
              reciter: reciter,
              moshaf: moshaf,
              intent: intent,
              selectedReciterId: selectedReciterId,
              selectedMoshafId: selectedMoshafId,
              downloadedKeys: downloadedKeys,
              onPick: onPick!,
            ),
        };
      },
      count: entries.length,
    );
  }
}

FTile _buildReciterTile(
  BuildContext context, {
  required Reciter reciter,
  required RecitationPickIntent intent,
  required int? selectedReciterId,
  required int? selectedMoshafId,
  required int? focusedReciterId,
  required Set<(int, int)> downloadedKeys,
  required ValueChanged<Reciter> onReciterPress,
  bool applying = false,
}) {
  final l10n = context.l10n;
  final colors = context.theme.colors;
  final selectable = _selectableMoshafs(reciter, intent);
  final isApplied = selectedReciterId == reciter.id;
  final isFocused = focusedReciterId == reciter.id;
  final activeMoshaf = isApplied && selectedMoshafId != null
      ? reciter.moshaf.where((m) => m.id == selectedMoshafId).firstOrNull
      : null;
  final multi = selectable.length > 1;

  return FTile(
    style: _reciterTileStyle,
    prefix: Icon(
      FLucideIcons.mic,
      size: 17,
      color: isApplied || isFocused ? colors.primary : colors.mutedForeground,
    ),
    title: Text(
      reciter.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      activeMoshaf != null
          ? _moshafPrimaryLabel(activeMoshaf, l10n)
          : multi
          ? l10n.quranReciterRiwayahCount(selectable.length)
          : _moshafPrimaryLabel(selectable.first, l10n),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    details: _ReciterHeaderMeta(
      reciter: reciter,
      downloadedKeys: downloadedKeys,
    ),
    suffix: applying
        ? const SizedBox(
            width: 16,
            height: 16,
            child: FCircularProgress(size: FCircularProgressSizeVariant.sm),
          )
        : multi
        ? Icon(
            isFocused ? FLucideIcons.chevronDown : FLucideIcons.chevronLeft,
            size: 16,
            color: colors.mutedForeground,
          )
        : (isApplied
              ? Icon(FLucideIcons.check, size: 16, color: colors.primary)
              : null),
    selected: isApplied || isFocused,
    onPress: () => onReciterPress(reciter),
  );
}

FTile _buildInlineMoshafTile(
  BuildContext context, {
  required Reciter reciter,
  required Moshaf moshaf,
  required RecitationPickIntent intent,
  required int? selectedReciterId,
  required int? selectedMoshafId,
  required Set<(int, int)> downloadedKeys,
  required void Function(Reciter reciter, Moshaf moshaf) onPick,
}) {
  final l10n = context.l10n;
  final colors = context.theme.colors;
  final ayahIntent = intent == RecitationPickIntent.ayahLevel;
  final selectable = !ayahIntent || moshaf.hasTiming;
  final isApplied =
      selectedReciterId == reciter.id && selectedMoshafId == moshaf.id;
  final tags = moshafTags(moshaf.name);
  final primary = _moshafPrimaryLabel(moshaf, l10n);
  final subtitle = selectable
      ? _moshafSubtitle(moshaf: moshaf, tags: tags, l10n: l10n)
      : l10n.quranReciterSurahOnly;

  return FTile(
    style: _riwayahTileStyle,
    enabled: selectable,
    prefix: _MoshafPrefix(style: tags.style),
    title: Text(primary, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: subtitle == null ? null : Text(subtitle),
    details: _MoshafMetaRow(
      moshaf: moshaf,
      downloaded: downloadedKeys.contains((reciter.id, moshaf.id)),
    ),
    suffix: isApplied
        ? Icon(FLucideIcons.check, size: 16, color: colors.primary)
        : null,
    selected: isApplied,
    onPress: selectable ? () => onPick(reciter, moshaf) : null,
  );
}

class _RiwayahDetailPane extends StatelessWidget {
  const _RiwayahDetailPane({
    required this.reciter,
    required this.intent,
    required this.selectedReciterId,
    required this.selectedMoshafId,
    required this.downloadedKeys,
    required this.onPick,
  });

  final Reciter? reciter;
  final RecitationPickIntent intent;
  final int? selectedReciterId;
  final int? selectedMoshafId;
  final Set<(int, int)> downloadedKeys;
  final void Function(Reciter reciter, Moshaf moshaf) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colors = theme.colors;

    if (reciter == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            l10n.quranSelectReciter,
            textAlign: TextAlign.center,
            style: theme.typography.body.sm.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ),
      );
    }

    final selectable = _selectableMoshafs(reciter!, intent);
    if (selectable.length <= 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            l10n.quranReciterRiwayahCount(selectable.length),
            textAlign: TextAlign.center,
            style: theme.typography.body.sm.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ),
      );
    }

    return _MoshafSelectGroup(
      reciter: reciter!,
      intent: intent,
      tileStyle: _reciterTileStyle,
      selectedReciterId: selectedReciterId,
      selectedMoshafId: selectedMoshafId,
      downloadedKeys: downloadedKeys,
      onPick: onPick,
      label: Text(
        reciter!.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.typography.body.sm.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.foreground,
        ),
      ),
    );
  }
}

class _MoshafSelectGroup extends StatelessWidget {
  const _MoshafSelectGroup({
    required this.reciter,
    required this.intent,
    required this.tileStyle,
    required this.selectedReciterId,
    required this.selectedMoshafId,
    required this.downloadedKeys,
    required this.onPick,
    this.label,
  });

  final Reciter reciter;
  final RecitationPickIntent intent;
  final FItemStyleDelta tileStyle;
  final int? selectedReciterId;
  final int? selectedMoshafId;
  final Set<(int, int)> downloadedKeys;
  final void Function(Reciter reciter, Moshaf moshaf) onPick;
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.theme.colors;
    final ayahIntent = intent == RecitationPickIntent.ayahLevel;
    final selectable = _selectableMoshafs(reciter, intent);
    final initial = selectedReciterId == reciter.id && selectedMoshafId != null
        ? _ReciterMoshafKey(reciter.id, selectedMoshafId!)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) => ScrollOverflowHintViewport(
        builder: (controller) => centeredViewportScrollTab(
          controller: controller,
          maxContentWidth: constraints.maxWidth,
          child: FSelectTileGroup<_ReciterMoshafKey>(
            key: ValueKey('Tile-Group-Riwayat${reciter.id}'),
            divider: FItemDivider.full,
            label: label,
            control: FMultiValueControl.managedRadio(
              initial: initial,
              onChange: (selected) {
                final key = selected.firstOrNull;
                if (key == null) return;
                final moshaf = reciter.moshaf.firstWhere(
                  (m) => m.id == key.moshafId,
                );
                onPick(reciter, moshaf);
              },
            ),
            children: [
              for (final moshaf in selectable)
                _buildMoshafTile(
                  reciter: reciter,
                  moshaf: moshaf,
                  ayahIntent: ayahIntent,
                  downloadedKeys: downloadedKeys,
                  l10n: l10n,
                  colors: colors,
                  tileStyle: tileStyle,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static FSelectTile<_ReciterMoshafKey> _buildMoshafTile({
    required Reciter reciter,
    required Moshaf moshaf,
    required bool ayahIntent,
    required Set<(int, int)> downloadedKeys,
    required AppLocalizations l10n,
    required FColors colors,
    required FItemStyleDelta tileStyle,
  }) {
    final selectable = !ayahIntent || moshaf.hasTiming;
    final tags = moshafTags(moshaf.name);
    final primary = _moshafPrimaryLabel(moshaf, l10n);
    final subtitle = selectable
        ? _moshafSubtitle(moshaf: moshaf, tags: tags, l10n: l10n)
        : l10n.quranReciterSurahOnly;

    return FSelectTile.suffix(
      style: tileStyle,
      value: _ReciterMoshafKey(reciter.id, moshaf.id),
      enabled: selectable,
      checkedIcon: Icon(FLucideIcons.check, size: 16, color: colors.primary),
      uncheckedIcon: const Icon(
        FLucideIcons.check,
        size: 16,
        color: Colors.transparent,
      ),
      prefix: _MoshafPrefix(style: tags.style),
      title: Text(primary, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null ? null : Text(subtitle),
      details: _MoshafMetaRow(
        moshaf: moshaf,
        downloaded: downloadedKeys.contains((reciter.id, moshaf.id)),
      ),
    );
  }
}

class _ReciterHeaderMeta extends StatelessWidget {
  const _ReciterHeaderMeta({
    required this.reciter,
    required this.downloadedKeys,
  });

  final Reciter reciter;
  final Set<(int, int)> downloadedKeys;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.theme.colors.mutedForeground;
    final downloaded = reciter.moshaf.any(
      (m) => downloadedKeys.contains((reciter.id, m.id)),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        if (reciter.hasTiming)
          _ReciterMetaIcon(
            message: l10n.quranReciterTimed,
            icon: FLucideIcons.audioLines,
            color: muted,
          ),
        if (downloaded)
          _ReciterMetaIcon(
            message: l10n.quranReciterFilterDownloaded,
            icon: FLucideIcons.download,
            color: muted,
          ),
      ],
    );
  }
}

class _ReciterMetaIcon extends StatelessWidget {
  const _ReciterMetaIcon({
    required this.message,
    required this.icon,
    required this.color,
    this.size = 13,
  });

  final String message;
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FTooltip(
      tipBuilder: (_, _) => Text(message),
      child: Semantics(
        label: message,
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

class _MoshafPrefix extends StatelessWidget {
  const _MoshafPrefix({required this.style});

  final RecitationStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final (icon, tint) = switch (style) {
      RecitationStyle.mujawwad => (FLucideIcons.sparkles, colors.primary),
      RecitationStyle.murattal => (
        FLucideIcons.audioLines,
        colors.mutedForeground,
      ),
      null => (FLucideIcons.bookOpen, colors.mutedForeground),
    };

    return Icon(icon, size: 16, color: tint);
  }
}

class _MoshafMetaRow extends StatelessWidget {
  const _MoshafMetaRow({
    required this.moshaf,
    required this.downloaded,
  });

  final Moshaf moshaf;
  final bool downloaded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.theme.colors.mutedForeground;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        if (moshaf.hasTiming)
          _ReciterMetaIcon(
            message: l10n.quranReciterTimed,
            icon: FLucideIcons.audioLines,
            color: muted,
            size: 12,
          ),
        if (downloaded)
          _ReciterMetaIcon(
            message: l10n.quranReciterFilterDownloaded,
            icon: FLucideIcons.hardDriveDownload,
            color: muted,
            size: 12,
          ),
      ],
    );
  }
}

String _moshafPrimaryLabel(Moshaf moshaf, AppLocalizations l10n) {
  final tags = moshafTags(moshaf.name);
  final parts = <String>[];
  if (tags.riwayah != null) parts.add(tags.riwayah!);
  if (tags.style != null) {
    parts.add(
      switch (tags.style!) {
        RecitationStyle.murattal => l10n.quranReciterStyleMurattal,
        RecitationStyle.mujawwad => l10n.quranReciterStyleMujawwad,
      },
    );
  }
  return parts.isNotEmpty ? parts.join(' · ') : moshaf.name;
}

String? _moshafSubtitle({
  required Moshaf moshaf,
  required ({RecitationStyle? style, String? riwayah}) tags,
  required AppLocalizations l10n,
}) {
  final primary = _moshafPrimaryLabel(moshaf, l10n);
  if (primary != moshaf.name) return moshaf.name;
  return null;
}

class _ReciterFilterBar extends StatelessWidget {
  const _ReciterFilterBar({
    required this.downloadedFilter,
    required this.styleFilter,
    required this.riwayahFilter,
    required this.riwayahOptions,
  });

  final ValueNotifier<bool> downloadedFilter;
  final ValueNotifier<Set<RecitationStyle>> styleFilter;
  final ValueNotifier<Set<String>> riwayahFilter;
  final List<String> riwayahOptions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FilterChip(
          label: l10n.quranReciterFilterDownloaded,
          active: downloadedFilter.value,
          onPress: () => downloadedFilter.value = !downloadedFilter.value,
        ),
        _FilterChip(
          label: l10n.quranReciterStyleMurattal,
          active: styleFilter.value.contains(RecitationStyle.murattal),
          onPress: () => styleFilter.value = _toggle(
            styleFilter.value,
            RecitationStyle.murattal,
          ),
        ),
        _FilterChip(
          label: l10n.quranReciterStyleMujawwad,
          active: styleFilter.value.contains(RecitationStyle.mujawwad),
          onPress: () => styleFilter.value = _toggle(
            styleFilter.value,
            RecitationStyle.mujawwad,
          ),
        ),
        for (final riwayah in riwayahOptions)
          _FilterChip(
            label: riwayah,
            active: riwayahFilter.value.contains(riwayah),
            onPress: () =>
                riwayahFilter.value = _toggle(riwayahFilter.value, riwayah),
          ),
      ],
    );
  }

  static Set<T> _toggle<T>(Set<T> set, T value) {
    final next = {...set};
    if (!next.remove(value)) next.add(value);
    return next;
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
  final VoidCallback onPress;

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
