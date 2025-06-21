import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quran/flutter_quran.dart';
import 'package:flutter_quran/src/utils/string_extensions.dart';
import 'package:flutter_quran/src/widgets/quran_page_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'app_bloc.dart';
import 'controllers/quran_controller.dart';
import 'models/quran_constants.dart';
import 'models/quran_page.dart';

part 'utils/images.dart';
part 'utils/toast_utils.dart';
part 'widgets/ayah_long_click_dialog.dart';
part 'widgets/quran_line.dart';
part 'widgets/quran_page_bottom_info.dart';
part 'widgets/surah_header_widget.dart';

class FlutterQuranScreen extends StatelessWidget {
  ///[showBottomWidget] is a bool to disable or enable the default bottom widget
  final bool showBottomWidget;

  ///[showBottomWidget] is a bool to disable or enable the default bottom widget
  final bool useDefaultAppBar;

  ///[bottomWidget] if if provided it will replace the default bottom widget
  final Widget? bottomWidget;

  ///[appBar] if if provided it will replace the default app bar
  final PreferredSizeWidget? appBar;

  ///[onPageChanged] if provided it will be called when a quran page changed
  final Function(int)? onPageChanged;

  const FlutterQuranScreen(
      {this.showBottomWidget = true,
      this.useDefaultAppBar = true,
      this.bottomWidget,
      this.appBar,
      this.onPageChanged,
      super.key});

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final Orientation currentOrientation = MediaQuery.of(context).orientation;

    return MultiBlocProvider(
      providers: AppBloc.providers,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          // appBar: appBar ?? (useDefaultAppBar ? AppBar(elevation: 0) : null),
          // drawer: appBar == null && useDefaultAppBar
          //     ? const _DefaultDrawer()
          //     : null,
          child: BlocBuilder<QuranCubit, List<QuranPage>>(
            builder: (ctx, pages) {
              return pages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SafeArea(
                      child: PageView.builder(
                        itemCount: pages.length,
                        controller: AppBloc.quranCubit.pageController,
                        onPageChanged: (page) {
                          if (onPageChanged != null) onPageChanged!(page);
                          AppBloc.quranCubit.saveLastPage(page + 1);
                        },
                        pageSnapping: true,
                        itemBuilder: (ctx, index) {
                          return QuranPageWidget(
                            page: pages[index],
                            index: index,
                            heightFactor: 1.2,
                            width: 1000,
                            orientation: currentOrientation,
                            onPageChanged: onPageChanged,
                          );
                        },
                      ),
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _FlutterQuranSearchScreen extends StatefulWidget {
  const _FlutterQuranSearchScreen();

  @override
  State<_FlutterQuranSearchScreen> createState() =>
      _FlutterQuranSearchScreenState();
}

class _FlutterQuranSearchScreenState extends State<_FlutterQuranSearchScreen> {
  List<Ayah> ayahs = [];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('بحث'),
        //   centerTitle: true,
        // ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                TextField(
                  onChanged: (txt) {
                    final searchResult = FlutterQuran().search(txt);
                    setState(() {
                      ayahs = [...searchResult];
                    });
                  },
                  // decoration: const InputDecoration(
                  //   border: OutlineInputBorder(
                  //     borderSide: BorderSide(color: Colors.black),
                  //   ),
                  //   hintText: 'بحث',
                  // ),
                ),
                Expanded(
                  child: ListView(
                    children: ayahs
                        .map((ayah) => Column(
                              children: [
                                Card(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      FlutterQuran().navigateToAyah(ayah);
                                    },
                                    child: Column(
                                      children: [
                                        Text(
                                          ayah.ayah.replaceAll('\n', ' '),
                                        ),
                                        Text(ayah.surahNameAr)
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(
                                  thickness: 1,
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
