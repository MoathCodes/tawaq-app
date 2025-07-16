import 'package:flutter/material.dart';
import 'package:mushaf_reader/core/font_manager.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_ayah_widget.dart';

class MushafPage extends StatelessWidget {
  final int page;
  final bool enableHighlight;
  final Widget? loadingWidget;
  final TextStyle? textStyle;
  final TextStyle? activeTextStyle;
  final TextStyle? surahNameTextStyle;
  final Function(int) onTap;

  const MushafPage({
    super.key,
    required this.page,
    this.loadingWidget,
    this.textStyle,
    this.enableHighlight = true,
    required this.onTap,
    this.activeTextStyle,
    this.surahNameTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final getPage = MushafController.instance.getPage(page);
    return FutureBuilder<QuranPageModel>(
      future: getPage,
      builder: (_, snap) {
        if (!snap.hasData) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        // Statically get the font family name. No need to wait or check.
        final pageFontFamily = FontHelper.getFontFamilyForPage(page);

        final defaultAyahStyle = TextStyle(
          fontFamily: pageFontFamily,
          package: 'mushaf_reader',
          fontSize: 28,
          height: 1.6,
          color: const Color(0xFF000000),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SurahNameWidget(
                  name: data.surahs[0].glyph,
                  textStyle: defaultAyahStyle.copyWith(fontSize: 18),
                ),
                JuzWidget(
                  number: data.juzNumber,
                  textStyle: defaultAyahStyle.copyWith(fontSize: 36),
                ),
              ],
            ),
            const Spacer(),
            for (final block in data.surahs) ...[
              if (block.hasBasmalah)
                SurahHeaderWidget(
                  name: block.glyph,
                  textStyle: surahNameTextStyle,
                ),
              const SizedBox(height: 8),
              if (block.hasBasmalah &&
                  block.surahNumber != 9 &&
                  block.surahNumber != 1)
                const BasmalahWidget(),
              PageAyahWidget(
                fullText: data.glyphText,
                enableHighlight: enableHighlight,
                activeStyle:
                    activeTextStyle?.copyWith(fontFamily: pageFontFamily) ??
                    defaultAyahStyle.copyWith(
                      backgroundColor: const Color.fromARGB(195, 243, 216, 127),
                    ),
                onAyahSelection: onTap,
                ayahs: block.ayahs,
                style:
                    textStyle?.copyWith(fontFamily: pageFontFamily) ??
                    defaultAyahStyle,
              ),
              const Spacer(),
            ],
            PageNumberWidget(page: page),
          ],
        );
      },
    );
  }
}
