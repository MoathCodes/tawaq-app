import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart' show TickerCanceled;
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/utils/reduce_motion.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/controller/fortress_focus_session.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_dua_content.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_share_dialog.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_study_panel.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_text_spans.dart';
import 'package:tawaq/theme/theme.dart';

class FortressFocusReadingView extends ConsumerWidget {
  const FortressFocusReadingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(fortressSelectedCategoryProvider);
    if (category == null) return const SizedBox.shrink();
    final state = ref.watch(fortressScreenControllerProvider);
    final exit = ref
        .read(fortressScreenControllerProvider.notifier)
        .exitFocusMode;
    return ref
        .watch(fortressRepositoryProvider)
        .when(
          data: (repository) => FortressFocusReadingSurface(
            key: ValueKey((category.chapterId, state.focusStartIndex)),
            category: category,
            duas: repository.loadDuas(category.chapterId),
            initialIndex: state.focusStartIndex,
            onExit: exit,
          ),
          loading: () =>
              Scaffold(body: Center(child: FCircularProgress.loader())),
          error: (_, _) => Scaffold(
            body: Column(
              children: [
                FButton(
                  variant: .ghost,
                  onPress: exit,
                  child: Text(context.l10n.fortressExitFocus),
                ),
                Expanded(
                  child: ErrorStatePanel(
                    message: context.l10n.fortressLoadError,
                    retryLabel: context.l10n.fortressRetry,
                    onRetry: () => ref.invalidate(fortressRepositoryProvider),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

/// The real reading surface, also usable with isolated content for native QA.
class FortressFocusReadingSurface extends StatefulWidget {
  const FortressFocusReadingSurface({
    required this.category,
    required this.duas,
    required this.onExit,
    this.initialIndex = 0,
    super.key,
  });
  final FortressCategory category;
  final List<FortressDuaItem> duas;
  final VoidCallback onExit;
  final int initialIndex;

  @override
  State<FortressFocusReadingSurface> createState() => _FocusState();
}

class _FocusState extends State<FortressFocusReadingSurface>
    with WidgetsBindingObserver {
  late final session = FortressFocusSession(
    widget.duas.map((dua) => dua.targetCount).toList(),
    initialIndex: widget.initialIndex,
  );
  final _bucket = PageStorageBucket();
  final _stageFocus = FocusNode();
  final _scroll = ScrollController();
  FPersistentSheetController? _sheet;
  final _sheetRevision = ValueNotifier(0);
  final _closingSheets = <FPersistentSheetController>{};
  FortressDetailKind? _detail;
  bool _expanded = false;
  bool _compact = false;
  bool _reserveSheet = false;
  Offset? _tapStart;
  int? _tapPointer;
  bool _tapMoved = false;
  DateTime? _tapTime;
  bool _sheetScheduled = false;
  bool _closing = false;
  int _visibleIndex = -1;
  double _dockWidth = 420;
  double _horizontalWheel = 0;
  DateTime? _lastWheel;
  Object? _stageMeasurementKey;
  TextStyle? _stageStyle;
  bool _stageShort = false;
  Widget? _stageContent;

  @override
  void initState() {
    super.initState();
    session.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  void _changed() {
    if (!mounted) return;
    if (_visibleIndex != session.index || session.ended) {
      _visibleIndex = session.index;
      if (_scroll.hasClients) _scroll.jumpTo(0);
      if (_detail != null) {
        final kinds = FortressDetailKind.available(widget.duas[session.index]);
        if (kinds.isEmpty || session.ended) {
          _detail = null;
          _hideSheet();
          // Restore reading focus after the sheet has closed.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _stageFocus.requestFocus();
          });
        } else if (!kinds.contains(_detail)) {
          _detail = kinds.first;
        }
      }
    }
    if (session.ended && _detail != null) {
      _detail = null;
      _expanded = false;
      _hideSheet();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _stageFocus.requestFocus();
      });
    }
    setState(() {});
    _sheetRevision.value++;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => session.pause(
    FortressFocusPause.inactive,
    state != AppLifecycleState.resumed,
  );

  void _hideSheet() {
    final sheet = _sheet;
    _sheet = null;
    if (sheet != null) {
      _closingSheets.add(sheet);
      unawaited(_finishClosingSheet(sheet));
    }
  }

  Future<void> _finishClosingSheet(FPersistentSheetController sheet) async {
    try {
      await sheet.hide().orCancel;
    } on TickerCanceled {
      // Removing the reader also cancels any sheet still closing.
    } finally {
      if (_closingSheets.remove(sheet)) sheet.dispose();
    }
  }

  void _disposeSheets() {
    _sheet?.dispose();
    _sheet = null;
    final closing = _closingSheets.toList();
    _closingSheets.clear();
    for (final sheet in closing) {
      sheet.dispose();
    }
  }

  void _closeDetails() {
    if (_closing) return;
    _closing = true;
    _hideSheet();
    setState(() {
      _detail = null;
      _expanded = false;
    });
    _stageFocus.requestFocus();
    _closing = false;
  }

  void _openDetails(FortressDetailKind kind) {
    if (_detail == kind) {
      _closeDetails();
      return;
    }
    setState(() => _detail = kind);
    _sheetRevision.value++;
  }

  void _syncSheet(BuildContext context) {
    if (_detail == null || session.ended) {
      _hideSheet();
      return;
    }
    if (_sheet != null || _sheetScheduled) return;
    _sheetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sheetScheduled = false;
      if (!mounted || _detail == null || session.ended) return;
      late final FPersistentSheetController created;
      created = showFPersistentSheet(
        context: context,
        side: Directionality.of(context) == TextDirection.rtl ? .ltr : .rtl,
        mainAxisMaxRatio: 1,
        draggable: false,
        useSafeArea: false,
        onClosing: () {
          if (_sheet == created) _closeDetails();
        },
        builder: (context, controller) => ValueListenableBuilder(
          valueListenable: _sheetRevision,
          builder: (_, _, _) => SizedBox(
            width: _expanded ? double.infinity : _dockWidth,
            height: double.infinity,
            child: _panel(compact: _compact),
          ),
        ),
      );
      _sheet = created;
    });
  }

  Widget _panel({bool compact = false}) => _detail == null
      ? const SizedBox.shrink()
      : CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _closeDetails,
          },
          child: Focus(
            autofocus: true,
            child: FortressStudyPanel(
              dua: widget.duas[session.index],
              itemNumber: session.index + 1,
              itemTotal: widget.duas.length,
              kind: _detail!,
              bucket: _bucket,
              paused: false,
              expanded: _expanded,
              onKindChanged: (kind) {
                setState(() => _detail = kind);
                _sheetRevision.value++;
              },
              onClose: _closeDetails,
              onExpand: () {
                setState(() => _expanded = !_expanded);
                _hideSheet();
              },
              onPrevious: compact && session.index > 0
                  ? session.previous
                  : null,
              onNext: compact ? session.next : null,
            ),
          ),
        );

  Future<void> _share({bool chapter = false}) async {
    session.pause(FortressFocusPause.share, true);
    try {
      await showFortressShareDialog(
        context,
        widget.duas[session.index],
        chapter: widget.duas,
        entireChapter: chapter,
      );
    } finally {
      if (mounted) session.pause(FortressFocusPause.share, false);
    }
  }

  void _count() {
    if (session.paused || session.ended || session.remaining == 0) return;
    session.count();
    unawaited(HapticFeedback.lightImpact());
  }

  void _exit() {
    _disposeSheets();
    session.pause(FortressFocusPause.inactive, true);
    widget.onExit();
  }

  @override
  void deactivate() {
    // FSheets is a child: cancel its tickers before children unmount.
    _disposeSheets();
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeSheets();
    _sheetRevision.dispose();
    session.dispose();
    _stageFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    if (widget.duas.isEmpty)
      return Scaffold(
        body: Column(
          children: [
            FButton(
              variant: .ghost,
              onPress: _exit,
              child: Text(l10n.fortressExitFocus),
            ),
            Expanded(
              child: EmptyStatePanel(
                icon: FLucideIcons.bookOpen,
                title: l10n.fortressNoAdhkarInChapter,
              ),
            ),
          ],
        ),
      );
    return Scaffold(
      backgroundColor: theme.colors.background,
      body: FSheets(
        child: Builder(
          builder: (sheetContext) => LayoutBuilder(
            builder: (context, constraints) {
              _compact =
                  constraints.maxWidth < 1040 ||
                  MediaQuery.textScalerOf(context).scale(18) > 27;
              final paneWidth = math.max(
                420.0,
                session.ended || widget.duas.isEmpty
                    ? 0.0
                    : FortressStudyPanel.minimumTabWidth(
                        context,
                        widget.duas[session.index],
                      ),
              );
              _reserveSheet =
                  constraints.maxWidth >= 720 &&
                  constraints.maxWidth - paneWidth >= 280;
              _dockWidth = _reserveSheet ? paneWidth : constraints.maxWidth;
              _syncSheet(sheetContext);
              final content = AnimatedPadding(
                duration: reduceMotion(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: EdgeInsetsDirectional.only(
                  end: _detail != null && _reserveSheet && !session.ended
                      ? _dockWidth
                      : 0,
                ),
                child: LayoutBuilder(
                  builder: (_, readerBox) => _reader(readerBox),
                ),
              );
              return CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () {
                    if (_detail != null) {
                      _closeDetails();
                    } else {
                      _exit();
                    }
                  },
                },
                child: Focus(
                  child: AppShortcutScope(
                    shortcuts: {
                      AppShortcut.fortressCount,
                      AppShortcut.fortressThikrNext,
                      AppShortcut.fortressThikrPrev,
                      AppShortcut.fortressUndo,
                    },
                    handlers: {
                      AppShortcut.fortressCount: _count,
                      AppShortcut.fortressThikrNext: session.next,
                      AppShortcut.fortressThikrPrev: session.previous,
                      AppShortcut.fortressUndo: session.undo,
                    },
                    shouldIgnore: () =>
                        session.paused ||
                        (!session.ended && !_stageFocus.hasPrimaryFocus),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        content,
                        if (_detail != null && !session.ended)
                          const Positioned.fill(
                            child: IgnorePointer(
                              child: ColoredBox(
                                key: ValueKey('fortress-focus-backdrop'),
                                color: Color(0x14000000),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _completion(BoxConstraints constraints) {
    final theme = context.theme;
    final l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Row(
            children: [
              FButton.icon(
                variant: .ghost,
                semanticsLabel: l10n.fortressExitFocus,
                onPress: _exit,
                child: const Icon(FLucideIcons.x, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.category.title,
                  style: theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colors.primary.withValues(alpha: .08),
                      ),
                      child: Icon(
                        session.allComplete
                            ? FLucideIcons.check
                            : FLucideIcons.bookOpen,
                        size: 40,
                        color: theme.colors.primary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      session.allComplete
                          ? l10n.fortressCompleted
                          : l10n.fortressReachedEnd,
                      textAlign: TextAlign.center,
                      style: theme.typography.body.xl3.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.category.title,
                      textAlign: TextAlign.center,
                      style: theme.typography.body.lg.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 360,
                      child: FortressChapterSegments(
                        targets: session.targets,
                        remaining: session.remainingCounts,
                        index: session.index,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.fortressChapterProgress(
                        session.completedItems,
                        widget.duas.length,
                      ),
                      textAlign: TextAlign.center,
                      style: theme.typography.body.md.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 208,
                          child: FButton(
                            onPress: session.allComplete
                                ? _exit
                                : session.continueUnfinished,
                            child: Flexible(
                              child: Text(
                                session.allComplete
                                    ? l10n.fortressReturnChapter
                                    : l10n.fortressContinueUnfinished,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 176,
                          child: FButton(
                            variant: .outline,
                            onPress: session.restart,
                            child: Flexible(
                              child: Text(l10n.fortressReadAgain),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 176,
                          child: FButton(
                            variant: .ghost,
                            prefix: const Icon(FLucideIcons.share2, size: 16),
                            onPress: () => _share(chapter: true),
                            child: Flexible(
                              child: Text(l10n.fortressShareChapter),
                            ),
                          ),
                        ),
                        if (session.canUndo)
                          SizedBox(
                            width: 176,
                            child: FButton(
                              variant: .ghost,
                              onPress: session.undo,
                              child: Flexible(
                                child: Text(l10n.fortressUndoCount),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reader(BoxConstraints constraints) {
    final l10n = context.l10n;
    final theme = context.theme;
    if (session.ended) return _completion(constraints);
    final dua = widget.duas[session.index];
    final compactDock =
        constraints.maxHeight < 600 || constraints.maxWidth < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: LayoutBuilder(
            builder: (context, header) {
              final title = Text(
                widget.category.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.body.md.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              );
              final progress = FortressChapterSegments(
                targets: session.targets,
                remaining: session.remainingCounts,
                index: session.index,
              );
              return Column(
                spacing: 12,
                children: [
                  Row(
                    spacing: 16,
                    children: [
                      FButton.icon(
                        variant: .ghost,
                        onPress: _exit,
                        semanticsLabel: l10n.fortressExitFocus,
                        child: const Icon(FLucideIcons.x, size: 18),
                      ),
                      Expanded(child: title),
                      if (header.maxWidth > 650)
                        Expanded(flex: 2, child: progress),
                      Flexible(
                        flex: 0,
                        child: Text(
                          '${session.index + 1} / ${widget.duas.length}',
                          textDirection: TextDirection.ltr,
                          style: theme.typography.body.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (header.maxWidth <= 650) progress,
                ],
              );
            },
          ),
        ),
        Expanded(
          child: Focus(
            focusNode: _stageFocus,
            autofocus: true,
            child: LayoutBuilder(
              builder: (context, stage) {
                final width = math.min(
                  720.0,
                  math.max(1.0, stage.maxWidth - 64),
                );
                final scaler = MediaQuery.textScalerOf(context);
                final measureKey = (
                  dua.contentId,
                  width,
                  stage.maxHeight,
                  scaler,
                  theme,
                );
                if (_stageMeasurementKey != measureKey) {
                  _stageMeasurementKey = measureKey;
                  final fontSize = fortressFocusFontSize(
                    dua.text,
                    width,
                    stage.maxHeight,
                    scaler,
                  );
                  final style = theme.typography.body.xl3.copyWith(
                    fontFamily: FontFamily.uthmanTN,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                    height: 1.85,
                  );
                  final painter = TextPainter(
                    text: fortressDhikrSpan(dua.text, style),
                    textDirection: TextDirection.rtl,
                    textScaler: scaler,
                  )..layout(maxWidth: width);
                  _stageShort = painter.height < stage.maxHeight - 48;
                  painter.dispose();
                  _stageStyle = style;
                  _stageContent = Directionality(
                    textDirection: TextDirection.rtl,
                    child: DesktopSelectionArea(
                      child: FortressDuaContent(
                        key: ValueKey(dua.contentId),
                        dua: dua,
                        mode: FortressDuaContentMode.focusReading,
                        proseStyle: _stageStyle,
                        textAlign: _stageShort
                            ? TextAlign.center
                            : TextAlign.start,
                      ),
                    ),
                  );
                }
                final short = _stageShort;
                return Listener(
                  onPointerDown: (event) {
                    if (event.buttons != kPrimaryButton) return;
                    _tapPointer = event.pointer;
                    _tapStart = event.position;
                    _tapMoved = false;
                    _tapTime = DateTime.now();
                  },
                  onPointerMove: (event) {
                    if (event.pointer == _tapPointer &&
                        (event.position - _tapStart!).distance > 6)
                      _tapMoved = true;
                  },
                  onPointerCancel: (_) => _tapPointer = null,
                  onPointerUp: (event) {
                    if (event.pointer == _tapPointer &&
                        !_tapMoved &&
                        DateTime.now().difference(_tapTime!) <
                            const Duration(milliseconds: 500)) {
                      _stageFocus.requestFocus();
                      _count();
                    }
                    _tapPointer = null;
                  },
                  onPointerSignal: (event) {
                    if (session.paused ||
                        event is! PointerScrollEvent ||
                        event.scrollDelta.dx.abs() <=
                            event.scrollDelta.dy.abs())
                      return;
                    final now = DateTime.now();
                    if (_lastWheel != null &&
                        now.difference(_lastWheel!) >
                            const Duration(milliseconds: 300))
                      _horizontalWheel = 0;
                    _lastWheel = now;
                    _horizontalWheel += event.scrollDelta.dx;
                    if (_horizontalWheel.abs() > 100) {
                      _horizontalWheel > 0
                          ? session.next()
                          : session.previous();
                      _horizontalWheel = 0;
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: session.paused
                        ? null
                        : (details) {
                            if ((details.primaryVelocity ?? 0).abs() > 420) {
                              details.primaryVelocity! > 0
                                  ? session.next()
                                  : session.previous();
                            }
                          },
                    child: Scrollbar(
                      controller: _scroll,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(0, stage.maxHeight - 48),
                          ),
                          child: Align(
                            alignment: short
                                ? Alignment.center
                                : Alignment.topCenter,
                            child: SizedBox(
                              width: width,
                              child: DirectionalContentSwitcher(
                                currentKey: dua.contentId,
                                slideDirection: session.direction,
                                child: _stageContent!,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: LayoutBuilder(
            builder: (context, rail) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: rail.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    for (final kind in FortressDetailKind.available(dua))
                      FButton(
                        variant: _detail == kind ? .secondary : .ghost,
                        onPress: () => _openDetails(kind),
                        child: Text(kind.label(l10n)),
                      ),
                    FButton(
                      variant: .ghost,
                      prefix: const Icon(FLucideIcons.share2, size: 16),
                      onPress: _share,
                      child: Text(l10n.fortressShare),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (dua.hasVirtue)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 640,
                  maxHeight: compactDock
                      ? math.min(160, constraints.maxHeight * .2)
                      : 180,
                ),
                child: SingleChildScrollView(
                  child: Semantics(
                    label: l10n.fortressVirtue,
                    child: Text(
                      dua.virtue!,
                      key: const ValueKey('fortress-focus-virtue'),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: theme.typography.body.md.copyWith(
                        fontSize: compactDock ? 14 : 16,
                        height: 1.6,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, compactDock ? 12 : 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: compactDock ? 16 : 32,
            children: [
              FButton.icon(
                variant: .outline,
                onPress: session.index > 0 ? session.previous : null,
                semanticsLabel: l10n.fortressPrevious,
                child: const Icon(FLucideIcons.chevronLeft),
              ),
              _Counter(
                session: session,
                size: MediaQuery.textScalerOf(context).scale(14) > 21
                    ? 160
                    : compactDock
                    ? 96
                    : 128,
                onCount: _count,
              ),
              FButton.icon(
                variant: .outline,
                onPress: session.next,
                semanticsLabel: session.index == widget.duas.length - 1
                    ? l10n.fortressFinish
                    : l10n.next,
                child: const Icon(FLucideIcons.chevronRight),
              ),
            ],
          ),
        ),
        if (constraints.maxHeight >= 680 && constraints.maxWidth >= 700)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l10n.fortressFocusInputHint,
              textAlign: TextAlign.center,
              style: theme.typography.body.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
      ],
    );
  }
}

/// Chooses a stable reading tier using actual laid-out lines and user scaling.
double fortressFocusFontSize(
  String text,
  double width,
  double height,
  TextScaler scaler,
) {
  final compact = width < 500;
  final tiers = compact ? [40.0, 32.0, 26.0] : [56.0, 40.0, 30.0];
  for (final size in tiers) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: FontFamily.uthmanTN,
          fontSize: size,
          height: 1.85,
        ),
      ),
      textDirection: TextDirection.rtl,
      textScaler: scaler,
    )..layout(maxWidth: width);
    final fits = painter.height <= height * .78;
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    if (fits && (size != tiers.first || lines <= 2)) return size;
  }
  return tiers.last;
}

class FortressChapterSegments extends StatelessWidget {
  const FortressChapterSegments({
    required this.targets,
    required this.remaining,
    required this.index,
    super.key,
  });
  final List<int> targets;
  final List<int> remaining;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Semantics(
      label: context.l10n.fortressChapterProgress(
        remaining.where((n) => n == 0).length,
        targets.length,
      ),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            final capacity = math.max(1, ((box.maxWidth + 4) / 12).floor());
            final start = (index - capacity ~/ 2)
                .clamp(0, math.max(0, targets.length - capacity))
                .toInt();
            final end = math.min(targets.length, start + capacity);
            return Row(
              spacing: 4,
              children: [
                if (start > 0)
                  Icon(
                    FLucideIcons.ellipsis,
                    size: 12,
                    color: colors.mutedForeground,
                  ),
                for (var i = start; i < end; i++)
                  Expanded(
                    child: SizedBox(
                      height: 14,
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: colors.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(('fortress-segment', i)),
                              tween: Tween(
                                end: (targets[i] - remaining[i]) / targets[i],
                              ),
                              duration: reduceMotion(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              child: ColoredBox(
                                color: colors.primary,
                                child: const SizedBox.expand(),
                              ),
                              builder: (_, value, child) => Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: FractionallySizedBox(
                                  widthFactor: value,
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (i == index)
                            Container(
                              height: 2,
                              width: 10,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (end < targets.length)
                  Icon(
                    FLucideIcons.ellipsis,
                    size: 12,
                    color: colors.mutedForeground,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.session,
    required this.size,
    required this.onCount,
  });
  final FortressFocusSession session;
  final double size;
  final VoidCallback onCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    return FContextMenu(
      control: .managed(
        onChange: (shown) => session.pause(FortressFocusPause.menu, shown),
      ),
      menuBuilder: (context, controller, _) => [
        FItemGroup(
          children: [
            FItem(
              prefix: const Icon(FLucideIcons.undo2),
              title: Text(l10n.fortressUndoCount),
              onPress: session.canUndo
                  ? () {
                      session.undo();
                      unawaited(controller.hide());
                    }
                  : null,
            ),
          ],
        ),
      ],
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: session.progress),
        duration: reduceMotion(context) ? Duration.zero : theme.durations.fast,
        builder: (context, progress, _) => Semantics(
          liveRegion: true,
          label: l10n.fortressCountProgress(
            session.completed,
            session.targets[session.index],
          ),
          child: FTappable(
            key: const ValueKey('fortress-counter'),
            onPress: session.paused || session.remaining == 0 ? null : onCount,
            builder: (context, states, _) => AnimatedScale(
              scale:
                  states.contains(FTappableVariant.pressed) &&
                      !reduceMotion(context)
                  ? .97
                  : 1,
              duration: reduceMotion(context)
                  ? Duration.zero
                  : theme.durations.instant,
              child: Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: states.contains(FTappableVariant.hovered)
                      ? theme.colors.secondary
                      : theme.colors.secondary.withValues(alpha: .55),
                  border: states.contains(FTappableVariant.focused)
                      ? Border.all(color: theme.colors.primary, width: 2)
                      : null,
                ),
                child: CustomPaint(
                  painter: _CounterRing(
                    progress: progress,
                    track: theme.colors.border,
                    active: theme.colors.primary,
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          session.remaining == 0
                              ? Icon(
                                  FLucideIcons.check,
                                  size: 34,
                                  color: theme.colors.primary,
                                )
                              : Text(
                                  '${session.completed}',
                                  style: theme.typography.body.xl3.copyWith(
                                    fontSize: size * .29,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                    height: 1.1,
                                  ),
                                ),
                          const SizedBox(height: 4),
                          Text(
                            '${session.completed} / ${session.targets[session.index]}',
                            textDirection: TextDirection.ltr,
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterRing extends CustomPainter {
  const _CounterRing({
    required this.progress,
    required this.track,
    required this.active,
  });
  final double progress;
  final Color track;
  final Color active;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(rect.deflate(3), paint..color = track);
    if (progress > 0)
      canvas.drawArc(
        rect.deflate(3),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paint..color = active,
      );
  }

  @override
  bool shouldRepaint(_CounterRing old) =>
      old.progress != progress || old.track != track || old.active != active;
}
