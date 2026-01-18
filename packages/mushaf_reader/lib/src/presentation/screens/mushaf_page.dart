import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/core/extensions.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_ayah_widget.dart';

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
/// Before using this widget, ensure the repository is initialized.
/// If using [MushafReaderController], call:
///
/// ```dart
/// await controller.ensureReady();
/// ```
///
/// ## Basic Usage
///
/// ```dart
/// MushafPage(
///   page: 1,
///   onTapAyah: (ayahId) {
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
/// await controller.ensureReady();
///
/// MushafPage(
///   page: 1,
///   controller: controller,
/// )
///
/// // Later, highlight an ayah programmatically
/// controller.selectAyah(7);
/// ```
///
/// ## In a PageView (prefer MushafReader widget)
///
/// ```dart
/// MushafReader(
///   controller: controller,
///   onTapAyah: (Ayah) => print('Tapped: ${Ayah.reference}'),
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
  /// Defaults to a centered [CircularProgressIndicator].
  final Widget? loadingWidget;

  /// Callback invoked when an Ayah is tapped.
  ///
  /// The callback receives the global Ayah ID (1-6236).
  /// Use this to show Ayah details, play audio, etc.
  final Function(int ayahId)? onTapAyah;

  /// Callback invoked when an Ayah is long-pressed.
  ///
  /// The callback receives the global Ayah ID (1-6236).
  /// Use this to show context menus, share options, etc.
  final Function(int ayahId)? onLongPressAyah;

  /// Styling options for the page.
  ///
  /// Controls highlight colors, scaling, and other visual aspects.
  /// See [MushafStyle] and [MushafScale] for configuration options.
  final MushafStyle? style;

  /// Callback invoked when a Surah header banner is tapped.
  ///
  /// Receives the Surah number (1-114).
  final void Function(int surahNumber)? onTapSurahHeader;

  /// Callback invoked when a Surah header banner is long-pressed.
  ///
  /// Receives the Surah number (1-114).
  final void Function(int surahNumber)? onLongPressSurahHeader;

  /// Callback invoked when a Surah name (in page header) is tapped.
  ///
  /// Receives the Surah number (1-114).
  final void Function(int surahNumber)? onTapSurahName;

  /// Callback invoked when a Surah name (in page header) is long-pressed.
  ///
  /// Receives the Surah number (1-114).
  final void Function(int surahNumber)? onLongPressSurahName;

  /// Callback invoked when the Juz indicator is tapped.
  ///
  /// Receives the Juz number (1-30).
  final void Function(int juzNumber)? onTapJuz;

  /// Callback invoked when the Juz indicator is long-pressed.
  ///
  /// Receives the Juz number (1-30).
  final void Function(int juzNumber)? onLongPressJuz;

  /// Whether to hide the page header (surah name, page number, juz indicator).
  final bool? hideHeader;

  /// Creates a MushafPage widget.
  ///
  /// [page] is required and must be in the range 1-604.
  const MushafPage({
    super.key,
    required this.page,
    this.controller,
    this.loadingWidget,
    this.onTapAyah,
    this.style,
    this.onTapSurahHeader,
    this.onLongPressSurahHeader,
    this.onTapSurahName,
    this.onLongPressSurahName,
    this.onTapJuz,
    this.onLongPressJuz,
    this.onLongPressAyah,
    this.hideHeader,
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

  // State for data loading
  QuranPage? _pageData;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true; // Keep page alive in PageView

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Show loading if data not loaded
    if (_isLoading || _pageData == null) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    // If using a controller, listen to its changes
    if (_controller != null) {
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

    if (widget.page != oldWidget.page) {
      // Page changed, reload data
      _pageData = null;
      _isLoading = true;
      _loadPageData();
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
    _loadPageData();
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

        // Calculate scale using the config
        var scale = scaleConfig.scaleForWidth(availableWidth);

        // Constrain by height if needed (for aspect ratio preservation)
        if (availableHeight.isFinite) {
          final heightScale = availableHeight / 850.0; // Reference height
          scale = scale.clamp(scaleConfig.minScale, heightScale);
        }

        final contentWidth = scaleConfig.referenceWidth * scale;
        final fontFamily = MushafFonts.forPage(widget.page);

        // Get scaled font sizes
        final ayahFontSize = scaleConfig.getAyahFontSize(scale);
        final basmalahFontSize = scaleConfig.getBasmalahFontSize(scale);
        final pageNumberFontSize = scaleConfig.getPageNumberFontSize(scale);

        // Use MushafTextStyleMerger to properly merge user styles with enforced font settings
        final defaultAyahStyle = MushafTextStyleMerger.mergeAyahStyle(
          userStyle: style.ayahStyle,
          modifier: style.ayahStyleModifier,
          pageNumber: widget.page,
          baseSize: ayahFontSize,
          scaleFactor: 1.0, // Already scaled via scaleConfig
        );

        final activeStyle =
            style.activeAyahStyle != null ||
                style.activeAyahStyleModifier != null
            ? MushafTextStyleMerger.mergeAyahStyle(
                userStyle: style.activeAyahStyle,
                modifier: style.activeAyahStyleModifier,
                pageNumber: widget.page,
                baseSize: style.activeAyahStyle?.fontSize ?? ayahFontSize,
                scaleFactor: style.activeAyahStyle?.fontSize != null
                    ? scale
                    : 1.0,
              )
            : defaultAyahStyle.copyWith(backgroundColor: style.highlightColor);

        return Center(
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
                  fontFamily,
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
      },
    );
  }

  /// Builds all Surah blocks with headers, Basmalah, and Ayah text.
  Iterable<Widget> _buildSurahBlocks(
    QuranPage data,
    double width,
    double scale,
    String fontFamily,
    TextStyle defaultAyahStyle,
    TextStyle activeStyle,
    MushafStyle mushafStyle,
    double basmalahFontSize,
  ) {
    return data.surahs.expand(
      (block) => [
        // Show header when this block starts a new surah (first ayah is verse 1)
        if (block.hasBasmalah) ...[
          SurahHeaderWidget(
            surahData: block.toSurah(),
            width: width,
            fontSize: basmalahFontSize,
            textStyle:
                mushafStyle.headerSurahNameStyle ?? mushafStyle.surahNameStyle,
            styleModifier:
                mushafStyle.headerSurahNameStyleModifier ??
                mushafStyle.surahNameStyleModifier,
            customHeaderImage: mushafStyle.surahHeaderImage,
            onTap: widget.onTapSurahHeader,
            onLongPress: widget.onLongPressSurahHeader,
          ),
          SizedBox(height: 4 * scale),
          // Show basmalah for all surahs except Al-Fatiha (1) and At-Tawbah (9)
          if (block.surahNumber != 9 && block.surahNumber != 1)
            BasmalahWidget(
              fontSize: basmalahFontSize,
              textStyle: mushafStyle.basmalahStyle,
              styleModifier: mushafStyle.basmalahStyleModifier,
            ),
        ],
        PageAyahWidget(
          fullText: data.glyphText,
          enableHighlight: true,
          activeStyle: activeStyle,
          selectedAyahId: _controller?.selectedAyahId ?? _selectedAyahId,
          ayahs: block.ayahs,
          style: defaultAyahStyle,
          onAyahSelection: (ayahId) {
            final currentSelection =
                _controller?.selectedAyahId ?? _selectedAyahId;
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
            widget.onTapAyah?.call(ayahId);
          },
          onAyahLongPress: widget.onLongPressAyah,
        ),
        if (data.surahs.last == block) const Spacer(),
      ],
    );
  }

  /// Loads page data asynchronously from the repository.
  Future<void> _loadPageData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getPage(widget.page);
      if (mounted) {
        setState(() {
          _pageData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading page ${widget.page}: $e');
    }
  }
}
