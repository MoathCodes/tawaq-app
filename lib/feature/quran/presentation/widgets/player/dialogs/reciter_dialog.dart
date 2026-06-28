import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_pick_intent.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/reciter_tags.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog_filters.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog_sections.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/timed_riwayat_suggestions.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

export 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/timed_riwayat_suggestions.dart'
    show ReciterPick;

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

    final visibleReciterList = useMemoized(
      () => visibleReciters(filtered: filtered, intent: intent),
      [filtered, intent],
    );

    final initialFocusId = useMemoized(() {
      if (selectedReciterId == null) return null;
      final selected = visibleReciterList
          .where((r) => r.id == selectedReciterId)
          .firstOrNull;
      if (selected == null) return null;
      return selectableMoshafs(selected, intent).length > 1
          ? selected.id
          : null;
    }, [visibleReciterList, selectedReciterId, intent]);

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
            ? r.resolveMoshaf(m.id, intent: intent)
            : m;
        if (resolved == null) return;

        if (resolved.id != m.id && context.mounted) {
          final riwayahName =
              moshafTags(resolved.name).riwayah ?? resolved.name;
          showFToast(
            context: context,
            icon: const Icon(FLucideIcons.info),
            title: Text(l10n.quranReciterRiwayahUpgraded(riwayahName)),
          );
        }

        final currentSettings = ref.read(recitationSettingsProvider).value;
        final playback = ref.read(recitationControllerProvider);
        if (currentSettings?.reciterId == r.id &&
            currentSettings?.moshafId == resolved.id &&
            playback.surah != null) {
          if (context.mounted) Navigator.of(context).pop();
          return;
        }

        await ref
            .read(recitationControllerProvider.notifier)
            .switchReciter(r, resolved);

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
      final selectable = selectableMoshafs(reciter, intent);
      if (selectable.length == 1) {
        onPick(reciter, selectable.first);
        return;
      }
      focusedReciterId.value = reciter.id;
    }

    final focusedReciter = focusedReciterId.value == null
        ? null
        : visibleReciterList
              .where((r) => r.id == focusedReciterId.value)
              .firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        0,
        0,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlayerDialogHeader(
            title: l10n.quranReciterRiwayahTitle,
            headerBottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        child: const Icon(
                          FLucideIcons.slidersHorizontal,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                if (filtersOpen.value) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ReciterDialogFilterBar(
                    downloadedFilter: downloadedFilter,
                    styleFilter: styleFilter,
                    riwayahFilter: riwayahFilter,
                    riwayahOptions: riwayahOptions,
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: colors.border),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: recitersAsync.isLoading && reciters.isEmpty
                ? const Center(child: FCircularProgress())
                : visibleReciterList.isEmpty
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
                              child: ReciterDialogListPane(
                                reciters: visibleReciterList,
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
                              child: ReciterDialogRiwayahPane(
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

                      return ReciterDialogListPane(
                        reciters: visibleReciterList,
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
