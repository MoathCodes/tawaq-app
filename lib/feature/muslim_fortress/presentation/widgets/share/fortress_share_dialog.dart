import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/clipboard_image.dart';
import 'package:tawaq/core/utils/reveal_folder.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/share_card_dialog_layout.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/models/fortress_share_include.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_booklet_plan.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_pdf_export.dart';
import 'package:tawaq/theme/theme.dart';

Future<void> showFortressShareDialog(
  BuildContext context,
  FortressDuaItem dua, {
  List<FortressDuaItem>? chapter,
  bool entireChapter = false,
}) => showFDialog<void>(
  context: context,
  builder: (context, style, animation) => FortressShareDialog(
    dua: dua,
    chapter: chapter,
    entireChapter: entireChapter,
    style: style,
    animation: animation,
  ),
);

class FortressShareDialog extends ConsumerStatefulWidget {
  const FortressShareDialog({
    required this.dua,
    required this.style,
    this.chapter,
    this.entireChapter = false,
    this.animation,
    super.key,
  });
  final FortressDuaItem dua;
  final List<FortressDuaItem>? chapter;
  final bool entireChapter;
  final FDialogStyle style;
  final Animation<double>? animation;
  @override
  ConsumerState<FortressShareDialog> createState() => _ShareState();
}

class _ShareState extends ConsumerState<FortressShareDialog> {
  late bool _chapter = widget.entireChapter && widget.chapter != null;
  double _textScale = 1;
  Timer? _resizeDebounce;
  bool _pdf = false;
  bool _busy = false;
  bool _loading = false;
  int _epoch = 0;
  int _page = 0;
  int _exported = 0;
  int _pdfAssembled = 0;
  FortressPdfExport? _pdfJob;
  Object? _error;
  FortressBookletPlan? _plan;
  Directory? _saved;
  List<File> _files = [];
  late Set<FortressShareInclude> _includes = {
    FortressShareInclude.repetition,
    FortressShareInclude.virtue,
    FortressShareInclude.appName,
  };
  final _dragKeys = <GlobalKey<DragItemWidgetState>>[];
  bool _initialized = false;
  List<FortressDuaItem> get _items => _chapter ? widget.chapter! : [widget.dua];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      unawaited(_prepare());
    }
  }

  @override
  void dispose() {
    _epoch++;
    _resizeDebounce?.cancel();
    _pdfJob?.cancel();
    super.dispose();
  }

  Future<void> _prepare() async {
    final epoch = ++_epoch;
    final theme = context.theme;
    final l10n = context.l10n;
    final items = List<FortressDuaItem>.of(_items);
    final includes = Set<FortressShareInclude>.of(_includes);
    final textScale = _textScale;
    setState(() {
      _loading = true;
      _error = null;
      _plan = null;
      _page = 0;
      _files = [];
      _saved = null;
    });
    try {
      final commentary = <int, HisnCommentary?>{};
      List<FortressShareInclude> fieldsFor(FortressDuaItem item) => [
        if (item.hasSharh) FortressShareInclude.sharh,
        if (item.hasBenefit) FortressShareInclude.benefit,
        if (item.hasHadith) FortressShareInclude.hadith,
      ].where(includes.contains).toList();
      final needsCommentary = includes.any(
        (option) => {
          FortressShareInclude.sharh,
          FortressShareInclude.hadith,
          FortressShareInclude.benefit,
        }.contains(option),
      );
      if (needsCommentary &&
          items.any(
            (item) => fieldsFor(item).isNotEmpty && item.commentary == null,
          )) {
        late FortressRepository repository;
        try {
          repository = await ref.read(fortressRepositoryProvider.future);
        } on Object {
          final failed = items.indexWhere(
            (item) => fieldsFor(item).isNotEmpty && item.commentary == null,
          );
          throw FortressBookletDetailFailure(
            failed + 1,
            fieldsFor(items[failed]).first,
          );
        }
        if (!mounted || epoch != _epoch) return;
        for (final (index, item) in items.indexed) {
          final fields = fieldsFor(item);
          if (fields.isEmpty) continue;
          try {
            commentary[item.contentId] =
                item.commentary ??
                repository.loadCommentaryForContent(item.contentId);
          } on Object {
            throw FortressBookletDetailFailure(index + 1, fields.first);
          }
          await Future<void>.delayed(Duration.zero);
          if (!mounted || epoch != _epoch) return;
        }
      }
      final blocks = FortressBookletPlan.content(
        items: items,
        options: FortressShareOptions(includes),
        commentary: commentary,
        l10n: l10n,
      );
      final plan = await FortressBookletPlan.create(
        title: widget.dua.category,
        blocks: blocks,
        colors: theme.colors,
        l10n: l10n,
        textScale: textScale,
        appName: includes.contains(FortressShareInclude.appName),
        cancelled: () => !mounted || epoch != _epoch,
      );
      if (mounted && epoch == _epoch)
        setState(() {
          _plan = plan;
          _loading = false;
        });
    } on FortressBookletCancelled {
      /* A superseded preview owns no state. */
    } on Object catch (error) {
      if (mounted && epoch == _epoch)
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  void _cancel() {
    _epoch++;
    _pdfJob?.cancel();
    setState(() {
      _busy = false;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final plan = _plan;
    if (plan == null || _busy || plan.pages.isEmpty) return;
    final epoch = ++_epoch;
    final outputPdf = _pdf;
    setState(() {
      _busy = true;
      _error = null;
      _exported = 0;
      _pdfAssembled = 0;
    });
    Directory? staging;
    FortressPdfExport? pdfJob;
    try {
      final parent =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final exportRoot = await Directory(p.join(parent.path, 'Tawaq'))
          .create(recursive: true);
      // createTemp gives the job an exclusive destination and avoids collisions.
      staging = await exportRoot.createTemp('.tawaq-fortress-');
      final files = <File>[];
      for (var index = 0; index < plan.pages.length; index++) {
        if (!mounted || epoch != _epoch) throw const FortressBookletCancelled();
        final bytes = await plan.png(index);
        final file = File(
          p.join(staging.path, '${(index + 1).toString().padLeft(3, '0')}.png'),
        );
        await file.writeAsBytes(bytes, flush: true);
        files.add(file);
        if (mounted && epoch == _epoch) setState(() => _exported = index + 1);
        await Future<void>.delayed(Duration.zero);
      }
      if (outputPdf) {
        if (!mounted || epoch != _epoch) throw const FortressBookletCancelled();
        final file = File(p.join(staging.path, 'tawaq-fortress.pdf'));
        pdfJob = FortressPdfExport();
        _pdfJob = pdfJob;
        await pdfJob.run(
          pages: files.map((file) => file.path).toList(),
          destination: file.path,
          onProgress: (count) {
            if (mounted && epoch == _epoch)
              setState(() => _pdfAssembled = count);
          },
        );
        for (final page in files) {
          await page.delete();
        }
        files
          ..clear()
          ..add(file);
      }
      if (!mounted || epoch != _epoch) throw const FortressBookletCancelled();
      final safeTitle = widget.dua.category
          .replaceAll(RegExp(r'[/\\\x00-\x1f<>:"|?*]'), '-')
          .trim();
      final leaf = p
          .basename(staging.path)
          .replaceFirst('.tawaq-fortress-', '');
      final completed = await staging.rename(
        p.join(
          exportRoot.path,
          'tawaq-${safeTitle.isEmpty ? widget.dua.contentId : safeTitle}-$leaf',
        ),
      );
      staging = null;
      if (!mounted || epoch != _epoch) {
        await completed.delete(recursive: true);
        throw const FortressBookletCancelled();
      }
      setState(() {
        _saved = completed;
        _files = [
          for (final file in files)
            File(p.join(completed.path, p.basename(file.path))),
        ];
        _dragKeys.clear();
        _dragKeys.addAll(
          List.generate(_files.length, (_) => GlobalKey<DragItemWidgetState>()),
        );
        _busy = false;
      });
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleCheck),
        title: Text(context.l10n.fortressExportReady),
        description: Text(
          '${plan.title}\n${context.l10n.fortressExportSummary(plan.pages.length, outputPdf ? 'PDF' : 'PNG')}',
        ),
        duration: const Duration(seconds: 8),
        suffixBuilder: (toastContext, entry) => FButton(
          mainAxisSize: MainAxisSize.min,
          size: .sm,
          variant: .ghost,
          prefix: const Icon(FLucideIcons.folderOpen, size: 16),
          onPress: () async {
            if (await revealFolderInFileManager(completed.path)) {
              entry.dismiss();
            } else if (toastContext.mounted) {
              showFToast(
                context: toastContext,
                icon: const Icon(FLucideIcons.triangleAlert),
                title: Text(toastContext.l10n.openFolderFailed),
              );
            }
          },
          child: Text(context.l10n.openFolder),
        ),
      );
    } on FortressPdfCancelled {
      if (mounted && epoch == _epoch) setState(() => _busy = false);
    } on FortressBookletCancelled {
      if (mounted && epoch == _epoch) setState(() => _busy = false);
    } on Object catch (error) {
      if (mounted && epoch == _epoch)
        setState(() {
          _error = error;
          _busy = false;
        });
    } finally {
      if (identical(_pdfJob, pdfJob)) _pdfJob = null;
      if (staging != null && await staging.exists())
        await staging.delete(recursive: true);
    }
  }

  Future<void> _copyImage() async {
    final plan = _plan;
    if (plan == null || _busy) return;
    setState(() => _busy = true);
    try {
      final error = await copyPngToClipboard(
        await plan.png(_page),
        l10n: context.l10n,
      );
      if (mounted)
        showFToast(
          context: context,
          title: Text(error ?? context.l10n.shareImageCopied),
        );
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _available(FortressShareInclude kind) => _items.any(
    (item) => switch (kind) {
      FortressShareInclude.repetition || FortressShareInclude.appName => true,
      FortressShareInclude.source => item.hasSource,
      FortressShareInclude.virtue => item.hasVirtue,
      FortressShareInclude.sharh => item.hasSharh,
      FortressShareInclude.hadith => item.hasHadith,
      FortressShareInclude.benefit => item.hasBenefit,
    },
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final plan = _plan;
    final disabled = _busy || _loading || plan == null || plan.pages.isEmpty;
    final labels = {
      FortressShareInclude.repetition: l10n.fortressRepetition,
      FortressShareInclude.source: l10n.fortressSourceReference,
      FortressShareInclude.virtue: l10n.fortressVirtue,
      FortressShareInclude.sharh: l10n.fortressSharh,
      FortressShareInclude.hadith: l10n.fortressRelatedHadith,
      FortressShareInclude.benefit: l10n.fortressBenefit,
      FortressShareInclude.appName: l10n.shareAppName,
    };
    Widget choices(
      List<String> labels,
      int selected,
      ValueChanged<int> change,
    ) => FTabs(
      style: theme.tabs.compact,
      control: .lifted(index: selected, onChange: _busy ? (_) {} : change),
      children: [
        for (final label in labels)
          .entry(label: Text(label), child: const SizedBox.shrink()),
      ],
    );
    final settings = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        if (widget.chapter != null)
          choices(
            [l10n.fortressShareThisDhikr, l10n.fortressEntireChapter],
            _chapter ? 1 : 0,
            (index) {
              setState(() {
                _chapter = index == 1;
                _includes = {
                  FortressShareInclude.repetition,
                  FortressShareInclude.virtue,
                  FortressShareInclude.appName,
                };
              });
              unawaited(_prepare());
            },
          ),
        FSelectTileGroup<FortressShareInclude>(
          enabled: !_busy,
          label: Text(l10n.shareIncludeInImage),
          control: .lifted(
            value: _includes,
            onChange: (values) {
              setState(() => _includes = Set.of(values));
              unawaited(_prepare());
            },
          ),
          children: [
            for (final option in FortressShareInclude.values)
              if (_available(option))
                FSelectTile(value: option, title: Text(labels[option]!)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.fortressExportTextSize)),
                Text(
                  '${(_textScale * 100).round()}%',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
            FSlider(
              key: const ValueKey('fortress-export-text-size'),
              // Endpoint marks are centred on the track. Keep their labels
              // inside the settings viewport when saved output adds scrolling.
              style: .delta(
                childPadding: .add(const EdgeInsets.symmetric(horizontal: 24)),
              ),
              enabled: !_busy,
              semanticValueFormatterCallback: (value) =>
                  '${(80 + value * 80).round()}%',
              control: .liftedContinuous(
                value: FSliderValue(max: (_textScale - .8) / .8),
                onChange: (value) {
                  _resizeDebounce?.cancel();
                  _epoch++;
                  setState(() {
                    _textScale = .8 + value.max * .8;
                    _loading = true;
                    _saved = null;
                    _files = [];
                  });
                  _resizeDebounce = Timer(
                    const Duration(milliseconds: 150),
                    () => unawaited(_prepare()),
                  );
                },
              ),
              onEnd: (_) {
                _resizeDebounce?.cancel();
                unawaited(_prepare());
              },
              marks: const [
                .mark(value: 0, label: Text('80%')),
                .mark(value: .25, label: Text('100%')),
                .mark(value: 1, label: Text('160%')),
              ],
            ),
          ],
        ),
        choices(
          [l10n.fortressImages, 'PDF'],
          _pdf ? 1 : 0,
          (index) => setState(() => _pdf = index == 1),
        ),
        if (_pdf)
          Text(
            l10n.fortressPdfVisualNote,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        if (_saved != null)
          FButton(
            mainAxisSize: MainAxisSize.min,
            prefix: const Icon(FLucideIcons.folderOpen, size: 16),
            variant: .secondary,
            onPress: () async {
              if (!await revealFolderInFileManager(_saved!.path) &&
                  context.mounted)
                showFToast(
                  context: context,
                  title: Text(l10n.openFolderFailed),
                );
            },
            child: Text(l10n.openFolder),
          ),
        if (_files.isNotEmpty) _bundle(),
      ],
    );
    final preview = Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 12,
                      children: [
                        const FCircularProgress.loader(),
                        Text(l10n.fortressPreparingPages),
                      ],
                    ),
                  )
                : plan == null || plan.pages.isEmpty
                ? _error != null
                      ? const SizedBox.shrink()
                      : Center(child: Text(l10n.fortressNoAdhkarInChapter))
                : FortressBookletPreview(plan: plan, index: _page),
          ),
        ),
        if (plan != null && plan.pages.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              FButton.icon(
                variant: .ghost,
                onPress: !_busy && _page > 0
                    ? () => setState(() => _page--)
                    : null,
                semanticsLabel: l10n.fortressPrevious,
                child: const Icon(FLucideIcons.chevronLeft),
              ),
              Flexible(
                child: Text(
                  l10n.fortressPagePosition(_page + 1, plan.pages.length),
                ),
              ),
              FButton.icon(
                variant: .ghost,
                onPress: !_busy && _page < plan.pages.length - 1
                    ? () => setState(() => _page++)
                    : null,
                semanticsLabel: l10n.next,
                child: const Icon(FLucideIcons.chevronRight),
              ),
            ],
          ),
      ],
    );
    return FDialog(
      style: widget.style,
      animation: widget.animation,
      constraints: dialogConstraints(
        context,
        preferredWidth: 1000,
        preferredHeight: 720,
        minWidth: 320,
      ),
      builder: (context, style) => ForuiDialogLayout(
        style: style,
        expandActions: true,
        title: Row(
          children: [
            Expanded(
              child: Text(_chapter ? l10n.fortressBooklet : l10n.fortressShare),
            ),
            FButton.icon(
              variant: .ghost,
              onPress: () {
                _cancel();
                Navigator.of(context).pop();
              },
              semanticsLabel: l10n.close,
              child: const Icon(FLucideIcons.x),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ShareCardDialogLayout(
                preview: preview,
                settings: settings,
              ),
            ),
            if (_busy)
              FDeterminateProgress(
                value: plan == null || plan.pages.isEmpty
                    ? 0
                    : _pdf
                    ? (_exported / plan.pages.length) * .5 +
                          (_pdfAssembled / plan.pages.length) * .4
                    : _exported / plan.pages.length,
                semanticsLabel: l10n.fortressPreparingPages,
              ),
            if (_busy && _pdf && _exported == plan?.pages.length)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.fortressPreparingPdf,
                  style: theme.typography.body.sm,
                ),
              ),
            if (_error != null)
              ErrorStatePanel(
                message: switch (_error) {
                  FortressBookletDetailFailure(
                    :final itemNumber,
                    :final field,
                  ) =>
                    l10n.fortressExportDetailFailed(itemNumber, switch (field) {
                      FortressShareInclude.sharh => l10n.fortressSharh,
                      FortressShareInclude.benefit => l10n.fortressBenefit,
                      _ => l10n.fortressRelatedHadith,
                    }),
                  _ => l10n.fortressExportFailed,
                },
                retryLabel: l10n.fortressRetry,
                onRetry: () => unawaited(_prepare()),
              ),
          ],
        ),
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              final actions = _busy
                  ? [
                      FButton(
                        mainAxisSize: MainAxisSize.min,
                        variant: .secondary,
                        prefix: const Icon(FLucideIcons.x, size: 16),
                        onPress: _cancel,
                        child: Text(l10n.cancel),
                      ),
                    ]
                  : [
                      FButton(
                        mainAxisSize: MainAxisSize.min,
                        prefix: Icon(
                          _pdf ? FLucideIcons.fileDown : FLucideIcons.download,
                          size: 16,
                        ),
                        onPress: disabled ? null : _save,
                        child: Flexible(
                          child: Text(
                            _pdf
                                ? l10n.fortressSavePdf
                                : (plan?.pages.length ?? 1) == 1
                                ? l10n.shareSaveImage
                                : l10n.fortressSavePages,
                          ),
                        ),
                      ),
                      FButton(
                        variant: .secondary,
                        mainAxisSize: MainAxisSize.min,
                        prefix: const Icon(FLucideIcons.image, size: 16),
                        onPress: disabled ? null : _copyImage,
                        child: Flexible(child: Text(l10n.shareCopyImage)),
                      ),
                      FButton(
                        mainAxisSize: MainAxisSize.min,
                        prefix: const Icon(FLucideIcons.copy, size: 16),
                        variant: .ghost,
                        onPress: disabled
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: plan.plainText),
                                );
                                if (context.mounted)
                                  showFToast(
                                    context: context,
                                    title: Text(l10n.fortressDhikrCopied),
                                  );
                              },
                        child: Flexible(child: Text(l10n.fortressCopyText)),
                      ),
                    ];
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _bundle() {
    Widget result = DraggableWidget(
      dragItemsProvider: (_) => [
        for (final key in _dragKeys)
          if (key.currentState != null) key.currentState!,
      ],
      child: FButton(
        variant: .outline,
        onPress: () {},
        prefix: const Icon(FLucideIcons.grip),
        child: Text(context.l10n.fortressDragBooklet),
      ),
    );
    for (var i = _files.length - 1; i >= 0; i--) {
      final file = _files[i];
      result = DragItemWidget(
        key: _dragKeys[i],
        allowedOperations: () => [DropOperation.copy],
        dragItemProvider: (_) {
          final item = DragItem(suggestedName: p.basename(file.path));
          item.add(Formats.fileUri(file.uri));
          return item;
        },
        child: result,
      );
    }
    return result;
  }
}
