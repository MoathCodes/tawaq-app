/// A Flutter package for displaying the Holy Quran (Mushaf) with authentic
/// Uthmanic script rendering using QCF4 (Quran Complex Fonts).
///
/// This package provides a complete solution for rendering Quran pages with:
/// - Page-specific fonts for accurate glyph rendering (QCF4_001 to QCF4_604)
/// - Ayah highlighting and selection
/// - Surah headers and Basmalah decorations
/// - Juz markers
/// - Page navigation
///
/// ## Getting Started
///
/// Initialize the library once in your `main()` function before `runApp()`:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await MushafReaderLibrary.ensureInitialized();
///   runApp(MyApp());
/// }
/// ```
///
/// Then use the reader in your widgets:
///
/// ```dart
/// class MyQuranScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MushafReader(
///       onAyahTap: (info) => print('Tapped: ${info.reference}'),
///     );
///   }
/// }
/// ```
///
/// ## Basic Usage
///
/// Display a single Mushaf page:
///
/// ```dart
/// MushafPage(
///   page: 1,
///   onTapAyah: (ayahId) {
///     print('Tapped ayah: $ayahId');
///   },
///   style: MushafStyle(
///     highlightColor: Colors.amber.withOpacity(0.3),
///   ),
/// )
/// ```
///
/// Display a single Ayah:
///
/// ```dart
/// // By global Ayah ID (1-6236)
/// AyahWidget.fromId(ayahId: 1)
///
/// // By Surah and Ayah number
/// AyahWidget.fromSurahAyah(surah: 1, ayah: 1)
/// ```
///
/// ## Architecture
///
/// The package follows a clean architecture pattern:
/// - **Models**: Data classes for Ayahs, Pages, Surahs, Juzs, and AyahInfo
/// - **Repository**: Data access layer with pre-populated Hive boxes
/// - **Controller**: [MushafReaderController] for navigation, selection, and data
/// - **Widgets**: UI components including [MushafReader] and [MushafPage]
///
/// ## Fonts
///
/// This package uses QCF4 fonts from the King Fahd Complex for the
/// Printing of the Holy Quran. Each page has its own font file to ensure
/// accurate glyph positioning and rendering that matches the printed Mushaf.
library;

import 'package:mushaf_reader/src/data/hive/hive_box_manager.dart';

// Core utilities
export 'src/core/fonts.dart'
    show MushafFonts, MushafBaseFontSizes, MushafTextStyleMerger;
// Core models
export 'src/data/models/ayah_info.dart';
export 'src/data/models/ayah_model.dart';
export 'src/data/models/juz_model.dart';
export 'src/data/models/mushaf_page_info.dart';
export 'src/data/models/mushaf_style.dart';
export 'src/data/models/quran_page_model.dart';
export 'src/data/models/surah_model.dart';
// Controller
export 'src/logic/mushaf_reader_controller.dart';
// Screens
export 'src/presentation/screens/mushaf_page.dart';
export 'src/presentation/screens/mushaf_reader.dart';
// Widgets
export 'src/presentation/widgets/ayah_widget.dart';
export 'src/presentation/widgets/basmalah_widget.dart';
export 'src/presentation/widgets/juz_widget.dart';
export 'src/presentation/widgets/page_number_widget.dart';
export 'src/presentation/widgets/surah_header_widget.dart';
export 'src/presentation/widgets/surah_name_widget.dart';

/// Global initialization for the Mushaf Reader library.
///
/// This class provides static methods for initializing the library's
/// data layer (Hive database) before using any reader widgets.
///
/// ## Usage
///
/// Call [ensureInitialized] once in your `main()` function:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await MushafReaderLibrary.ensureInitialized();
///   runApp(MyApp());
/// }
/// ```
abstract final class MushafReaderLibrary {
  static bool _initialized = false;

  /// Returns `true` if the library has been initialized.
  ///
  /// Check this before using [MushafReaderController] if you're unsure
  /// whether initialization has completed.
  static bool get isInitialized => _initialized;

  /// Initializes the Mushaf Reader library.
  ///
  /// This method must be called once before using any Mushaf widgets or
  /// the [MushafReaderController]. It initializes the Hive database,
  /// registers type adapters, and copies pre-populated data from assets.
  ///
  /// This method is idempotent - subsequent calls return immediately.
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await MushafReaderLibrary.ensureInitialized();
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// Throws if database initialization fails (e.g., missing assets).
  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    final boxManager = HiveBoxManager();
    await boxManager.init();

    _initialized = true;
  }
}
