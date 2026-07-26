import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/core/mushaf_layout.dart';
import 'package:mushaf_reader/src/core/mushaf_page_range_layout.dart';
import 'package:mushaf_reader/src/data/mushaf_page_range_resolver.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';
import 'package:mushaf_reader/src/presentation/mushaf_loading.dart';
import 'package:mushaf_reader/src/presentation/widgets/mushaf_page_surah_blocks.dart';

/// Renders mushaf text for a full page or a subset of ayahs on one or more pages.
///
/// Host apps supply selection parameters and optional chrome flags. The package
/// handles fragment filtering, surah header / basmalah placement, and newline
/// compaction for excerpts.
///
/// ## Single-page range
///
/// ```dart
/// MushafPageRange.onPage(
///   page: 1,
///   startAyahId: 1,
///   endAyahId: 3,
///   style: MushafStyle.modify(ayah: (s) => s.copyWith(color: Colors.brown)),
/// )
/// ```
///
/// ## Cross-page contiguous range
///
/// ```dart
/// MushafPageRange.contiguous(
///   startAyahId: 5,
///   endAyahId: 10,
///   controller: controller,
/// )
/// ```
///
/// This is a rendering primitive — not a share card. Wrap with your own layout,
/// borders, and image capture as needed.
///
/// See also: [MushafPage], [MushafPageRangeLayout].
class MushafPageRange extends StatefulWidget {
  /// Renders a contiguous ayah range on one mushaf page.
  const MushafPageRange.onPage({
    required this.page,
    this.startAyahId,
    this.endAyahId,
    this.pageData,
    this.controller,
    this.repository,
    this.style,
    this.showSurahHeader = true,
    this.showBasmalah = true,
    this.preserveMushafLineBreaks = false,
    this.isDark,
    this.loadingWidget,
    this.textDirection = TextDirection.rtl,
    this.sliceSpacing = 16,
    super.key,
  }) : startAyahIdGlobal = null,
       endAyahIdGlobal = null,
       ayahIds = null;

  /// Renders a global contiguous ayah id range, spanning pages when needed.
  const MushafPageRange.contiguous({
    required int startAyahId,
    required int endAyahId,
    this.controller,
    this.repository,
    this.style,
    this.showSurahHeader = true,
    this.showBasmalah = true,
    this.preserveMushafLineBreaks = false,
    this.isDark,
    this.loadingWidget,
    this.textDirection = TextDirection.rtl,
    this.sliceSpacing = 16,
    super.key,
  }) : page = null,
       startAyahId = null,
       endAyahId = null,
       startAyahIdGlobal = startAyahId,
       endAyahIdGlobal = endAyahId,
       pageData = null,
       ayahIds = null;

  /// Renders an explicit ordered list of ayah ids (grouped by page internally).
  const MushafPageRange.ayahIds({
    required List<int> ayahIds,
    this.controller,
    this.repository,
    this.style,
    this.showSurahHeader = true,
    this.showBasmalah = true,
    this.preserveMushafLineBreaks = false,
    this.isDark,
    this.loadingWidget,
    this.textDirection = TextDirection.rtl,
    this.sliceSpacing = 16,
    super.key,
  }) : page = null,
       startAyahId = null,
       endAyahId = null,
       startAyahIdGlobal = null,
       endAyahIdGlobal = null,
       pageData = null,
       ayahIds = ayahIds;

  /// Mushaf page number for [MushafPageRange.onPage].
  final int? page;

  /// Inclusive range start on [page] for [MushafPageRange.onPage].
  final int? startAyahId;

  /// Inclusive range end on [page] for [MushafPageRange.onPage].
  final int? endAyahId;

  /// Preloaded page model; skips async load for [MushafPageRange.onPage].
  final QuranPage? pageData;

  /// Global range start for [MushafPageRange.contiguous].
  final int? startAyahIdGlobal;

  /// Global range end for [MushafPageRange.contiguous].
  final int? endAyahIdGlobal;

  /// Explicit ayah ids for [MushafPageRange.ayahIds].
  final List<int>? ayahIds;

  /// Optional controller for repository access.
  final MushafReaderController? controller;

  /// Optional repository when no [controller] is provided.
  final IQuranRepository? repository;

  /// Mushaf styling.
  final MushafStyle? style;

  /// When `true`, surah headers may render per layout rules.
  final bool showSurahHeader;

  /// When `true`, basmalah lines may render per layout rules.
  final bool showBasmalah;

  /// When `true`, keeps mushaf line breaks even when a partial-page range
  /// would normally compact them.
  final bool preserveMushafLineBreaks;

  /// Surah banner SVG variant.
  ///
  /// When null, follows [Theme.of] brightness.
  final bool? isDark;

  /// Shown while page data is loading.
  final Widget? loadingWidget;

  /// Reading direction for the passage column.
  final TextDirection textDirection;

  /// Vertical gap between slices on cross-page selections.
  final double sliceSpacing;

  @override
  State<MushafPageRange> createState() => _MushafPageRangeState();
}

class _LoadedSlice {
  const _LoadedSlice({
    required this.pageNumber,
    required this.page,
    required this.ayahIds,
  });

  final int pageNumber;
  final QuranPage page;
  final List<int> ayahIds;
}

class _MushafPageRangeState extends State<MushafPageRange> {
  late IQuranRepository _repository;
  List<_LoadedSlice>? _slices;
  Object? _loadError;

  /// Drops stale async results when the selection changes mid-load.
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _repository = _resolveRepository();
    _loadSlices();
  }

  @override
  void didUpdateWidget(covariant MushafPageRange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.repository != oldWidget.repository) {
      _repository = _resolveRepository();
    }
    if (_selectionChanged(oldWidget)) {
      _loadSlices();
    } else if (widget.pageData != oldWidget.pageData && widget.pageData != null) {
      _applyPreloadedSinglePage();
    }
  }

  IQuranRepository _resolveRepository() {
    return widget.controller?.repository ??
        widget.repository ??
        HiveQuranRepository.instance;
  }

  bool _selectionChanged(MushafPageRange oldWidget) {
    return widget.page != oldWidget.page ||
        widget.startAyahId != oldWidget.startAyahId ||
        widget.endAyahId != oldWidget.endAyahId ||
        widget.startAyahIdGlobal != oldWidget.startAyahIdGlobal ||
        widget.endAyahIdGlobal != oldWidget.endAyahIdGlobal ||
        widget.ayahIds != oldWidget.ayahIds;
  }

  Future<void> _loadSlices() async {
    final generation = ++_loadGeneration;
    _loadError = null;
    _slices = null;
    if (mounted) setState(() {});

    try {
      final slices = await _resolveSlices();
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _slices = slices);
    } on Object catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loadError = error);
    }
  }

  void _applyPreloadedSinglePage() {
    if (widget.page == null || widget.pageData == null) return;
    final ids = _orderedAyahIdsForSinglePage(widget.pageData!);
    setState(
      () => _slices = [
        _LoadedSlice(
          pageNumber: widget.page!,
          page: widget.pageData!,
          ayahIds: ids,
        ),
      ],
    );
  }

  List<int> _orderedAyahIdsForSinglePage(QuranPage page) {
    if (widget.startAyahId != null && widget.endAyahId != null) {
      return MushafPageRangeLayout.contiguousIdsOnPage(
        page,
        startAyahId: widget.startAyahId!,
        endAyahId: widget.endAyahId!,
      );
    }
    return MushafPageRangeLayout.orderedAyahIdsOnPage(page);
  }

  Future<List<_LoadedSlice>> _resolveSlices() async {
    if (widget.page != null) {
      final pageNumber = widget.page!;
      final page =
          widget.pageData ??
          _repository.peekCachedPage(pageNumber) ??
          await _repository.getPage(pageNumber);
      final ayahIds = _orderedAyahIdsForSinglePage(page);
      return [
        _LoadedSlice(
          pageNumber: pageNumber,
          page: page,
          ayahIds: ayahIds,
        ),
      ];
    }

    final orderedIds = widget.ayahIds ??
        MushafPageRangeLayout.contiguousGlobalIds(
          startAyahId: widget.startAyahIdGlobal!,
          endAyahId: widget.endAyahIdGlobal!,
        );

    final resolved = await resolvePageRangeSlices(orderedIds, _repository);
    final loaded = <_LoadedSlice>[];
    for (final slice in resolved) {
      final page =
          _repository.peekCachedPage(slice.pageNumber) ??
          await _repository.getPage(slice.pageNumber);
      loaded.add(
        _LoadedSlice(
          pageNumber: slice.pageNumber,
          page: page,
          ayahIds: slice.ayahIds,
        ),
      );
    }
    return loaded;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return widget.loadingWidget ?? MushafLoading.none;
    }
    final slices = _slices;
    if (slices == null || slices.isEmpty) {
      return widget.loadingWidget ?? MushafLoading.none;
    }

    final style = widget.style ?? const MushafStyle();
    final scaleConfig = style.scale;

    return Directionality(
      textDirection: widget.textDirection,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : scaleConfig.referenceWidth;

          final children = <Widget>[];
          for (var i = 0; i < slices.length; i++) {
            final slice = slices[i];
            if (i > 0) {
              children.add(SizedBox(height: widget.sliceSpacing));
            }
            children.add(
              _buildSlice(
                context: context,
                slice: slice,
                style: style,
                availableWidth: availableWidth,
              ),
            );
          }

          final content = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );

          if (style.backgroundColor == null) {
            return content;
          }
          return ColoredBox(color: style.backgroundColor!, child: content);
        },
      ),
    );
  }

  Widget _buildSlice({
    required BuildContext context,
    required _LoadedSlice slice,
    required MushafStyle style,
    required double availableWidth,
  }) {
    final scaleConfig = style.scale;
    // Unbounded height → contain == width-fit; boost ≤ width-fit (no H-scroll).
    final scale = resolvePageScale(
      scaleConfig: scaleConfig,
      availableWidth: availableWidth,
      availableHeight: double.infinity,
    );

    final contentWidth = scaleConfig.referenceWidth * scale;
    final ayahFontSize = snapToDevicePixel(
      context,
      scaleConfig.getAyahFontSize(scale),
    );
    final basmalahFontSize = snapToDevicePixel(
      context,
      scaleConfig.getBasmalahFontSize(scale),
    );

    final ayahStyle = MushafTextStyleMerger.mergeAyahStyle(
      userStyle: style.ayahStyle,
      modifier: style.ayahStyleModifier,
      pageNumber: slice.pageNumber,
      baseSize: ayahFontSize,
    );

    return Center(
      child: SizedBox(
        width: contentWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...MushafPageSurahBlocks.build(
              data: slice.page,
              pageNumber: slice.pageNumber,
              width: contentWidth,
              scale: scale,
              defaultAyahStyle: ayahStyle,
              activeStyle: ayahStyle,
              mushafStyle: style,
              basmalahFontSize: basmalahFontSize,
              isDark: widget.isDark,
              selectedAyahIds: slice.ayahIds.toSet(),
              showSurahHeader: widget.showSurahHeader,
              showBasmalah: widget.showBasmalah,
              preserveMushafLineBreaks: widget.preserveMushafLineBreaks,
              addTrailingSpacer: false,
            ),
          ],
        ),
      ),
    );
  }
}
