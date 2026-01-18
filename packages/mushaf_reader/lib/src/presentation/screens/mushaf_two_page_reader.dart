import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/data/models/ayah.dart';
import 'package:mushaf_reader/src/data/models/mushaf_page_info.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart';
import 'package:mushaf_reader/src/logic/mushaf_reader_controller.dart';
import 'package:mushaf_reader/src/presentation/screens/mushaf_page.dart';

/// A widget for displaying a complete Mushaf reader with 2 pages side-by-side.
///
/// This provides a book-like experience, suitable for landscape or tablets.
class MushafTwoPageReader extends StatefulWidget {
  /// The controller for managing navigation and state.
  ///
  /// If not provided, an internal controller is created and managed.
  final MushafReaderController? controller;

  /// The initial page to display (1-604).
  ///
  /// Only used when [controller] is not provided.
  final int initialPage;

  /// Whether to reverse page order within the [textDirection].
  ///
  /// Defaults to `false`.
  final bool reverse;

  /// The reading direction for the Mushaf.
  ///
  /// Defaults to [TextDirection.rtl], which matches the natural reading
  /// direction of Arabic text (swiping right goes to the next spread).
  final TextDirection textDirection;

  /// Callback invoked when an Ayah is tapped.
  final void Function(Ayah ayah)? onAyahTap;

  /// Callback invoked when an Ayah is long-pressed.
  final void Function(Ayah ayah)? onAyahLongPress;

  /// Callback invoked when the page changes.
  ///
  /// Provides the new page info for both pages.
  final void Function((MushafPageInfo, MushafPageInfo?) info)? onPageChanged;

  /// Callback invoked with page numbers on page change.
  final void Function((int, int) pages)? onPageNumberChanged;

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

  /// Creates a MushafTwoPageReader widget.
  const MushafTwoPageReader({
    super.key,
    this.controller,
    this.initialPage = 1,
    this.reverse = false,
    this.textDirection = TextDirection.rtl,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onPageChanged,
    this.onPageNumberChanged,
    this.style,
    this.loadingWidget,
    this.pageLoadingWidget,
    this.hideHeader = false,
    this.clipBehavior = Clip.hardEdge,
    this.physics,
  });

  @override
  State<MushafTwoPageReader> createState() => _MushafTwoPageReaderState();
}

class _MushafTwoPageReaderState extends State<MushafTwoPageReader> {
  late MushafReaderController _controller;
  bool _ownsController = false;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    return Directionality(
      textDirection: widget.textDirection,
      child: PageView.builder(
        controller: _controller.pageController,
        reverse: widget.reverse,
        clipBehavior: widget.clipBehavior,
        physics: widget.physics,
        // 604 pages / 2 = 302 spreads
        itemCount: 302,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          // Index 0 -> Pages 1, 2
          final firstPage = index * 2 + 1;
          final secondPage = firstPage + 1;

          return Row(
            children: [
              // Right Page (Odd in RTL, Left in LTR)
              Expanded(
                child: MushafPage(
                  page: firstPage,
                  controller: _controller,
                  style: widget.style,
                  loadingWidget: widget.pageLoadingWidget,
                  hideHeader: widget.hideHeader,
                  onTapAyah: widget.onAyahTap != null
                      ? (ayahId) => _handleAyahTap(ayahId)
                      : null,
                  onLongPressAyah: widget.onAyahLongPress != null
                      ? (ayahId) => _handleAyahLongPress(ayahId)
                      : null,
                ),
              ),
              // Separator? (Book spine?)

              // Left Page (Even in RTL, Right in LTR)
              Expanded(
                child: secondPage <= 604
                    ? MushafPage(
                        page: secondPage,
                        controller: _controller,
                        style: widget.style,
                        loadingWidget: widget.pageLoadingWidget,
                        hideHeader: widget.hideHeader,
                        onTapAyah: widget.onAyahTap != null
                            ? (ayahId) => _handleAyahTap(ayahId)
                            : null,
                        onLongPressAyah: widget.onAyahLongPress != null
                            ? (ayahId) => _handleAyahLongPress(ayahId)
                            : null,
                      )
                    : Container(), // End of book
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
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
      // Ensure controller is configured for 2-page mode
      _controller.pagesPerViewport = 2;
      _isInitialized = _controller.isInitialized;
    } else {
      _controller = MushafReaderController(
        initialPage: widget.initialPage,
        pagesPerViewport: 2,
      );
      _ownsController = true;
    }
    _controller.addListener(_onControllerChanged);
    _initController();
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
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      // Load initial page info
      await _controller.loadCurrentPageInfo();
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onPageChanged(int index) {
    // index is viewport index (0..301)
    _controller.onPageChanged(index);

    final pages = _controller.currentPages;
    widget.onPageNumberChanged?.call(pages);

    if (widget.onPageChanged != null) {
      final page = pages.$1;
      _controller.getTwoPagesInfo(page).then((info) {
        widget.onPageChanged?.call(info);
      });
    }

    // Preload adjacent pages
    _controller.preloadAdjacentPages(count: 2);
  }
}
