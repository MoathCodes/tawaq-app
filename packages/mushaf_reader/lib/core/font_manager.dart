// lib/src/core/font_manager.dart

/// A helper class to determine the correct font family for a given page.
///
/// This assumes font chunks are declared globally in pubspec.yaml.
class FontHelper {
  /// The font family for the shared Basmalah and surah header glyphs.
  static const String basmalahFamily = 'QCF4_BSML';

  /// Returns the font family name for the chunk that contains the given page.
  static String getFontFamilyForPage(int pageNumber) {
    return 'QuranPage_${pageNumber.toString().padLeft(3, '0')}';
  }
}

// class FontManager {
//   static final instance = FontManager._();

//   final _fontStatus = <String, FontStatus>{};
//   final _loadingFutures = <String, Future<void>>{};
//   final _statusUpdateController = StreamController<String>.broadcast();

//   FontManager._();

//   Stream<String> get onStatusChanged => _statusUpdateController.stream;

//   FontStatus getStatusForPage(int page) {
//     final family = FontHelper.getFontFamilyForPage(page);
//     return _fontStatus[family] ?? FontStatus.notLoaded;
//   }

//   /// Loads the required font chunk for the page and the shared Basmalah font.
//   Future<void> loadAssetsForPage(int page) {
//     final pageChunkFamily = FontHelper.getFontFamilyForPage(page);
//     const basmalahFamily = 'QCF4_BSML'; // Shared font for surah headers

//     final pageChunkFuture = _loadFontFamily(pageChunkFamily);
//     final basmalahFuture = _loadFontFamily(basmalahFamily);

//     return Future.wait([pageChunkFuture, basmalahFuture]);
//   }

//   void prefetchAroundPage(int currentPage, {int radius = 3}) {
//     for (int i = currentPage - radius; i <= currentPage + radius; i++) {
//       if (i >= 1 && i <= 604) {
//         loadAssetsForPage(i); // Fire-and-forget
//       }
//     }
//   }

/// Performs the actual font loading, updating state, and handling cleanup.
// Future<void> _doLoadAndCache(String family) async {
//   _fontStatus[family] = FontStatus.loading;
//   _statusUpdateController.add(family);
//   try {
//     final loader = FontLoader(family)
//       ..addFont(
//         rootBundle.load(
//           'packages/mushaf_reader/assets/quran_fonts/$family.woff',
//         ),
//       );
//     await loader.load();
//     _fontStatus[family] = FontStatus.loaded;
//   } catch (e) {
//     _fontStatus[family] = FontStatus.error;
//     rethrow; // Re-throw so the Future completes with an error.
//   } finally {
//     _statusUpdateController.add(family);
//     // Remove the future from the loading map *after* it completes or fails.
//     _loadingFutures.remove(family);
//   }
// }

/// Loads a specific font family if it's not already loading or loaded.
// Future<void> _loadFontFamily(String family) {
//   if (_loadingFutures.containsKey(family)) {
//     return _loadingFutures[family]!;
//   }
//   // Create and store the future immediately to prevent re-entry.
//   final future = _doLoadAndCache(family);
//   _loadingFutures[family] = future;
//   return future;
// }
// }

// import 'package:mushaf_reader/src/core/font_provider.dart';

enum FontStatus { notLoaded, loading, loaded, error }
