import 'dart:async';
import 'dart:convert';

import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_storage.g.dart';

/// Hivez-backed storage for Riverpod offline persistence.
///
/// Each entry is stored as a JSON envelope:
/// ```json
/// { "data": "<encoded state>", "destroyKey": "v1", "expireAt": null }
/// ```
/// This enables full `deleteOutOfDate` support and `destroyKey` migration.
final class SettingsStorage extends Storage<String, String> {
  /// Creates a [SettingsStorage] backed by the given [_box].
  SettingsStorage(this._box);

  /// Opens the underlying Hivez box and returns a ready storage instance.
  factory SettingsStorage.create() =>
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

/// Provides the shared [SettingsStorage] instance for Riverpod persistence.
///
/// Keep-alive so the storage is opened once and shared across all persisted
/// providers.
@Riverpod(keepAlive: true)
SettingsStorage settingsStorage(Ref ref) => SettingsStorage.create();
