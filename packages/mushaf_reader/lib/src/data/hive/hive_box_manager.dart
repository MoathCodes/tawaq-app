import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:mushaf_reader/src/data/hive/hive_registrar.g.dart';
import 'package:mushaf_reader/src/data/models/ayah.dart';
import 'package:mushaf_reader/src/data/models/hizb.dart';
import 'package:mushaf_reader/src/data/models/juz.dart';
import 'package:mushaf_reader/src/data/models/page_layouts.dart';
import 'package:mushaf_reader/src/data/models/surah.dart';
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
/// Prefer initializing via [MushafReaderLibrary.ensureInitialized] so apps can
/// pass a [subDirectory]. Direct use:
///
/// ```dart
/// final manager = HiveBoxManager.acquire();
/// await manager.init();
///
/// final surahs = manager.surahsBox;
/// final ayahs = manager.ayahsBox; // LazyBox for memory efficiency
///
/// manager.dispose();
/// ```
///
/// [subDirectory] is fixed on the first successful [init] call. Later calls with
/// a different value throw [StateError].
class HiveBoxManager {
  /// Singleton instance.
  static HiveBoxManager? _instance;

  /// Reference count for automatic cleanup.
  static int _refCount = 0;

  /// Completer to handle concurrent initialization requests.
  Completer<void>? _initCompleter;

  /// Whether [init] has completed successfully.
  bool _initialized = false;

  /// [subDirectory] passed to the first successful [init], if any.
  String? _configuredSubDirectory;

  /// The directory where Hive stores its boxes.
  late String _hivePath;

  // Opened boxes
  Box<Surah>? _surahsBox;

  LazyBox<Ayah>? _ayahsBox;

  Box<String>? _searchIndexBox;

  Completer<Box<String>>? _searchIndexOpenCompleter;

  Box<Juz>? _juzsBox;
  Box<Hizb>? _hizbsBox;
  Box<PageLayouts>? _pageLayoutsBox;
  Box<String>? _metadataBox;

  /// Layout rows grouped by page number (built once at init).
  final Map<int, List<PageLayouts>> _layoutsByPage = {};

  /// Whether boxes have been opened via [init].
  bool get isInitialized => _initialized;

  /// [subDirectory] from the first successful [init], if any.
  String? get configuredSubDirectory => _configuredSubDirectory;

  /// Current reference count (for tests).
  @visibleForTesting
  static int get refCount => _refCount;

  /// The shared singleton (does not change [refCount]).
  static HiveBoxManager get instance {
    return _instance ??= HiveBoxManager._internal();
  }

  /// Returns [instance] and increments [refCount] for ownership.
  ///
  /// Pair each [acquire] with [dispose] on the returned instance.
  static HiveBoxManager acquire() {
    _refCount++;
    return instance;
  }

  /// Returns the singleton without changing [refCount].
  ///
  /// Prefer [acquire] when this manager is owned for its lifetime.
  factory HiveBoxManager() => instance;

  HiveBoxManager._internal();

  /// The ayahs lazy box (6236 ayahs keyed by ID).
  ///
  /// Uses LazyBox to avoid loading all ayahs into memory.
  LazyBox<Ayah> get ayahsBox {
    _ensureInitialized();
    return _ayahsBox!;
  }

  /// Opens the pre-normalized ayah search box (6236 entries keyed by ayah ID).
  ///
  /// Value format: `"surahNumber|normalizedText"`. Deferred until first search
  /// or [ensureSearchIndexBoxOpen] so readers that never search pay no RAM cost.
  Future<Box<String>> ensureSearchIndexBoxOpen() async {
    _ensureInitialized();

    if (_searchIndexBox != null) return _searchIndexBox!;
    if (_searchIndexOpenCompleter != null) {
      return _searchIndexOpenCompleter!.future;
    }

    _searchIndexOpenCompleter = Completer<Box<String>>();

    try {
      _searchIndexBox = await Hive.openBox<String>('search_index');
      _searchIndexOpenCompleter!.complete(_searchIndexBox!);
      return _searchIndexBox!;
    } catch (e, st) {
      _searchIndexOpenCompleter!.completeError(e, st);
      _searchIndexOpenCompleter = null;
      rethrow;
    }
  }

  /// The juzs box (30 juzs keyed by number).
  Box<Juz> get juzsBox {
    _ensureInitialized();
    return _juzsBox!;
  }

  /// The hizbs box (60 hizbs keyed by number).
  Box<Hizb> get hizbsBox {
    _ensureInitialized();
    return _hizbsBox!;
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
  Box<Surah> get surahsBox {
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
    if (_refCount <= 0) return;

    _refCount--;

    if (_refCount <= 0) {
      _closeAndReset();
    }
  }

  /// Gets all PageLayouts for a specific page number.
  ///
  /// Uses an in-memory index built at [init] — O(1) per page instead of
  /// scanning every key in the layouts box.
  List<PageLayouts> getLayoutsForPage(int page) {
    _ensureInitialized();
    final layouts = _layoutsByPage[page];
    if (layouts == null || layouts.isEmpty) return const [];
    return layouts;
  }

  /// Initializes Hive and opens all boxes.
  ///
  /// This copies the pre-populated boxes from assets on first run,
  /// registers adapters, and opens all required boxes.
  ///
  /// [subDirectory] - Optional subdirectory within the app documents folder
  /// where Hive boxes should be stored. If provided, boxes will be stored at
  /// `documents/<subDirectory>/` instead of directly in `documents/`.
  /// This is useful for organizing app data in an app-specific folder.
  ///
  /// [subDirectory] is only applied on the first successful init. Subsequent
  /// calls must pass the same value (or both omit it) or a [StateError] is
  /// thrown.
  ///
  /// Safe to call multiple times concurrently — all callers await the same
  /// initialization future.
  Future<void> init({String? subDirectory}) async {
    if (_initialized) {
      _assertMatchingSubDirectory(subDirectory);
      return;
    }
    if (_initCompleter != null) {
      _assertMatchingSubDirectory(subDirectory);
      return _initCompleter!.future;
    }

    _assertMatchingSubDirectory(subDirectory);
    _configuredSubDirectory = subDirectory;
    _initCompleter = Completer<void>();

    try {
      // Initialize Hive with Flutter's application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      _hivePath = subDirectory != null
          ? p.join(appDir.path, subDirectory)
          : appDir.path;

      // Ensure the directory exists
      await Directory(_hivePath).create(recursive: true);

      Hive.init(_hivePath);

      // Register all adapters
      Hive.registerAdapters();

      // Copy pre-populated boxes from assets if needed
      await _copyBoxesFromAssets();

      // Open core boxes (search_index opens on demand via [ensureSearchIndexBoxOpen])
      _surahsBox = await Hive.openBox<Surah>('surahs');
      _ayahsBox = await Hive.openLazyBox<Ayah>('ayahs');
      _juzsBox = await Hive.openBox<Juz>('juzs');
      _hizbsBox = await Hive.openBox<Hizb>('hizbs');
      _pageLayoutsBox = await Hive.openBox<PageLayouts>('pagelayouts');
      _metadataBox = await Hive.openBox<String>('metadata');

      _buildLayoutsByPageIndex();

      _initialized = true;
      _initCompleter!.complete();
    } catch (e, st) {
      _configuredSubDirectory = null;
      _initCompleter!.completeError(e, st);
      _initCompleter = null;
      rethrow;
    }
  }

  void _assertMatchingSubDirectory(String? subDirectory) {
    if (!_initialized && _initCompleter == null) return;
    if (subDirectory == _configuredSubDirectory) return;
    throw StateError(
      'HiveBoxManager already initialized with '
      'subDirectory=${_configuredSubDirectory == null ? 'null' : '"$_configuredSubDirectory"'}; '
      'cannot re-init with '
      'subDirectory=${subDirectory == null ? 'null' : '"$subDirectory"'}',
    );
  }

  void _buildLayoutsByPageIndex() {
    _layoutsByPage.clear();
    for (final key in _pageLayoutsBox!.keys) {
      final layout = _pageLayoutsBox!.get(key);
      if (layout == null) continue;
      (_layoutsByPage[layout.page] ??= []).add(layout);
    }
  }

  /// Internal method to close and reset.
  void _closeAndReset() {
    _surahsBox?.close();
    _ayahsBox?.close();
    _searchIndexBox?.close();
    _juzsBox?.close();
    _hizbsBox?.close();
    _pageLayoutsBox?.close();
    _metadataBox?.close();

    _surahsBox = null;
    _ayahsBox = null;
    _searchIndexBox = null;
    _searchIndexOpenCompleter = null;
    _juzsBox = null;
    _hizbsBox = null;
    _pageLayoutsBox = null;
    _metadataBox = null;
    _layoutsByPage.clear();

    _initialized = false;
    _configuredSubDirectory = null;
    _initCompleter = null;
    _instance = null;
    _refCount = 0;
  }

  /// Copies pre-populated Hive boxes from assets to the app directory.
  ///
  /// Uses manifest.json (containing MD5 hashes) to detect which boxes
  /// need to be updated. This is fast at runtime since it only compares
  /// pre-computed hashes, not file contents.
  Future<void> _copyBoxesFromAssets() async {
    // On web, we can't copy files - Hive CE uses IndexedDB
    if (kIsWeb) return;

    const boxNames = [
      'surahs',
      'ayahs',
      'search_index',
      'juzs',
      'hizbs',
      'pagelayouts',
      'metadata',
    ];

    // Load asset manifest (pre-computed MD5 hashes)
    Map<String, dynamic> assetManifest;
    try {
      final manifestJson = await rootBundle.loadString(
        'packages/mushaf_reader/assets/hive/manifest.json',
      );
      assetManifest = json.decode(manifestJson) as Map<String, dynamic>;
    } catch (e) {
      // No manifest = copy all boxes (first run or legacy install)
      debugPrint('No manifest found, copying all boxes...');
      for (final name in boxNames) {
        await _copyBoxFromAssets(name);
      }
      return;
    }

    // Load local manifest (hashes of currently installed boxes)
    final localManifestPath = p.join(_hivePath, 'manifest.json');
    final localManifestFile = File(localManifestPath);
    Map<String, dynamic> localManifest = {};
    if (localManifestFile.existsSync()) {
      try {
        localManifest =
            json.decode(localManifestFile.readAsStringSync())
                as Map<String, dynamic>;
      } catch (_) {
        // Corrupted manifest, will re-copy all
      }
    }

    // Compare hashes and copy only changed boxes
    var needsUpdate = false;
    for (final name in boxNames) {
      final hiveFile = '$name.hive';
      final assetHash = assetManifest[hiveFile];
      final localHash = localManifest[hiveFile];

      if (assetHash == null) continue;
      if (assetHash == localHash) continue;

      debugPrint('$hiveFile changed, copying...');
      await _copyBoxFromAssets(name);
      localManifest[hiveFile] = assetHash;
      needsUpdate = true;
    }

    if (needsUpdate || !localManifestFile.existsSync()) {
      await localManifestFile.writeAsString(json.encode(localManifest));
    }
  }

  /// Copies a single box file from assets.
  Future<void> _copyBoxFromAssets(String boxName) async {
    final destPath = p.join(_hivePath, '$boxName.hive');
    final destFile = File(destPath);

    try {
      final assetPath = 'packages/mushaf_reader/assets/hive/$boxName.hive';
      final data = await rootBundle.load(assetPath);
      final assetBytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await destFile.writeAsBytes(assetBytes, flush: true);
    } catch (e, st) {
      final message = 'Failed to copy $boxName.hive from assets: $e';
      debugPrint('HiveBoxManager: $message');
      if (kDebugMode) {
        Error.throwWithStackTrace(StateError(message), st);
      }
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'HiveBoxManager not initialized. Call '
        'MushafReaderLibrary.ensureInitialized() or init() first.',
      );
    }
  }
}
