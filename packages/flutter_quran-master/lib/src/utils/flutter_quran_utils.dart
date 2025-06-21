import 'package:flutter/material.dart';
import 'package:flutter_quran/src/app_bloc.dart';
import 'package:flutter_quran/src/models/ayah.dart';
import 'package:flutter_quran/src/models/quran_page.dart';
import 'package:flutter_quran/src/models/surah.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_constants.dart';
import 'preferences/preferences_utils.dart';

class FlutterQuran {
  ///Singleton factory
  static final FlutterQuran _instance = FlutterQuran._internal();

  /// [hafsStyle] is the default style for Quran so all special characters will be rendered correctly
  final hafsStyle = const TextStyle(
    color: Colors.black,
    fontSize: 23.55,
    fontFamily: "hafs",
    package: "flutter_quran",
  );

  factory FlutterQuran() {
    return _instance;
  }

  FlutterQuran._internal();

  ///[getAllHizbs] returns list of all Quran hizbs' names
  List<String> getAllHizbs() =>
      QuranConstants.quranHizbs.map((jozz) => "الحزب $jozz").toList();

  ///[getAllJozzs] returns list of all Quran jozzs' names
  List<String> getAllJozzs() => QuranConstants.quranHizbs
      .sublist(0, 30)
      .map((jozz) => "الجزء $jozz")
      .toList();

  List<QuranPage> getAllQuranPages() => AppBloc.quranCubit.staticPages;

  ///[getAllSurahs] returns list of all Quran surahs' names
  List<String> getAllSurahs({bool isArabic = true}) => AppBloc.quranCubit.surahs
      .map((surah) => "سورة ${isArabic ? surah.nameAr : surah.nameEn}")
      .toList();

  /// [getCurrentPageNumber] Returns the page number of the page that the user is currently on.
  /// Page numbers start at 1, so the first page of the Quran is page 1.
  int getCurrentPageNumber() => AppBloc.quranCubit.lastPage;

  QuranPage getQuranPage(int page) => AppBloc.quranCubit.staticPages[page - 1];

  /// [getSurah] let's you get a Surah with all its data
  /// Note it receives surah number not surah index
  Surah getSurah(int surah) => AppBloc.quranCubit.surahs[surah - 1];

  /// [init] initializes the FlutterQuran, and must be called before starting using the package
  Future<void> init() async {
    PreferencesUtils().preferences = await SharedPreferences.getInstance();
    await AppBloc.quranCubit.loadQuran();
  }

  /// [navigateToAyah] let's you navigate to any ayah..
  /// It's better to call this method while Quran screen is displayed
  /// and if it's called and the Quran screen is not displayed, the next time you
  /// open quran screen it will start from this ayah's page
  void navigateToAyah(Ayah ayah) {
    AppBloc.quranCubit.animateToPage(ayah.page - 1);
  }

  /// [navigateToHizb] let's you navigate to any quran hizb with hizb number
  /// Note it receives hizb number not hizb index
  void navigateToHizb(int hizb) => navigateToPage(
      hizb == 1 ? 0 : (AppBloc.quranCubit.quranStops[(hizb - 1) * 4 - 1]));

  /// [navigateToJozz] let's you navigate to any quran jozz with jozz number
  /// Note it receives jozz number not jozz index
  void navigateToJozz(int jozz) => navigateToPage(
      jozz == 1 ? 0 : (AppBloc.quranCubit.quranStops[(jozz - 1) * 8 - 1]));

  /// [navigateToPage] let's you navigate to any quran page with page number
  /// Note it receives page number not page index
  /// It's better to call this method while Quran screen is displayed
  /// and if it's called and the Quran screen is not displayed, the next time you
  /// open quran screen it will start from this page
  void navigateToPage(int page) => AppBloc.quranCubit.animateToPage(page - 1);

  /// [navigateToSurah] let's you navigate to any quran surah with surah number
  /// Note it receives surah number not surah index
  void navigateToSurah(int surah) =>
      navigateToPage(AppBloc.quranCubit.surahsStart[surah - 1] + 1);

  /// [search] Searches the Quran for the given text.
  ///
  /// Returns a list of all Ayahs whose text contains the given text.
  List<Ayah> search(String text) => AppBloc.quranCubit.search(text);
}
