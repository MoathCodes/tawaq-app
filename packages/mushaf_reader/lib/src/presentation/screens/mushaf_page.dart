import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/core/extensions.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';
import 'package:mushaf_reader/src/presentation/mushaf_loading.dart';
import 'package:mushaf_reader/src/core/mushaf_layout.dart';
import 'package:mushaf_reader/src/presentation/widgets/mushaf_page_surah_blocks.dart';

/// A widget that displays a single page of the Mushaf (Quran).
///
/// This widget renders a complete Quran page with:
/// - Surah headers with decorative banners
/// - Basmalah (when appropriate)
/// - Ayah text with highlighting support
/// - Page number
/// - Juz indicator
///
/// ## Prerequisites
///
/// Call [MushafReaderLibrary.ensureInitialized] once before building this
/// widget (typically in `main()`).
///
/// ## Basic Usage
///
/// ```dart
/// MushafPage(
///   page: 1,
///   onAyahIdTap: (ayahId) {
///     print('Tapped ayah: $ayahId');
///   },
/// )
/// ```
///
/// ## With Custom Styling
///
/// ```dart
/// MushafPage(
///   page: 1,
///   style: MushafStyle(
///     highlightColor: Colors.amber.withOpacity(0.3),
///     backgroundColor: Color(0xFFFFFBF0),
///   ),
/// )
/// ```
///
/// ## With External Controller
///
/// ```dart
/// final controller = MushafReaderController();
///
/// MushafPage(
///   page: 1,
///   controller: controller,
/// )
///
/// // Highlight an ayah programmatically
/// controller.selectAyah(7);
/// ```
///
/// ## In a PageView (prefer MushafReader widget)
///
/// ```dart
/// MushafReader(
///   controller: controller,
///   onAyahTap: (ayah) => print('Tapped: ${ayah.reference}'),
/// )
/// ```
///
/// ## Layout
///
/// The widget uses a reference size of 500x850 and scales to fit the
/// available space while maintaining aspect ratio. It's designed to
/// work well in portrait mode on mobile devices.
///
/// See also:
/// - [MushafReaderController], for navigation and data access
/// - [MushafStyle], for customizing appearance
/// - [MushafReader], convenience widget with PageView navigation
class MushafPage extends StatefulWidget {
  /// The page number to display (1-604).
  final int page;

  /// The unified controller for data access and selection state.
  ///
  /// If not provided, an internal repository is used for data access
  /// and selection state is managed internally.
  final MushafReaderController? controller;

  /// Widget to show while the page is loading.
  ///
  /// Defaults to [MushafLoading.none] (no built-in spinner).
  ///
  /// Host apps should pass their own indicator, e.g. Forui's
  /// `FCircularProgress.loader()`.
  final Widget? loadingWidget;

  /// Callback invoked when an Ayah is tapped.
  ///
  /// Receives the global ayah id (1–6236). For a full [Ayah] model, use
  /// [MushafReader.onAyahTap] or fetch via [MushafReaderController.getAyah].
  final AyahIdTapCallback? onAyahIdTap;

  /// Callback invoked when an Ayah is long-pressed.
  final AyahIdLongPressCallback? onAyahIdLongPress;

  /// Styling options for the page.
  ///
  /// Controls highlight colors, scaling, and other visual aspects.
  /// See [MushafStyle] and [MushafScale] for configuration options.
  final MushafStyle? style;

  /// Callback invoked when a Surah header banner is tapped.
  ///
  /// Receives the Surah number (1-114).
  final SurahTapCallback? onTapSurahHeader;

  /// Callback invoked when a Surah header banner is long-pressed.
  final SurahTapCallback? onLongPressSurahHeader;

  /// Callback invoked when a Surah name (in page header) is tapped.
  final SurahTapCallback? onTapSurahName;

  /// Callback invoked when a Surah name (in page header) is long-pressed.
  final SurahTapCallback? onLongPressSurahName;

  /// Callback invoked when the Juz indicator is tapped.
  final JuzTapCallback? onTapJuz;

  /// Callback invoked when the Juz indicator is long-pressed.
  final JuzTapCallback? onLongPressJuz;

  /// Whether to hide the page header (surah name, page number, juz indicator).
  final bool? hideHeader;

  /// Whether ayahs can be tapped, selected, and visually highlighted.
  ///
  /// When `false`, ayah text is read-only (no tap targets or selection styling).
  /// Defaults to `true`.
  final bool enableAyahHighlight;

  /// Creates a MushafPage widget.
  ///
  /// [page] is required and must be in the range 1-604.
  const MushafPage({
    super.key,
    required this.page,
    this.controller,
    this.loadingWidget,
    this.onAyahIdTap,
    this.onAyahIdLongPress,
    this.style,
    this.onTapSurahHeader,
    this.onLongPressSurahHeader,
    this.onTapSurahName,
    this.onLongPressSurahName,
    this.onTapJuz,
    this.onLongPressJuz,
    this.hideHeader,
    this.enableAyahHighlight = true,
  });

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage>
    with AutomaticKeepAliveClientMixin {
  late IQuranRepository _repository;
  MushafReaderController? _controller;

  /// Tracks which ayah is currently selected for highlighting
  int? _selectedAyahId;

  QuranPage? _pageData;

  final PageScaleCache _pageScaleCache = PageScaleCache();

  @override
  bool get wantKeepAlive => true; // Keep page alive in PageView

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_pageData == null) {
      return widget.loadingWidget ?? MushafLoading.none;
    }

    if (_controller != null && widget.enableAyahHighlight) {
      return ListenableBuilder(
        listenable: _controller!,
        builder: (context, child) {
          return _buildPageContent(_pageData!);
        },
      );
    }

    // Otherwise just build the content
    return _buildPageContent(_pageData!);
  }

  @override
  void didUpdateWidget(MushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller;
      if (_controller != null) {
        _repository = _controller!.repository;
      }
    }

    if (widget.page != oldWidget.page || widget.style != oldWidget.style) {
      _pageScaleCache.clear();
    }

    if (widget.page != oldWidget.page) {
      _pageData = _repository.peekCachedPage(widget.page);
      if (_pageData == null) {
        _loadPageData();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _repository = _controller?.repository ?? HiveQuranRepository();
    _pageData = _repository.peekCachedPage(widget.page);
    if (_pageData == null) {
      _loadPageData();
    }
  }

  /// Builds the page header with Surah name and Juz indicator.
  Widget _buildHeader(
    QuranPage data,
    double width,
    double fontSize,
    MushafStyle style,
  ) {
    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (data.surahs.isNotEmpty)
            SurahNameWidget(
              surahData: data.surahs.first.toSurah(),
              fontSize: fontSize,
              textStyle: style.surahNameStyle,
              styleModifier: style.surahNameStyleModifier,
              onTap: widget.onTapSurahName,
              onLongPress: widget.onLongPressSurahName,
            ),
          JuzWidget(
            number: data.juzNumber,
            fontSize: fontSize + 20,
            textStyle: style.juzStyle,
            styleModifier: style.juzStyleModifier,
            onTap: widget.onTapJuz,
            onLongPress: widget.onLongPressJuz,
          ),
        ],
      ),
    );
  }

  /// Builds the complete page content with responsive scaling.
  Widget _buildPageContent(QuranPage data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = widget.style ?? const MushafStyle();
        final scaleConfig = style.scale;

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : scaleConfig.referenceWidth;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : double.infinity;

        final scale = _pageScaleCache.resolve(
          context: context,
          scaleConfig: scaleConfig,
          page: data,
          availableWidth: availableWidth,
          availableHeight: availableHeight,
          hideHeader: widget.hideHeader == true,
          pageNumber: widget.page,
          style: style,
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
        final pageNumberFontSize = snapToDevicePixel(
          context,
          scaleConfig.getPageNumberFontSize(scale),
        );

        final defaultAyahStyle = MushafTextStyleMerger.mergeAyahStyle(
          userStyle: style.ayahStyle,
          modifier: style.ayahStyleModifier,
          pageNumber: widget.page,
          baseSize: ayahFontSize,
          scaleFactor: 1.0,
        );

        final activeStyle =
            style.activeAyahStyle != null ||
                style.activeAyahStyleModifier != null
            ? MushafTextStyleMerger.mergeAyahStyle(
                userStyle: style.activeAyahStyle,
                modifier: style.activeAyahStyleModifier,
                pageNumber: widget.page,
                baseSize: ayahFontSize,
                scaleFactor: 1.0,
              )
            : defaultAyahStyle.copyWith(backgroundColor: style.highlightColor);

        final pageContent = Center(
          child: SizedBox(
            width: contentWidth,
            height: availableHeight.isFinite ? availableHeight : null,
            child: Column(
              children: [
                if (widget.hideHeader != true)
                  _buildHeader(data, contentWidth, basmalahFontSize, style),
                const Spacer(),
                ..._buildSurahBlocks(
                  data,
                  contentWidth,
                  scale,
                  defaultAyahStyle,
                  activeStyle,
                  style,
                  basmalahFontSize,
                ),
                PageNumberWidget(
                  page: widget.page,
                  fontSize: pageNumberFontSize,
                  textStyle: style.pageNumberStyle,
                  styleModifier: style.pageNumberStyleModifier,
                ),
              ],
            ),
          ),
        );

        if (style.backgroundColor == null) {
          return pageContent;
        }

        return ColoredBox(
          color: style.backgroundColor!,
          child: pageContent,
        );
      },
    );
  }

  /// Builds all Surah blocks with headers, Basmalah, and Ayah text.
  Iterable<Widget> _buildSurahBlocks(
    QuranPage data,
    double width,
    double scale,
    TextStyle defaultAyahStyle,
    TextStyle activeStyle,
    MushafStyle mushafStyle,
    double basmalahFontSize,
  ) {
    return MushafPageSurahBlocks.build(
      data: data,
      pageNumber: widget.page,
      width: width,
      scale: scale,
      defaultAyahStyle: defaultAyahStyle,
      activeStyle: activeStyle,
      mushafStyle: mushafStyle,
      basmalahFontSize: basmalahFontSize,
      enableAyahHighlight: widget.enableAyahHighlight,
      selectedAyahId: widget.enableAyahHighlight
          ? (_controller?.selectedAyahId ?? _selectedAyahId)
          : null,
      onAyahSelection: (ayahId) {
        if (!widget.enableAyahHighlight) return;
        final currentSelection = _controller?.selectedAyahId ?? _selectedAyahId;
        if (currentSelection == ayahId) {
          if (_controller != null) {
            _controller!.clearSelection();
          } else {
            setState(() => _selectedAyahId = null);
          }
        } else {
          if (_controller != null) {
            _controller!.selectAyah(ayahId);
          } else {
            setState(() => _selectedAyahId = ayahId);
          }
        }
        widget.onAyahIdTap?.call(ayahId);
      },
      onAyahLongPress: widget.enableAyahHighlight
          ? widget.onAyahIdLongPress
          : null,
      onTapSurahHeader: widget.onTapSurahHeader,
      onLongPressSurahHeader: widget.onLongPressSurahHeader,
    );
  }

  Future<void> _loadPageData() async {
    final cached = _repository.peekCachedPage(widget.page);
    if (cached != null) {
      if (mounted) setState(() => _pageData = cached);
      return;
    }

    try {
      final data = await _repository.getPage(widget.page);
      if (mounted) setState(() => _pageData = data);
    } catch (e) {
      debugPrint('Error loading page ${widget.page}: $e');
    }
  }
}
