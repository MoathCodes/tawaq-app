/// A minimal Flutter building block for rendering Medina Mushaf pages.
///
/// [mushaf_reader] focuses on authentic Uthmanic script via QCF4 page fonts,
/// bundled Quran data, and composable widgets. It does **not** ship an app
/// shell, settings, audio, tafsir, bookmarks, or theming beyond [MushafStyle]
/// hooks — you bring those.
///
/// ## Setup
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await MushafReaderLibrary.ensureInitialized();
///   runApp(MyApp());
/// }
/// ```
///
/// ## Quick start
///
/// ```dart
/// MushafReader(
///   onAyahTap: (ayah) => print(ayah.reference),
/// )
/// ```
///
/// For full control, use [MushafPage] with your own [PageView] or
/// [MushafReaderController] for navigation and data access.
///
/// ### Callback naming
///
/// - [MushafReader] (`pagesPerViewport: 1` or `2`): [AyahTapCallback]
///   (`onAyahTap`) delivers a full [Ayah].
/// - [MushafPage]: [AyahIdTapCallback] (`onAyahIdTap`) delivers the global
///   ayah id only — use the controller or repository to resolve the model.
///
/// See also: [MushafReaderLibrary], [MushafReader], [MushafPage],
/// [MushafReaderController], [MushafConstants].
library;

import 'dart:io';

import 'package:mushaf_reader/src/data/hive/hive_box_manager.dart';

// Core utilities
export 'src/core/callbacks.dart';
export 'src/core/extensions.dart';
export 'src/core/fonts.dart'
    show MushafFonts, MushafBaseFontSizes, MushafTextStyleMerger;
export 'src/core/mushaf_constants.dart';
export 'src/core/kfqc_page_geometry.dart';
export 'src/core/mushaf_layout.dart' show mushafReferencePageHeight;
export 'src/core/mushaf_page_range_layout.dart';
// Data layer
export 'src/data/ayah_id_resolver.dart';
export 'src/data/repository/i_quran_repo.dart';
// Core models
export 'src/data/models/ayah.dart';
export 'src/data/models/ayah_fragment.dart';
export 'src/data/models/hizb.dart';
export 'src/data/models/juz.dart';
export 'src/data/models/page_line.dart';
export 'src/data/models/mushaf_page_info.dart';
export 'src/data/models/mushaf_style.dart';
export 'src/data/models/mushaf_style_extensions.dart';
export 'src/data/models/quran_page.dart';
export 'src/data/models/surah_block.dart';
export 'src/data/models/revelation_type.dart';
export 'src/data/models/surah.dart';
export 'src/data/models/surah_timing.dart';
// Controller
export 'src/logic/mushaf_reader_controller.dart';
export 'src/logic/mushaf_reader_listenables.dart';
// Screens
export 'src/presentation/screens/mushaf_page.dart';
export 'src/presentation/screens/mushaf_reader.dart';
export 'src/presentation/screens/mushaf_two_page_reader.dart';
// Widgets
export 'src/presentation/mushaf_loading.dart' show MushafLoading;
export 'src/presentation/widgets/ayah_widget.dart';
export 'src/presentation/widgets/basmalah_widget.dart';
export 'src/presentation/widgets/juz_widget.dart';
export 'src/presentation/widgets/page_number_widget.dart';
export 'src/presentation/widgets/surah_header_widget.dart';
export 'src/presentation/widgets/surah_name_widget.dart';
export 'src/presentation/widgets/mushaf_page_range.dart';

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
  /// [storageDirectory] - Optional directory for the bundled Quran boxes.
  /// When omitted, the package uses
  /// `<application-support>/mushaf_reader/`.
  ///
  /// Example with a host-selected storage directory:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await MushafReaderLibrary.ensureInitialized(
  ///     storageDirectory: Directory('/path/to/app-support/quran'),
  ///   );
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// This method is idempotent - subsequent calls return immediately.
  ///
  /// Throws if database initialization fails (e.g., missing assets).
  static Future<void> ensureInitialized({Directory? storageDirectory}) async {
    if (_initialized) return;

    final boxManager = HiveBoxManager.acquire();
    await boxManager.init(storageDirectory: storageDirectory);

    _initialized = true;
  }
}
