import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mushaf_reader/mushaf_reader.dart'
    show
        AyahTapCallback,
        AyahLongPressCallback,
        MushafConstants,
        MushafPageChangedCallback,
        MushafLoading,
        MushafPage,
        MushafReaderController,
        MushafScale,
        MushafStyle,
        MushafStyleCustomization,
        MushafTwoPageChangedCallback;

/// A convenient widget for displaying a complete Mushaf reader with navigation.
///
/// Supports single-page (`pagesPerViewport: 1`, default) or two-page spread
/// (`pagesPerViewport: 2`) layouts.
///
/// ## Desktop zoom
///
/// When [enablePointerZoom] is true (default):
/// - **Ctrl/⌘ + scroll** (mouse wheel or trackpad) zooms within
///   [MushafScale.minReadingBoost]–[MushafScale.maxReadingBoost]
/// - **Trackpad pinch** (when the platform emits scale pointer signals)
/// - **Ctrl/⌘ + / − / 0** zoom in, out, and reset session zoom
///
/// Zoom never exceeds width-fit (no horizontal scrolling). Larger than
/// contain-fit enables vertical scroll on the page.
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

  /// Enables Ctrl/⌘+scroll, pinch, and Ctrl/⌘+±/0 session zoom.
  ///
  /// Defaults to `true`. Disable when the host owns zoom exclusively.
  final bool enablePointerZoom;

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
    this.enablePointerZoom = true,
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

  /// True while the user is dragging or flinging the [PageView].
  ///
  /// [PageView.onPageChanged] also fires when the viewport is resized or
  /// re-attached after a layout change; those callbacks must not overwrite
  /// [MushafReaderController.currentPage].
  bool _userInteractingWithPageView = false;

  bool _syncScheduled = false;

  /// Accumulates trackpad [PointerScaleEvent] factors within one gesture.
  double _pinchBaseBoost = 1;

  bool get _isTwoPage => widget.pagesPerViewport == 2;

  MushafScale get _baseScale => (widget.style ?? const MushafStyle()).scale;

  /// Keeps only the visible page(s) and immediate neighbors alive in the
  /// [PageView] (current ±1) so scroll-back stays smooth without retaining
  /// every visited page for the session.
  bool _isPageInKeepAliveWindow(int page) {
    final anchor = _controller.currentPage;
    if (_isTwoPage) {
      final maxVisible = (anchor + 1).clamp(1, MushafConstants.pageCount);
      return page >= anchor - 1 && page <= maxVisible + 1;
    }
    return (page - anchor).abs() <= 1;
  }

  void _onControllerPageChanged() {
    if (mounted) setState(() {});
  }

  MushafStyle _styleWithSessionBoost() {
    final base = widget.style ?? const MushafStyle();
    final boost = _controller.effectiveReadingBoost(scale: base.scale);
    if (boost == base.scale.readingBoost &&
        _controller.sessionReadingBoost.value == null) {
      return base;
    }
    return base.modify(scale: base.scale.copyWith(readingBoost: boost));
  }

  bool get _zoomModifierPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
  }

  void _nudgeBoost(double delta) {
    _controller.nudgeReadingBoost(delta, scale: _baseScale);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (!widget.enablePointerZoom) return;

    if (event is PointerScaleEvent) {
      GestureBinding.instance.pointerSignalResolver.register(event, (event) {
        final scaleEvent = event as PointerScaleEvent;
        if (scaleEvent.scale == 1.0) {
          _pinchBaseBoost = _controller.effectiveReadingBoost(
            scale: _baseScale,
          );
        }
        final next = (_pinchBaseBoost * scaleEvent.scale).clamp(
          _baseScale.minReadingBoost,
          _baseScale.maxReadingBoost,
        );
        _controller.sessionReadingBoost.value = next;
      });
      return;
    }

    if (event is PointerScrollEvent && _zoomModifierPressed) {
      GestureBinding.instance.pointerSignalResolver.register(event, (event) {
        final scroll = event as PointerScrollEvent;
        final delta = (-scroll.scrollDelta.dy).clamp(-80.0, 80.0) * 0.0015;
        if (delta != 0) {
          _nudgeBoost(delta);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return widget.loadingWidget ?? MushafLoading.none;
    }

    Widget child = Directionality(
      textDirection: widget.textDirection,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: ListenableBuilder(
          listenable: _controller.sessionReadingBoost,
          builder: (context, _) {
            final style = _styleWithSessionBoost();
            return PageView.builder(
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
                  return _buildSpread(index, style);
                }
                return _buildSinglePage(index + 1, style);
              },
            );
          },
        ),
      ),
    );

    if (widget.enablePointerZoom) {
      child = Listener(
        onPointerSignal: _onPointerSignal,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.equal, control: true):
                () => _nudgeBoost(0.04),
            const SingleActivator(LogicalKeyboardKey.equal, meta: true):
                () => _nudgeBoost(0.04),
            const SingleActivator(LogicalKeyboardKey.add, control: true):
                () => _nudgeBoost(0.04),
            const SingleActivator(LogicalKeyboardKey.add, meta: true):
                () => _nudgeBoost(0.04),
            const SingleActivator(LogicalKeyboardKey.minus, control: true):
                () => _nudgeBoost(-0.04),
            const SingleActivator(LogicalKeyboardKey.minus, meta: true):
                () => _nudgeBoost(-0.04),
            const SingleActivator(LogicalKeyboardKey.digit0, control: true):
                _controller.resetSessionReadingBoost,
            const SingleActivator(LogicalKeyboardKey.digit0, meta: true):
                _controller.resetSessionReadingBoost,
            const SingleActivator(LogicalKeyboardKey.numpad0, control: true):
                _controller.resetSessionReadingBoost,
            const SingleActivator(LogicalKeyboardKey.numpad0, meta: true):
                _controller.resetSessionReadingBoost,
          },
          child: Focus(canRequestFocus: true, child: child),
        ),
      );
    }

    return child;
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
    final oldBoost = oldWidget.style?.scale.readingBoost;
    final newBoost = widget.style?.scale.readingBoost;
    if (oldBoost != newBoost) {
      _controller.resetSessionReadingBoost();
    }
  }

  @override
  void dispose() {
    _controller.page.removeListener(_onControllerPageChanged);
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
    _controller.page.addListener(_onControllerPageChanged);
    _initController();
  }

  Widget _buildSinglePage(int page, MushafStyle style) {
    return RepaintBoundary(
      child: MushafPage(
        key: ValueKey(page),
        page: page,
        controller: _controller,
        keepAlive: _isPageInKeepAliveWindow(page),
        style: style,
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

  Widget _buildSpread(int index, MushafStyle style) {
    final firstPage = index * 2 + 1;
    final secondPage = firstPage + 1;

    return Row(
      children: [
        Expanded(child: _buildSinglePage(firstPage, style)),
        Expanded(
          child: secondPage <= MushafConstants.pageCount
              ? _buildSinglePage(secondPage, style)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _handleAyahLongPress(int ayahId) async {
    if (widget.onAyahLongPress == null) return;
    final ayah = await _controller.getAyah(ayahId);
    if (!mounted) return;
    widget.onAyahLongPress!(ayah);
  }

  Future<void> _handleAyahTap(int ayahId) async {
    if (widget.onAyahTap == null) return;
    final ayah = await _controller.getAyah(ayahId);
    if (!mounted) return;
    widget.onAyahTap!(ayah);
  }

  Future<void> _initController() async {
    await _controller.ensureReady();
    if (!mounted) return;
    setState(() {
      _isInitialized = true;
    });
    _scheduleSyncPageViewToController();
    await _controller.loadCurrentPageInfo();
  }

  int _expectedViewportIndex() =>
      (_controller.currentPage - 1) ~/ widget.pagesPerViewport;

  void _scheduleSyncPageViewToController() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      _syncPageViewToController();
    });
  }

  void _syncPageViewToController() {
    final pageController = _controller.pageController;
    if (!pageController.hasClients) return;

    final expectedIndex = _expectedViewportIndex();
    final currentIndex = pageController.page?.round();
    if (currentIndex == expectedIndex) return;

    pageController.jumpToPage(expectedIndex);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;

    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        _userInteractingWithPageView = true;
      }
    } else if (notification is ScrollEndNotification) {
      _userInteractingWithPageView = false;
    }
    return false;
  }

  void _onPageChanged(int index) {
    final expectedIndex = _expectedViewportIndex();
    if (index != expectedIndex && !_userInteractingWithPageView) {
      _scheduleSyncPageViewToController();
      return;
    }

    _controller.onPageChanged(index);
    if (mounted) setState(() {});

    if (_isTwoPage) {
      final pages = _controller.currentPages;
      widget.onSpreadPageNumbersChanged?.call(pages);

      if (widget.onSpreadChanged != null) {
        _controller.getTwoPagesInfo(pages.$1).then((info) {
          if (!mounted) return;
          widget.onSpreadChanged?.call(info);
        });
      }
    } else {
      final page = index + 1;
      widget.onPageNumberChanged?.call(page);

      if (widget.onPageChanged != null) {
        _controller.getPageInfo(page).then((info) {
          if (!mounted) return;
          widget.onPageChanged?.call(info);
        });
      }
    }

    _controller.preloadAdjacentPages();
  }
}
