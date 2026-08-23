import 'dart:async';
import 'dart:convert';

import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';

part 'settings_storage.g.dart';

/// Long-lived prefs use forever cache (no expireAt cleanup).
const StorageOptions kSettingsPersistForever = StorageOptions(
  cacheTime: StorageCacheTime.unsafe_forever,
);

/// Awaits a durable write of [value] under [key].
///
/// Use at kill boundaries (e.g. onboarding finish). Prefer this over
/// `await persist().future`, which only waits for hydrate decode — not a
/// mutation flush. [value] must be JSON-encodable (primitives or `toJson()`).
Future<void> flushPersistedValue(
  Storage<String, String> storage,
  String key,
  Object? value, {
  StorageOptions options = kSettingsPersistForever,
}) async {
  await storage.write(key, jsonEncode(value), options);
}

/// Hivez-backed storage for Riverpod offline persistence.
///
/// Each entry is stored as a JSON envelope:
/// ```json
/// { "data": "<encoded state>", "destroyKey": "v1", "expireAt": null }
/// ```
/// This enables full `deleteOutOfDate` support and `destroyKey` migration.
final class SettingsStorage extends Storage<String, String> {
  /// Creates a [SettingsStorage] backed by the given [_box].
  new(this._box);

  /// Opens the underlying Hivez box and returns a ready storage instance.
  factory create() =>
      SettingsStorage(Box<String, String>('riverpod_persist'));

  final Box<String, String> _box;

  /// Reads a persisted envelope for [key], or null if missing or corrupt.
  @override
  FutureOr<PersistedData<String>?> read(String key) async {
    final raw = await _box.get(key);
    if (raw == null) return null;

    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final data = envelope['data'] as String;
      final destroyKey = envelope['destroyKey'] as String?;
      final expireAtMs = envelope['expireAt'] as int?;
      final expireAt = expireAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expireAtMs)
          : null;

      return PersistedData(data, destroyKey: destroyKey, expireAt: expireAt);
    } catch (_) {
      // Corrupted entry — treat as missing.
      return null;
    }
  }

  /// Writes [value] under [key] with optional [StorageOptions] metadata.
  @override
  FutureOr<void> write(
    String key,
    String value,
    StorageOptions options,
  ) async {
    final expireAt = options.cacheTime.duration != null
        ? DateTime.now().add(options.cacheTime.duration!)
        : null;

    final envelope = jsonEncode({
      'data': value,
      'destroyKey': options.destroyKey,
      'expireAt': expireAt?.millisecondsSinceEpoch,
    });

    await _box.put(key, envelope);
  }

  /// Removes the entry for [key].
  @override
  FutureOr<void> delete(String key) async {
    await _box.delete(key);
  }

  /// Deletes entries whose expiration timestamp is in the past (best-effort).
  @override
  void deleteOutOfDate() {
    // Settings use unsafe_forever, so expiration is not expected.
    // For correctness, we schedule an async cleanup that enumerates all keys
    // and deletes any entries whose expireAt has passed.
    unawaited(
      Future<void>(() async {
        final now = DateTime.now();
        final keys = await _box.getAllKeys();

        for (final key in keys) {
          try {
            final raw = await _box.get(key);
            if (raw == null) continue;
            final envelope = jsonDecode(raw) as Map<String, dynamic>;
            final expireAtMs = envelope['expireAt'] as int?;
            if (expireAtMs != null) {
              final expireAt = DateTime.fromMillisecondsSinceEpoch(expireAtMs);
              if (expireAt.isBefore(now)) {
                await _box.delete(key);
              }
            }
          } catch (_) {
            // Corrupted entry — delete it.
            await _box.delete(key);
          }
        }
      }),
    );
  }
}

/// Shared Riverpod offline [Storage], gated on Hive core init.
///
/// Typed as [Storage] (not [SettingsStorage]) so tests can override with
/// [Storage.inMemory]. Production always returns [SettingsStorage.create].
@Riverpod(keepAlive: true)
Future<Storage<String, String>> settingsStorage(Ref ref) async {
  await ref.watch(hiveCoreInitProvider.future);
  return SettingsStorage.create();
}
