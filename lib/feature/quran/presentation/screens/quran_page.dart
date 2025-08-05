// import 'package:flutter_quran/flutter_quran.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:page_flip/page_flip.dart';
// import 'package:quran/quran.dart' as quran;

class QuranPage extends ConsumerStatefulWidget {
  const QuranPage({super.key});

  @override
  ConsumerState<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends ConsumerState<QuranPage>
    with TickerProviderStateMixin {
  int page = 1;

  late AnimationController animation;
  final _controller = GlobalKey<PageFlipWidgetState>();

  @override
  Widget build(BuildContext context) {
    // final pageText = quran.getVersesTextByPage(12);
    // final pageData = quran.getPageData(12);
    // for (var element in page) {
    //   for (var i = element['start']; i <= element['end']; i++) {
    //     pageText =
    //         "$pageText${quran.getVersesTextByPage(element['surah'], i)} ${quran.getVerseEndSymbol(i)} ";
    //   }
    // }
    // print(pageText);
    return FScaffold(
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 500,
            height: 1000,
            child: PageFlipWidget(
              key: _controller,
              backgroundColor: FTheme.of(context).colors.foreground,
              initialIndex: 0,
              // isRightSwipe: true,
              lastPage: Container(
                  color: FTheme.of(context).colors.background,
                  child: MushafPage(
                    page: page,
                    onTapAyah: (ayahId) {},
                  )),
              children: <Widget>[
                for (var i = 0; i < 604; i++)
                  Container(
                      color: FTheme.of(context).colors.background,
                      child: MushafPage(
                        page: i + 1,
                        onTapAyah: (p0) {},
                      )),
              ],
              onPageFlipped: (pageNumber) {
                debugPrint('onPageFlipped: (pageNumber) $pageNumber');
              },
              onFlipStart: () {
                debugPrint('onFlipStart');
              },
            ),
          ),
          // floatingActionButton: FloatingActionButton(
          //   child: const Icon(Icons.looks_5_outlined),
          //   onPressed: () {
          //     _controller.currentState?.goToPage(5);
          //   },
          // ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller.currentState?.goToPage(598);

    animation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
  }
}
