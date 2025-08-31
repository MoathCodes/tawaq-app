import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_ayah_widget.dart';

class MushafPage extends StatelessWidget {
  final int page;
  final bool enableHighlight;
  final Widget? loadingWidget;
  final TextStyle? textStyle;
  final TextStyle? activeTextStyle;
  final TextStyle? surahNameTextStyle;
  final Function(int ayahId) onTapAyah;
  final Color highlightColor;

  const MushafPage({
    super.key,
    required this.page,
    this.loadingWidget,
    this.textStyle,
    this.enableHighlight = true,
    required this.onTapAyah,
    this.activeTextStyle,
    this.surahNameTextStyle,
    this.highlightColor = const Color.fromARGB(202, 245, 205, 110),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuranPageModel>(
      future: MushafController.instance.getPage(page),
      builder: (_, snap) {
        if (!snap.hasData) {
          return loadingWidget ?? const Center(child: Text('Loading'));
        }

        final data = snap.data!;
        return _buildPageContent(data);
      },
    );
  }

  Widget _buildPageContent(QuranPageModel data) {
    // Get cached font family
    final pageFontFamily = PerformanceUtils.getFontFamilyForPage(page);

    // Cache frequently used styles
    final defaultAyahStyle = PerformanceUtils.getCachedTextStyle(
      'default_$page',
      () => TextStyle(
        fontFamily: pageFontFamily,
        package: 'mushaf_reader',
        fontSize: 28,
        height: 1.6,
        color: const Color(0xFF000000),
      ),
    );

    final headerNameStyle = PerformanceUtils.getCachedTextStyle(
      'header_name_$page',
      () => defaultAyahStyle.copyWith(fontSize: 18),
    );

    final juzStyle = PerformanceUtils.getCachedTextStyle(
      'juz_$page',
      () =>
          defaultAyahStyle.copyWith(fontSize: 36, fontWeight: FontWeight.bold),
    );

    final activeStyle =
        activeTextStyle?.copyWith(fontFamily: pageFontFamily) ??
        PerformanceUtils.getCachedTextStyle(
          'active_$page',
          () => defaultAyahStyle.copyWith(backgroundColor: highlightColor),
        );

    final finalTextStyle =
        textStyle?.copyWith(fontFamily: pageFontFamily) ?? defaultAyahStyle;

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
                    textStyle: surahNameTextStyle,
                  ),
                  const SizedBox(height: 8),
                ],
                if (block.hasBasmalah &&
                    block.surahNumber != 9 &&
                    block.surahNumber != 1)
                  const BasmalahWidget(),
                PageAyahWidget(
                  fullText: data.glyphText,
                  enableHighlight: enableHighlight,
                  activeStyle: activeStyle,
                  onAyahSelection: onTapAyah,
                  ayahs: block.ayahs,
                  style: finalTextStyle,
                ),
                const Spacer(),
              ],
            )
            .expand((widgets) => widgets),

        PageNumberWidget(page: page),
      ],
    );
  }
}
