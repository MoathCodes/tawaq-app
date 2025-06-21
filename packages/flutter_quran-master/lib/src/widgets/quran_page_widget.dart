import 'package:flutter_quran/flutter_quran.dart';
import 'package:flutter_quran/src/models/quran_page.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class QuranPageWidget extends StatelessWidget {
  final QuranPage page;
  final int index;
  final double heightFactor;
  final double width;
  final Orientation orientation;
  final void Function(int)? onPageChanged;

  const QuranPageWidget({
    required this.page,
    required this.index,
    required this.heightFactor,
    required this.width,
    required this.orientation,
    this.onPageChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    List<String> newSurahs = [];

    return Container(
      height: heightFactor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: index == 0 || index == 1
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SurahHeaderWidget(page.ayahs[0].surahNameAr),
                          if (index == 1) const BasmallahWidget(),
                          ...page.lines.map((line) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: width - 32,
                                  child:
                                      QuranLine(line, boxFit: BoxFit.scaleDown),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return ListView(
                        physics: orientation == Orientation.portrait
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        children: [
                          ...page.lines.map((line) {
                            bool firstAyah = false;
                            if (line.ayahs[0].ayahNumber == 1 &&
                                !newSurahs
                                    .contains(line.ayahs[0].surahNameAr)) {
                              newSurahs.add(line.ayahs[0].surahNameAr);
                              firstAyah = true;
                            }
                            return Column(
                              children: [
                                if (firstAyah)
                                  SurahHeaderWidget(line.ayahs[0].surahNameAr),
                                if (firstAyah && line.ayahs[0].surahNumber != 9)
                                  const BasmallahWidget(),
                                SizedBox(
                                  width: width - 30,
                                  height: ((orientation == Orientation.landscape
                                              ? constraints.maxHeight
                                              : width) -
                                          (page.numberOfNewSurahs *
                                              (line.ayahs[0].surahNumber != 9
                                                  ? 110
                                                  : 80))) *
                                      0.95 /
                                      page.lines.length,
                                  child: QuranLine(
                                    line,
                                    // boxFit: BoxFit.fill,
                                    boxFit: line.ayahs.last.centered
                                        ? BoxFit.scaleDown
                                        : BoxFit.fill,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
          QuranPageBottomInfoWidget(
            page: index + 1,
            hizb: page.hizb,
            surahName: page.ayahs.last.surahNameAr,
          ),
        ],
      ),
    );
  }
}
