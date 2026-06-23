import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart'
    show
        AyahTapCallback,
        AyahLongPressCallback,
        MushafConstants,
        MushafPageChangedCallback,
        MushafLoading,
        MushafPage,
        MushafReaderController,
        MushafStyle,
        MushafTwoPageChangedCallback;

/// A convenient widget for displaying a complete Mushaf reader with navigation.
///
/// Supports single-page (`pagesPerViewport: 1`, default) or two-page spread
/// (`pagesPerViewport: 2`) layouts.
///
/// ## Quick Start
///
/// ```dart
/// MushafReader(
///   onAyahTap: (ayah) => print('Tapped ${ayah.reference}'),
/// )
/// ```
///
/// ## Two-page spread
///
/// ```dart
/// MushafReader(
///   pagesPerViewport: 2,
///   onAyahTap: (ayah) => print(ayah.reference),
///   onSpreadChanged: (info) => print(info.$1.pageNumber),
/// )
/// ```
///
/// See also:
/// - [MushafReaderController], for programmatic control
/// - [MushafPage], for single-page display
class MushafReader extends StatefulWidget {
  /// The controller for managing navigation and state.
  ///
  /// If not provided, an internal controller is created and managed.
  final MushafReaderController? controller;

  /// Mushaf pages shown per viewport: `1` (default) or `2`.
  final int pagesPerViewport;

  /// The initial page to display (1-604).
  ///
  /// Only used when [controller] is not provided.
  final int initialPage;

  /// Whether to reverse page order within the [textDirection].
  final bool reverse;

  /// The reading direction for the Mushaf.
  ///
  /// Defaults to [TextDirection.rtl].
  final TextDirection textDirection;

  /// Callback invoked when an Ayah is tapped.
  final AyahTapCallback? onAyahTap;

  /// Callback invoked when an Ayah is long-pressed.
  final AyahLongPressCallback? onAyahLongPress;

  /// Invoked when the visible page changes (single-page mode only).
  final MushafPageChangedCallback? onPageChanged;

  /// Invoked with the page number on change (single-page mode only).
  final void Function(int page)? onPageNumberChanged;

  /// Invoked when the visible spread changes (two-page mode only).
  final MushafTwoPageChangedCallback? onSpreadChanged;

  /// Invoked with spread page numbers on change (two-page mode only).
  final void Function((int, int) pages)? onSpreadPageNumbersChanged;

  /// Styling options for the pages.
  final MushafStyle? style;

  /// Widget to show while the reader is initializing.
  final Widget? loadingWidget;

  /// Widget to show while individual pages are loading.
  final Widget? pageLoadingWidget;

  /// Whether to hide the header (surah name, page number).
  final bool hideHeader;

  /// How to clip the page content.
  final Clip clipBehavior;

  /// Scroll physics for the page view.
  final ScrollPhysics? physics;

  /// Creates a MushafReader widget.
  const MushafReader({
    super.key,
    this.controller,
    this.pagesPerViewport = 1,
    this.initialPage = 1,
    this.reverse = false,
    this.textDirection = TextDirection.rtl,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onPageChanged,
    this.onPageNumberChanged,
    this.onSpreadChanged,
    this.onSpreadPageNumbersChanged,
    this.style,
    this.loadingWidget,
    this.pageLoadingWidget,
    this.hideHeader = false,
    this.clipBehavior = Clip.hardEdge,
    this.physics,
  }) : assert(
         pagesPerViewport == 1 || pagesPerViewport == 2,
         'pagesPerViewport must be 1 or 2',
       );

  @override
  State<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends State<MushafReader> {
  late MushafReaderController _controller;
  bool _ownsController = false;
  bool _isInitialized = false;

  bool get _isTwoPage => widget.pagesPerViewport == 2;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return widget.loadingWidget ?? MushafLoading.none;
    }

    return Directionality(
      textDirection: widget.textDirection,
      child: PageView.builder(
        controller: _controller.pageController,
        reverse: widget.reverse,
        clipBehavior: widget.clipBehavior,
        physics: widget.physics,
        itemCount: _isTwoPage
            ? MushafConstants.twoPageSpreadCount
            : MushafConstants.pageCount,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          if (_isTwoPage) {
            return _buildSpread(index);
          }
          return _buildSinglePage(index + 1);
        },
      ),
    );
  }

  @override
  void didUpdateWidget(MushafReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null &&
        widget.pagesPerViewport != oldWidget.pagesPerViewport) {
      _controller.pagesPerViewport = widget.pagesPerViewport;
      if (_isInitialized) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _controller.pagesPerViewport = widget.pagesPerViewport;
      _isInitialized = _controller.isInitialized;
    } else {
      _controller = MushafReaderController(
        initialPage: widget.initialPage,
        pagesPerViewport: widget.pagesPerViewport,
      );
      _ownsController = true;
    }
    _initController();
  }

  Widget _buildSinglePage(int page) {
    return RepaintBoundary(
      child: MushafPage(
        key: ValueKey(page),
        page: page,
        controller: _controller,
        style: widget.style,
        loadingWidget: widget.pageLoadingWidget,
        hideHeader: widget.hideHeader,
        onAyahIdTap: widget.onAyahTap != null
            ? (ayahId) => _handleAyahTap(ayahId)
            : null,
        onAyahIdLongPress: widget.onAyahLongPress != null
            ? (ayahId) => _handleAyahLongPress(ayahId)
            : null,
      ),
    );
  }

  Widget _buildSpread(int index) {
    final firstPage = index * 2 + 1;
    final secondPage = firstPage + 1;

    return Row(
      children: [
        Expanded(child: _buildSinglePage(firstPage)),
        Expanded(
          child: secondPage <= MushafConstants.pageCount
              ? _buildSinglePage(secondPage)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _handleAyahLongPress(int ayahId) async {
    if (widget.onAyahLongPress == null) return;
    final ayah = await _controller.getAyah(ayahId);
    widget.onAyahLongPress!(ayah);
  }

  Future<void> _handleAyahTap(int ayahId) async {
    if (widget.onAyahTap == null) return;
    final ayah = await _controller.getAyah(ayahId);
    widget.onAyahTap!(ayah);
  }

  Future<void> _initController() async {
    await _controller.ensureReady();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      await _controller.loadCurrentPageInfo();
    }
  }

  void _onPageChanged(int index) {
    _controller.onPageChanged(index);

    if (_isTwoPage) {
      final pages = _controller.currentPages;
      widget.onSpreadPageNumbersChanged?.call(pages);

      if (widget.onSpreadChanged != null) {
        _controller.getTwoPagesInfo(pages.$1).then((info) {
          widget.onSpreadChanged?.call(info);
        });
      }
    } else {
      final page = index + 1;
      widget.onPageNumberChanged?.call(page);

      if (widget.onPageChanged != null) {
        _controller.getPageInfo(page).then((info) {
          widget.onPageChanged?.call(info);
        });
      }
    }

    _controller.preloadAdjacentPages();
  }
}
