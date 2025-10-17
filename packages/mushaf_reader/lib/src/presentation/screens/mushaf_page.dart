import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_ayah_widget.dart';

class MushafPage extends StatefulWidget {
  final int page;
  final bool enableHighlight;
  final MushafController? controller;
  final Widget? loadingWidget;
  final TextStyle? textStyle;
  final TextStyle? activeTextStyle;
  final TextStyle? surahNameTextStyle;
  final Function(int ayahId) onTapAyah;
  final Color highlightColor;

  const MushafPage({
    super.key,
    required this.page,
    this.controller,
    this.loadingWidget,
    this.textStyle,
    this.enableHighlight = true,
    required this.onTapAyah,
    this.activeTextStyle,
    this.surahNameTextStyle,
    this.highlightColor = const Color.fromARGB(202, 245, 205, 110),
  });

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  static const String _packageName = 'mushaf_reader';
  late MushafController _controller;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuranPageModel>(
      future: _controller.getPage(widget.page),
      builder: (_, snap) {
        if (!snap.hasData) {
          return widget.loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        final data = snap.data!;
        return _buildPageContent(data);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? MushafController.instance;
  }

  Widget _buildPageContent(QuranPageModel data) {
    // Get cached font family
    final pageFontFamily = PerformanceUtils.getFontFamilyForPage(widget.page);

    // Cache frequently used styles
    final defaultAyahStyle = PerformanceUtils.getCachedTextStyle(
      'default_${widget.page}',
      () => TextStyle(
        fontFamily: pageFontFamily,
        package: _packageName,
        fontSize: 28,
        height: 1.6,
        color: const Color(0xFF000000),
      ),
    );

    final headerNameStyle = PerformanceUtils.getCachedTextStyle(
      'header_name_${widget.page}',
      () => defaultAyahStyle.copyWith(fontSize: 18),
    );

    final juzStyle = PerformanceUtils.getCachedTextStyle(
      'juz_${widget.page}',
      () =>
          defaultAyahStyle.copyWith(fontSize: 36, fontWeight: FontWeight.bold),
    );

    final activeStyle =
        widget.activeTextStyle?.copyWith(
          fontFamily: pageFontFamily,
          package: _packageName,
        ) ??
        PerformanceUtils.getCachedTextStyle(
          'active_${widget.page}',
          () =>
              defaultAyahStyle.copyWith(backgroundColor: widget.highlightColor),
        );

    final finalTextStyle =
        widget.textStyle?.copyWith(
          fontFamily: pageFontFamily,
          package: _packageName,
        ) ??
        defaultAyahStyle;

    return Column(
      children: [
        // Header section
        SizedBox(
          width: 500,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SurahNameWidget(
                name: data.surahs[0].glyph,
                textStyle: headerNameStyle,
              ),
              JuzWidget(number: data.juzNumber, textStyle: juzStyle),
            ],
          ),
        ),
        const Spacer(),

        // Content sections
        ...data.surahs
            .map(
              (block) => [
                if (block.hasBasmalah) ...[
                  SurahHeaderWidget(
                    name: block.glyph,
                    textStyle: widget.surahNameTextStyle,
                  ),
                  const SizedBox(height: 8),
                ],
                if (block.hasBasmalah &&
                    block.surahNumber != 9 &&
                    block.surahNumber != 1)
                  const BasmalahWidget(),
                PageAyahWidget(
                  fullText: data.glyphText,
                  enableHighlight: widget.enableHighlight,
                  activeStyle: activeStyle,
                  onAyahSelection: widget.onTapAyah,
                  ayahs: block.ayahs,
                  style: finalTextStyle,
                ),
                const Spacer(),
              ],
            )
            .expand((widgets) => widgets),

        PageNumberWidget(page: widget.page),
      ],
    );
  }
}
