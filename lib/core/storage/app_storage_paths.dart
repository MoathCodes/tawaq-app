import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _appBundleIdentifier = 'me.moathdev.tawaq';

/// Application-owned storage locations for durable and generated data.
///
/// The returned root is already application-specific on Linux, Windows, and
/// Android. macOS may return either the shared Application Support directory
/// or a sandboxed app-specific directory, so Tawaq adds its bundle identifier
/// only when the returned path does not already include it.
final class AppStoragePaths {
  AppStoragePaths._(this.root);

  /// Resolves Tawaq's private application support root.
  static Future<AppStoragePaths> resolve() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final supportSegments = p.split(p.normalize(supportDirectory.path));
    final root =
        Platform.isMacOS && !supportSegments.contains(_appBundleIdentifier)
        ? Directory(p.join(supportDirectory.path, _appBundleIdentifier))
        : supportDirectory;
    await root.create(recursive: true);
    return AppStoragePaths._(root);
  }

  /// Root for internal app data, outside user-visible Documents.
  final Directory root;

  /// Hive databases for settings and user-owned feature state.
  Directory get hive => Directory(p.join(root.path, 'hive'));

  /// Installed copies of bundled content databases.
  Directory get contentDatabases =>
      Directory(p.join(root.path, 'content', 'databases'));

  /// Bundled Quran Hive boxes.
  Directory get quran => Directory(p.join(root.path, 'content', 'quran'));

  /// Bundled Muslim Fortress databases.
  Directory get fortress =>
      Directory(p.join(contentDatabases.path, 'hisn_elmoslem'));

  /// Bundled Dorar reference data and its local API cache.
  Directory get dorar => Directory(p.join(contentDatabases.path, 'dorar'));

  /// Audio retained for offline recitation.
  Directory get recitations => Directory(p.join(root.path, 'recitations'));

  /// Internal diagnostic logs.
  Directory get logs => Directory(p.join(root.path, 'logs'));
}
