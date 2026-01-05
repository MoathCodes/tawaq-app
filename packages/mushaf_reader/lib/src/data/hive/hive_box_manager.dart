import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:mushaf_reader/src/data/hive/hive_adapters.dart';
// import 'package:mushaf_reader/src/data/hive/hive_registrar.g.dart';
import 'package:mushaf_reader/src/data/models/ayah_model.dart';
import 'package:mushaf_reader/src/data/models/juz_model.dart';
import 'package:mushaf_reader/src/data/models/page_layouts.dart';
import 'package:mushaf_reader/src/data/models/surah_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages Hive box initialization and access.
///
/// This manager:
/// - Copies pre-populated Hive boxes from assets to the app directory
/// - Registers all required type adapters
/// - Provides typed accessors to open boxes
///
/// ## Usage
///
/// ```dart
/// final manager = HiveBoxManager();
/// await manager.init();
///
/// final surahs = manager.surahsBox;
/// final ayahs = manager.ayahsBox; // LazyBox for memory efficiency
///
/// manager.dispose();
/// ```
class HiveBoxManager {
  /// Singleton instance.
  static HiveBoxManager? _instance;

  /// Reference count for automatic cleanup.
  static int _refCount = 0;

  /// Completer to handle concurrent initialization requests.
  bool _initialized = false;

  /// The directory where Hive stores its boxes.
  late String _hivePath;

  // Opened boxes
  Box<SurahModel>? _surahsBox;

  LazyBox<AyahModel>? _ayahsBox;

  Box<JuzModel>? _juzsBox;
  Box<PageLayouts>? _pageLayoutsBox;
  Box<String>? _metadataBox;

  /// Factory constructor that returns the singleton instance.
  factory HiveBoxManager() {
    _refCount++;
    return _instance ??= HiveBoxManager._internal();
  }
  HiveBoxManager._internal();

  /// The ayahs lazy box (6236 ayahs keyed by ID).
  ///
  /// Uses LazyBox to avoid loading all ayahs into memory.
  LazyBox<AyahModel> get ayahsBox {
    _ensureInitialized();
    return _ayahsBox!;
  }

  /// The juzs box (30 juzs keyed by number).
  Box<JuzModel> get juzsBox {
    _ensureInitialized();
    return _juzsBox!;
  }

  /// The metadata box (key-value string data).
  Box<String> get metadataBox {
    _ensureInitialized();
    return _metadataBox!;
  }

  /// The page layouts box.
  ///
  /// PageLayouts are stored with compound keys: "page_index" (e.g., "1_0").
  /// Use [getLayoutsForPage] to retrieve all layouts for a specific page.
  Box<PageLayouts> get pageLayoutsBox {
    _ensureInitialized();
    return _pageLayoutsBox!;
  }

  /// The surahs box (114 surahs keyed by number).
  Box<SurahModel> get surahsBox {
    _ensureInitialized();
    return _surahsBox!;
  }

  /// Forcefully closes all boxes.
  void closeAll() {
    _closeAndReset();
  }

  /// Disposes of the manager and closes all boxes.
  ///
  /// Uses reference counting - only closes when all references are released.
  void dispose() {
    _refCount--;

    if (_refCount <= 0) {
      _closeAndReset();
    }
  }

  /// Gets all PageLayouts for a specific page number.
  List<PageLayouts> getLayoutsForPage(int page) {
    _ensureInitialized();
    final prefix = '${page}_';
    final layouts = <PageLayouts>[];
    for (final key in _pageLayoutsBox!.keys) {
      if (key.toString().startsWith(prefix)) {
        final layout = _pageLayoutsBox!.get(key);
        if (layout != null) {
          layouts.add(layout);
        }
      }
    }
    return layouts;
  }

  /// Initializes Hive and opens all boxes.
  ///
  /// This copies the pre-populated boxes from assets on first run,
  /// registers adapters, and opens all required boxes.
  ///
  /// Safe to call multiple times - subsequent calls return immediately.
  Future<void> init() async {
    if (_initialized) return;

    // Initialize Hive with Flutter's application documents directory
    final appDir = await getApplicationDocumentsDirectory();
    _hivePath = appDir.path;
    Hive.init(_hivePath);

    // Register all adapters
    Hive
      ..registerAdapter(JuzModelAdapter())
      ..registerAdapter(AyahModelAdapter())
      ..registerAdapter(PageLayoutsAdapter())
      ..registerAdapter(SurahModelAdapter());

    // Copy pre-populated boxes from assets if needed
    await _copyBoxesFromAssets();

    // Open all boxes
    _surahsBox = await Hive.openBox<SurahModel>('surahs');
    _ayahsBox = await Hive.openLazyBox<AyahModel>('ayahs');
    _juzsBox = await Hive.openBox<JuzModel>('juzs');
    _pageLayoutsBox = await Hive.openBox<PageLayouts>('pagelayouts');
    _metadataBox = await Hive.openBox<String>('metadata');

    _initialized = true;
  }

  /// Internal method to close and reset.
  void _closeAndReset() {
    _surahsBox?.close();
    _ayahsBox?.close();
    _juzsBox?.close();
    _pageLayoutsBox?.close();
    _metadataBox?.close();

    _surahsBox = null;
    _ayahsBox = null;
    _juzsBox = null;
    _pageLayoutsBox = null;
    _metadataBox = null;

    _initialized = false;
    _instance = null;
    _refCount = 0;
  }

  /// Copies pre-populated Hive boxes from assets to the app directory.
  ///
  /// Only copies if the destination files don't exist or have different sizes.
  Future<void> _copyBoxesFromAssets() async {
    // On web, we can't copy files - Hive CE uses IndexedDB
    if (kIsWeb) return;

    const boxNames = ['surahs', 'ayahs', 'juzs', 'pagelayouts', 'metadata'];

    for (final name in boxNames) {
      await _copyBoxIfNeeded(name);
    }
  }

  /// Copies a single box file from assets if needed.
  Future<void> _copyBoxIfNeeded(String boxName) async {
    final destPath = p.join(_hivePath, '$boxName.hive');
    final destFile = File(destPath);

    try {
      // Load from assets
      final assetPath = 'packages/mushaf_reader/assets/hive/$boxName.hive';
      final data = await rootBundle.load(assetPath);
      final assetBytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // Copy if file doesn't exist or size differs
      final exists = destFile.existsSync();
      final sizeMatch = exists && destFile.lengthSync() == data.lengthInBytes;

      if (!exists || !sizeMatch) {
        debugPrint('Copying $boxName.hive to $_hivePath');
        await destFile.writeAsBytes(assetBytes, flush: true);
      }
    } catch (e) {
      // Asset might not exist in test environment or first build
      debugPrint('Warning: Could not copy $boxName.hive: $e');
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('HiveBoxManager not initialized. Call init() first.');
    }
  }
}
