import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/data/models/ayah_info.dart';
import 'package:mushaf_reader/src/data/models/mushaf_page_info.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart';
import 'package:mushaf_reader/src/logic/mushaf_reader_controller.dart';
import 'package:mushaf_reader/src/presentation/screens/mushaf_page.dart';

/// A convenient widget for displaying a complete Mushaf reader with navigation.
///
/// This widget provides a ready-to-use Quran reader experience with:
/// - Page-by-page navigation via horizontal swiping
/// - Ayah tap and long-press handling with rich info
/// - Automatic controller management (or bring your own)
/// - Preloading of adjacent pages for smooth scrolling
///
/// ## Quick Start
///
/// ```dart
/// // Minimal setup - just add to your widget tree
/// MushafReader(
///   onAyahTap: (info) => print('Tapped ${info.reference}'),
/// )
/// ```
///
/// ## With Controller
///
/// For programmatic navigation and state access:
///
/// ```dart
/// class _MyReaderState extends State<MyReader> {
///   late final MushafReaderController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = MushafReaderController(initialPage: 1);
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         // Navigation header
///         Row(
///           children: [
///             IconButton(
///               icon: Icon(Icons.arrow_back),
///               onPressed: () => _controller.previousPage(),
///             ),
///             Text('Page ${_controller.currentPage}'),
///             IconButton(
///               icon: Icon(Icons.arrow_forward),
///               onPressed: () => _controller.nextPage(),
///             ),
///           ],
///         ),
///         // Reader
///         Expanded(
///           child: MushafReader(
///             controller: _controller,
///             onAyahTap: (info) => _showAyahDetails(info),
///             onAyahLongPress: (info) => _showContextMenu(info),
///           ),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// ## RTL Support
///
/// The Mushaf is read right-to-left. Set [reverse] to `true` (default) for
/// authentic reading experience where swiping left goes to the next page.
///
/// See also:
/// - [MushafReaderController], for programmatic control
/// - [MushafPage], for single-page display
/// - [AyahInfo], for tap callback info
/// - [MushafPageInfo], for current page info
class MushafReader extends StatefulWidget {
  /// The controller for managing navigation and state.
  ///
  /// If not provided, an internal controller is created and managed.
  final MushafReaderController? controller;

  /// The initial page to display (1-604).
  ///
  /// Only used when [controller] is not provided.
  final int initialPage;

  /// Whether to reverse page order for RTL reading.
  ///
  /// When `true` (default), swiping left goes to the next page,
  /// which matches the natural reading direction of Arabic text.
  final bool reverse;

  /// Callback invoked when an Ayah is tapped.
  ///
  /// Provides rich [AyahInfo] with surah, verse, page, and juz context.
  final void Function(AyahInfo info)? onAyahTap;

  /// Callback invoked when an Ayah is long-pressed.
  ///
  /// Provides rich [AyahInfo] for context menus, sharing, etc.
  final void Function(AyahInfo info)? onAyahLongPress;

  /// Callback invoked when the page changes.
  ///
  /// Provides the new [MushafPageInfo] with page metadata.
  final void Function(MushafPageInfo info)? onPageChanged;

  /// Callback invoked with just the page number on page change.
  ///
  /// Use this for simple page tracking without loading full info.
  final void Function(int page)? onPageNumberChanged;

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
    this.initialPage = 1,
    this.reverse = true,
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
  State<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends State<MushafReader> {
  late MushafReaderController _controller;
  bool _ownsController = false;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    return PageView.builder(
      controller: _controller.pageController,
      reverse: widget.reverse,
      clipBehavior: widget.clipBehavior,
      physics: widget.physics,
      itemCount: 604,
      onPageChanged: _onPageChanged,
      // children: List.generate(
      //   604,
      //   (index) => MushafPage(
      //     page: index + 1,
      //     style: widget.style,
      //     loadingWidget: widget.pageLoadingWidget,
      //     hideHeader: widget.hideHeader,
      //     onTapAyah: widget.onAyahTap != null
      //         ? (ayahId) => _handleAyahTap(ayahId)
      //         : null,
      //     onLongPressAyah: widget.onAyahLongPress != null
      //         ? (ayahId) => _handleAyahLongPress(ayahId)
      //         : null,
      //   ),
      // ),
      itemBuilder: (context, index) {
        final page = index + 1;
        return MushafPage(
          page: page,
          style: widget.style,
          loadingWidget: widget.pageLoadingWidget,
          hideHeader: widget.hideHeader,
          onTapAyah: widget.onAyahTap != null
              ? (ayahId) => _handleAyahTap(ayahId)
              : null,
          onLongPressAyah: widget.onAyahLongPress != null
              ? (ayahId) => _handleAyahLongPress(ayahId)
              : null,
        );
      },
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
      _isInitialized = _controller.isInitialized;
    } else {
      _controller = MushafReaderController(initialPage: widget.initialPage);
      _ownsController = true;
    }
    _controller.addListener(_onControllerChanged);
    _initController();
  }

  Future<void> _handleAyahLongPress(int ayahId) async {
    if (widget.onAyahLongPress == null) return;
    final info = await _controller.getAyahInfo(ayahId);
    widget.onAyahLongPress!(info);
  }

  Future<void> _handleAyahTap(int ayahId) async {
    if (widget.onAyahTap == null) return;
    final info = await _controller.getAyahInfo(ayahId);
    widget.onAyahTap!(info);
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
    final page = index + 1;
    _controller.onPageChanged(index);

    // Simple page number callback
    widget.onPageNumberChanged?.call(page);

    // Rich page info callback (async)
    if (widget.onPageChanged != null) {
      _controller.getPageInfo(page).then((info) {
        widget.onPageChanged?.call(info);
      });
    }

    // Preload adjacent pages
    _controller.preloadAdjacentPages(count: 2);
  }
}
