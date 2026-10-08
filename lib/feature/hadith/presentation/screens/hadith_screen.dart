import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_interaction.dart';

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/layout/persisted_horizontal_split_pane.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_desk_layout.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_form.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_desk_breadcrumbs.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_results_column.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_search_column.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_topics.dart';

class HadithPage extends ConsumerStatefulWidget {
  const HadithPage({super.key});
  @override
  ConsumerState<HadithPage> createState() => _HadithPageState();
}

class _HadithPageState extends ConsumerState<HadithPage> {
  final _resultFocus = <String, FocusNode>{};
  final _mainKey = GlobalKey();
  FPersistentSheetController? _readerSheet;
  FPersistentSheetController? _filterSheet;
  Size? _readerSheetSize;
  TextDirection? _readerSheetDirection;
  bool _closingReader = false;
  bool _closingFilters = false;
  String? _rootKey;
  HadithReaderSelection? _previousSelection;

  Future<void> _hideReader() async {
    final sheet = _readerSheet;
    if (sheet == null || _closingReader) return;
    _closingReader = true;
    try {
      await sheet.hide().orCancel;
    } on TickerCanceled {
      return;
    } finally {
      if (identical(_readerSheet, sheet)) {
        _readerSheet = null;
        sheet.dispose();
      }
      _closingReader = false;
    }
  }

  Future<void> _hideFilters() async {
    final sheet = _filterSheet;
    if (sheet == null || _closingFilters) return;
    _closingFilters = true;
    try {
      await sheet.hide().orCancel;
    } on TickerCanceled {
      return;
    } finally {
      if (identical(_filterSheet, sheet)) {
        _filterSheet = null;
        sheet.dispose();
      }
      _closingFilters = false;
    }
  }

  void _closeReader() {
    ref.read(hadithSessionControllerProvider.notifier).clearSelection();
    unawaited(_hideReader());
  }

  Widget _reader() => _DeskReader(onClose: _closeReader);

  @override
  void dispose() {
    final reader = _readerSheet;
    _readerSheet = null;
    reader?.dispose();
    final filters = _filterSheet;
    _filterSheet = null;
    filters?.dispose();
    for (final node in _resultFocus.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
      hadithSessionControllerProvider.select(
        (s) => (
          s.context,
          s.target,
          s.reader?.selection,
          s.origin != null,
          s.query,
          s.searchPage?.isEmpty,
          s.filters.optionalPhrases,
        ),
      ),
    );
    ref.watch(hadithFilterInteractionProvider);
    final session = ref.read(hadithSessionControllerProvider);
    final settings =
        ref.watch(hadithScreenSettingsProvider).value ??
        HadithPersistedSettings.initial();
    final controller = ref.read(hadithSessionControllerProvider.notifier);
    final preferences = ref.read(hadithScreenSettingsProvider.notifier);
    final direction = Directionality.of(context);
    final root = session.readerTrail.firstOrNull?.selection;
    if (root != null) _rootKey = root.key;
    if (session.reader == null && _previousSelection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final node = _resultFocus[_rootKey];
        if (node?.context != null) {
          node!.requestFocus();
        } else {
          AppSearchFocusRegistry.instance.focus();
        }
      });
    }
    _previousSelection = session.reader?.selection;
    final landing =
        session.isSearchMode &&
        session.query.isEmpty &&
        session.searchPage?.isEmpty == true &&
        session.filters.optionalPhrases.every((p) => p.trim().isEmpty);
    return FSheets(
      child: Builder(
        builder: (sheetContext) => LayoutBuilder(
          builder: (context, constraints) {
            final policy = HadithDeskLayout.resolve(
              constraints.maxWidth - 32,
              (context.theme.typography.body.md.fontSize ?? 16) / 16,
            );
            final inlineFilters =
                session.supportsFilters &&
                policy.areas == 3 &&
                settings.filtersVisible;
            final inlineReader =
                session.reader != null &&
                !settings.readerCollapsed &&
                policy.areas >= 2;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if ((inlineFilters || !session.supportsFilters) &&
                  _filterSheet != null)
                unawaited(_hideFilters());
              if ((inlineReader || session.reader == null) &&
                  _readerSheet != null)
                unawaited(_hideReader());
              final sheetSize = Size(
                (constraints.maxWidth * .92).clamp(0, 520),
                constraints.maxHeight,
              );
              if (!inlineReader &&
                  _readerSheet != null &&
                  !_closingReader &&
                  (_readerSheetSize != sheetSize ||
                      _readerSheetDirection != direction)) {
                final old = _readerSheet!;
                _readerSheet = null;
                old.dispose();
              }
              if (session.reader != null &&
                  !inlineReader &&
                  _readerSheet == null &&
                  !_closingReader) {
                unawaited(_hideFilters());
                _readerSheetSize = sheetSize;
                _readerSheetDirection = direction;
                _readerSheet = showFPersistentSheet(
                  context: sheetContext,
                  side: direction == TextDirection.rtl
                      ? FLayout.ltr
                      : FLayout.rtl,
                  mainAxisMaxRatio: 1,
                  draggable: false,
                  constraints: BoxConstraints.tightFor(
                    width: sheetSize.width,
                    height: sheetSize.height,
                  ),
                  onClosing: () {
                    if (!_closingReader && mounted) _closeReader();
                  },
                  builder: (_, _) => _reader(),
                );
              }
            });
            void filters() {
              if (!session.supportsFilters) return;
              if (policy.areas == 3) {
                preferences.setFiltersVisible(!settings.filtersVisible);
                return;
              }
              if (_filterSheet != null) {
                unawaited(_hideFilters());
                return;
              }
              _filterSheet = showFPersistentSheet(
                context: sheetContext,
                side: direction == TextDirection.rtl
                    ? FLayout.rtl
                    : FLayout.ltr,
                mainAxisMaxRatio: 1,
                draggable: false,
                constraints: BoxConstraints.tightFor(
                  width: (constraints.maxWidth * .9).clamp(0, 340),
                  height: constraints.maxHeight,
                ),
                onClosing: () {
                  if (!_closingFilters) unawaited(_hideFilters());
                },
                builder: (_, _) => ColoredBox(
                  key: const ValueKey('hadith-filter-sheet-surface'),
                  color: context.theme.colors.background,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.escape): () =>
                            unawaited(_hideFilters()),
                      },
                      child: HadithFilterPanel(
                        onClose: () => unawaited(_hideFilters()),
                      ),
                    ),
                  ),
                ),
              );
            }

            final main = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _DeskNavigation(),
                const FDivider(),
                Expanded(
                  child: Padding(
                    key: _mainKey,
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 880),
                        child: landing
                            ? _Landing(onFilters: filters)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (session.isSearchMode)
                                    HadithSearchColumn(onFilters: filters),
                                  const SizedBox(height: 16),
                                  const HadithDeskBreadcrumbs(),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: HadithResultsColumn(
                                      focusNodes: _resultFocus,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
            Widget workspace = main;
            if (inlineReader)
              workspace = PersistedHorizontalSplitPane(
                key: const ValueKey('hadith-reader-split'),
                sidePanelRatio: settings.readerRatio,
                sideRegionIndex: direction == TextDirection.rtl ? 0 : 1,
                onSidePanelRatioChanged: preferences.setReaderRatio,
                resolve: ({required totalWidth, required sideWidth}) {
                  final extent = sideWidth
                      .clamp(
                        policy.readerMin,
                        totalWidth - policy.resultsMin - 1,
                      )
                      .toDouble();
                  return (
                    sideExtent: extent,
                    mainExtent: totalWidth - extent,
                    sideMin: policy.readerMin,
                    mainMin: policy.resultsMin,
                  );
                },
                mainPane: Directionality(textDirection: direction, child: main),
                sidePane: Directionality(
                  textDirection: direction,
                  child: _reader(),
                ),
              );
            if (inlineFilters)
              workspace = PersistedHorizontalSplitPane(
                key: const ValueKey('hadith-filter-split'),
                sidePanelRatio: settings.filtersWidth / constraints.maxWidth,
                sideRegionIndex: direction == TextDirection.rtl ? 1 : 0,
                onSidePanelRatioChanged: (ratio) =>
                    preferences.setFiltersWidth(ratio * constraints.maxWidth),
                resolve: ({required totalWidth, required sideWidth}) {
                  final minMain =
                      policy.resultsMin +
                      (inlineReader ? policy.readerMin + 1 : 0);
                  final extent = sideWidth
                      .clamp(
                        policy.filtersMin,
                        (totalWidth - minMain - 1).clamp(
                          policy.filtersMin,
                          policy.filtersMin.clamp(340.0, double.infinity),
                        ),
                      )
                      .toDouble();
                  return (
                    sideExtent: extent,
                    mainExtent: totalWidth - extent,
                    sideMin: policy.filtersMin,
                    mainMin: minMain,
                  );
                },
                sidePane: Directionality(
                  textDirection: direction,
                  child: Padding(
                    key: const ValueKey('hadith-filter-column'),
                    padding: const EdgeInsets.all(16),
                    child: HadithFilterPanel(
                      onClose: () => preferences.setFiltersVisible(false),
                    ),
                  ),
                ),
                mainPane: Directionality(
                  textDirection: direction,
                  child: workspace,
                ),
              );
            return AppShortcutScope(
              shortcuts: {
                if (session.supportsFilters) AppShortcut.hadithFilters,
                AppShortcut.hadithFocusSearch,
              },
              handlers: {
                if (session.supportsFilters) AppShortcut.hadithFilters: filters,
                AppShortcut.hadithFocusSearch: () =>
                    AppSearchFocusRegistry.instance.focus(),
              },
              child: Focus(
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    if (_filterSheet != null) {
                      unawaited(_hideFilters());
                      return KeyEventResult.handled;
                    }
                    if (session.reader != null) {
                      controller.readerBack();
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: workspace,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DeskNavigation extends ConsumerWidget {
  const _DeskNavigation();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      hadithSessionControllerProvider.select(
        (s) => (s.context, s.origin != null),
      ),
    );
    final session = ref.read(hadithSessionControllerProvider);
    final controller = ref.read(hadithSessionControllerProvider.notifier);
    final l10n = context.l10n;
    final items = <(String, bool, VoidCallback, IconData)>[
      (
        l10n.hadithSearchAction,
        session.context is SearchCollection,
        () => controller.returnToSearch(),
        FLucideIcons.search,
      ),
      (
        l10n.hadithTopics,
        session.context is TopicsCollection ||
            session.context is CategoryCollection,
        controller.openTopics,
        FLucideIcons.library,
      ),
      (
        l10n.bookmarks,
        session.context is SavedCollection,
        () => controller.openBookmarks(),
        FLucideIcons.bookmark,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (_, constraints) => Row(
          children: [
            if (session.origin != null)
              FButton.icon(
                variant: .ghost,
                semanticsTooltip: l10n.hadithBackToSearch,
                onPress: controller.returnToWorkspace,
                child: const Icon(FLucideIcons.undo2, size: 18),
              ),
            if (constraints.maxWidth < 480)
              Expanded(
                child: FPopoverMenu(
                  menuBuilder: (_, popover, _) => [
                    FItemGroup(
                      children: [
                        for (final item in items)
                          FItem(
                            prefix: Icon(item.$4, size: 16),
                            title: Text(item.$1),
                            onPress: () {
                              popover.hide();
                              item.$3();
                            },
                          ),
                      ],
                    ),
                  ],
                  builder: (_, popover, _) {
                    final current = items.firstWhere((item) => item.$2);
                    return FButton(
                      variant: .ghost,
                      prefix: Icon(current.$4, size: 16),
                      suffix: const Icon(FLucideIcons.chevronDown, size: 14),
                      onPress: popover.toggle,
                      child: Text(current.$1),
                    );
                  },
                ),
              )
            else
              for (final item in items)
                FButton(
                  variant: item.$2 ? .secondary : .ghost,
                  size: .sm,
                  mainAxisSize: MainAxisSize.min,
                  prefix: Icon(item.$4, size: 16),
                  onPress: item.$3,
                  child: Text(item.$1),
                ),
          ],
        ),
      ),
    );
  }
}

class _DeskReader extends ConsumerWidget {
  const _DeskReader({required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(
      hadithSessionControllerProvider.select((s) => s.reader?.selection),
    );
    final record = ref.watch(selectedHadithProvider);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            ref.read(hadithSessionControllerProvider.notifier).readerBack(),
      },
      child: ColoredBox(
        color: context.theme.colors.card,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HadithDeskBreadcrumbs(reader: true),
              const SizedBox(height: 10),
              Expanded(
                child: selection is ProseSelection
                    ? HadithProseDetailsPane(
                        key: ValueKey(selection.key),
                        id: selection.id,
                        onClose: onClose,
                      )
                    : record == null
                    ? const SizedBox.shrink()
                    : HadithSelectedDetailsPane(
                        key: ValueKey(selection!.key),
                        hadith: record,
                        onClose: onClose,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Landing extends StatelessWidget {
  const _Landing({required this.onFilters});
  final VoidCallback onFilters;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.hadithStudyDesk,
                style: context.theme.typography.body.xl.copyWith(
                  fontSize:
                      (context.theme.typography.body.xl.fontSize ?? 20) * 1.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.hadithStudyDeskHint,
                style: context.theme.typography.body.md.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 28),
              HadithSearchColumn(onFilters: onFilters),
              const SizedBox(height: 38),
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth >= 720
                    ? const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: HadithTopics()),
                          SizedBox(width: 34),
                          Expanded(flex: 2, child: HadithRecentQueries()),
                        ],
                      )
                    : const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 28,
                        children: [HadithTopics(), HadithRecentQueries()],
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
