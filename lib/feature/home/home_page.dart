// import 'package:flutter_quran/flutter_quran.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:quran/quran.dart' as quran;
import 'package:shadcn_flutter/shadcn_flutter.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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
    return const Scaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SelectableText(S.of(context).appName).x7Large(),
          // Toggle(
          //   value: ref.watch(localeNotifierProvider) == const Locale('ar'),
          //   child: Text(S.of(context).toggleArabic),
          //   onChanged: (_) =>
          //       ref.read(localeNotifierProvider.notifier).toggle(),
          // ),
          Expanded(
            child: Row(
              spacing: 120,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: OutlinedContainer(
                      width: 392.72727272727275 * 2,
                      height: 800.7272727272727 * 2,
                      padding: EdgeInsets.all(12),
                      child: Text("page")),
                ),
                Flexible(
                  child: OutlinedContainer(
                      width: 320.72727272727275,
                      height: 800.7272727272727,
                      padding: EdgeInsets.all(12),
                      child: Text("page")),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
