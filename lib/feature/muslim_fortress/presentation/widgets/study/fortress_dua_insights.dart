import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart' show TickerCanceled;
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/reduce_motion.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_commentary_text.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_study_panel.dart';

/// Owns the persistent side-sheet lifetime for the chapter reader.
class FortressStudyHost extends StatefulWidget {
  const FortressStudyHost({required this.child, this.chapterId, super.key});
  final Widget child;
  final int? chapterId;
  @override
  State<FortressStudyHost> createState() => _FortressStudyHostState();
}

class _FortressStudyHostState extends State<FortressStudyHost> {
  FPersistentSheetController? _sheet;
  final _closingSheets = <FPersistentSheetController>{};
  final _selections =
      <FPersistentSheetController, ValueNotifier<FortressDetailKind>>{};
  BuildContext? _sheetContext;
  Completer<void>? _closed;
  final _bucket = PageStorageBucket();

  Future<void> open(FortressDuaItem dua, FortressDetailKind? initial) {
    close();
    final kinds = FortressDetailKind.available(dua);
    if (kinds.isEmpty) return Future.value();
    final selected = ValueNotifier(initial ?? kinds.first);
    _closed = Completer<void>();
    final context = _sheetContext!;
    late final FPersistentSheetController created;
    created = showFPersistentSheet(
      context: context,
      side: Directionality.of(context) == TextDirection.rtl ? .ltr : .rtl,
      draggable: false,
      mainAxisMaxRatio: 1,
      onClosing: () {
        if (_sheet == created) close();
      },
      builder: (context, controller) => SizedBox(
        width: math.min(
          math.max(480, FortressStudyPanel.minimumTabWidth(context, dua)),
          MediaQuery.sizeOf(context).width,
        ),
        height: double.infinity,
        child: ValueListenableBuilder(
          valueListenable: selected,
          builder: (_, kind, _) => FortressStudyPanel(
            dua: dua,
            kind: kind,
            bucket: _bucket,
            onKindChanged: (kind) {
              selected.value = kind;
            },
            onClose: close,
          ),
        ),
      ),
    );
    _selections[created] = selected;
    _sheet = created;
    setState(() {});
    return _closed!.future;
  }

  void close() {
    final sheet = _sheet;
    _sheet = null;
    if (sheet != null) {
      _closingSheets.add(sheet);
      unawaited(_finishClosingSheet(sheet));
    }
    if (mounted) setState(() {});
    final closed = _closed;
    _closed = null;
    if (closed != null && !closed.isCompleted) closed.complete();
  }

  Future<void> _finishClosingSheet(FPersistentSheetController sheet) async {
    try {
      await sheet.hide().orCancel;
    } on TickerCanceled {
      // Removing the chapter reader cancels any sheet still closing.
    } finally {
      if (_closingSheets.remove(sheet)) {
        sheet.dispose();
        _selections.remove(sheet)?.dispose();
      }
    }
  }

  void _disposeSheets() {
    _sheet?.dispose();
    _selections.remove(_sheet)?.dispose();
    _sheet = null;
    final closing = _closingSheets.toList();
    _closingSheets.clear();
    for (final sheet in closing) {
      sheet.dispose();
      _selections.remove(sheet)?.dispose();
    }
    if (_closed != null && !_closed!.isCompleted) _closed!.complete();
    _closed = null;
  }

  @override
  void didUpdateWidget(covariant FortressStudyHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterId != widget.chapterId) close();
  }

  @override
  void deactivate() {
    // FSheets is a child: cancel its tickers before children unmount.
    _disposeSheets();
    super.deactivate();
  }

  @override
  void dispose() {
    _disposeSheets();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FSheets(
    child: Builder(
      builder: (context) {
        _sheetContext = context;
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _sheet == null,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _sheet == null ? 0 : 1),
                  duration: reduceMotion(context)
                      ? Duration.zero
                      : context
                            .theme
                            .persistentSheetStyle
                            .motion
                            .expandDuration,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => value == 0
                      ? const SizedBox.shrink()
                      : FModalBarrier(
                          key: const ValueKey('fortress-study-backdrop'),
                          filter: context.theme.dialogRouteStyle.barrierFilter
                              ?.call(context, value),
                          semanticsLabel: context.l10n.close,
                          onDismiss: close,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> showFortressStudySheet(
  BuildContext context,
  FortressDuaItem dua, {
  FortressDetailKind? kind,
}) {
  final host = context.findAncestorStateOfType<_FortressStudyHostState>();
  if (host == null)
    throw FlutterError('Fortress details require a FortressStudyHost.');
  return host.open(dua, kind);
}

class FortressDuaStudyNavAction extends StatelessWidget {
  const FortressDuaStudyNavAction({required this.dua, super.key});
  final FortressDuaItem dua;
  @override
  Widget build(BuildContext context) =>
      FortressDetailKind.available(dua).isEmpty
      ? const SizedBox.shrink()
      : FButton(
          variant: .ghost,
          prefix: const Icon(FLucideIcons.bookOpenText),
          onPress: () => unawaited(showFortressStudySheet(context, dua)),
          child: Text(context.l10n.fortressShowDetails),
        );
}

class FortressDuaVirtueLine extends StatelessWidget {
  const FortressDuaVirtueLine({required this.virtue, super.key});
  final String virtue;
  @override
  Widget build(BuildContext context) => FortressCommentaryText(
    text: virtue,
    baseStyle: context.theme.typography.body.sm.copyWith(
      color: context.theme.colors.mutedForeground,
      height: 1.75,
    ),
    textAlign: TextAlign.center,
  );
}

class FortressDuaSourceLine extends StatelessWidget {
  const FortressDuaSourceLine({required this.reference, super.key});
  final String reference;
  @override
  Widget build(BuildContext context) => ScopedSelectableText(
    reference,
    style: context.theme.typography.body.sm.copyWith(
      color: context.theme.colors.mutedForeground,
      height: 1.6,
    ),
    textAlign: TextAlign.center,
  );
}
