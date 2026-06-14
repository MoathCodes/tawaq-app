import 'package:example/demo_scaffold.dart';
import 'package:example/demo_widgets.dart';
import 'package:example/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// Demonstrates low-level mushaf widgets with repository-backed data.
///
/// See package README "Low-level pieces" — never pass fake [Surah.glyph] strings.
class StandaloneWidgetsDemo extends StatelessWidget {
  const StandaloneWidgetsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const headerFontSize = MushafBaseFontSizes.basmalah;
    const juzFontSize = headerFontSize + 20;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final chromeStyle = TextStyle(color: onSurface);
    final bannerSurahNameStyle = TextStyle(color: onSurface);

    return DemoScaffold(
      title: t.standalone.title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WidgetDemoCard(
            title: t.standalone.ayahFromId,
            hint: t.standalone.ayahFromIdHint,
            child: AyahWidget.fromId(
              ayahId: 255,
              fontSize: 28,
            ),
          ),
          WidgetDemoCard(
            title: t.standalone.ayahFromSurahAyah,
            hint: t.standalone.ayahFromSurahAyahHint,
            child: AyahWidget.fromSurahAyah(
              surah: 1,
              ayah: 1,
              fontSize: 28,
            ),
          ),
          WidgetDemoCard(
            title: t.standalone.basmalah,
            hint: t.standalone.basmalahHint,
            child: BasmalahWidget(
              fontSize: headerFontSize,
              textStyle: chromeStyle,
            ),
          ),
          WidgetDemoCard(
            title: t.standalone.surahHeader,
            hint: t.standalone.surahHeaderHint,
            child: SurahHeaderWidget.fromSurahNumber(
              2,
              width: 360,
              fontSize: headerFontSize,
              textStyle: bannerSurahNameStyle,
            ),
          ),
          WidgetDemoCard(
            title: t.standalone.surahNameJuz,
            hint: t.standalone.surahNameJuzHint,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SurahNameWidget.fromSurahNumber(
                  1,
                  fontSize: headerFontSize,
                  textStyle: chromeStyle,
                ),
                JuzWidget(
                  number: 1,
                  fontSize: juzFontSize,
                  textStyle: chromeStyle,
                ),
              ],
            ),
          ),
          WidgetDemoCard(
            title: t.standalone.pageNumber,
            hint: t.standalone.pageNumberHint,
            child: PageNumberWidget(
              page: 1,
              fontSize: 20,
              textStyle: chromeStyle,
            ),
          ),
        ],
      ),
    );
  }
}
