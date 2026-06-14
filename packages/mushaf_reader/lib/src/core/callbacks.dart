import 'package:mushaf_reader/src/core/mushaf_constants.dart';
import 'package:mushaf_reader/src/data/models/ayah.dart';
import 'package:mushaf_reader/src/data/models/mushaf_page_info.dart';

/// Invoked when the user taps an ayah and a full [Ayah] model is available.
///
/// Used by [MushafReader] (single- or two-page mode).
typedef AyahTapCallback = void Function(Ayah ayah);

/// Invoked when the user long-presses an ayah and a full [Ayah] is available.
typedef AyahLongPressCallback = void Function(Ayah ayah);

/// Invoked when the user taps an ayah on a single [MushafPage].
///
/// Receives the global ayah id (1–[MushafConstants.ayahCount]).
typedef AyahIdTapCallback = void Function(int ayahId);

/// Invoked when the user long-presses an ayah on a [MushafPage].
typedef AyahIdLongPressCallback = void Function(int ayahId);

/// Invoked when the user taps a surah header or name.
typedef SurahTapCallback = void Function(int surahNumber);

/// Invoked when the user taps a juz marker.
typedef JuzTapCallback = void Function(int juzNumber);

/// Invoked when the visible Mushaf page changes in single-page mode.
typedef MushafPageChangedCallback = void Function(MushafPageInfo info);

/// Invoked when the visible spread changes in two-page mode.
typedef MushafTwoPageChangedCallback =
    void Function((MushafPageInfo, MushafPageInfo?) info);
