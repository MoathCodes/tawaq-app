import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';

/// Approved removal of legacy missed rows (TAW-17), before history consumers.
///
/// Startup owns the history box exclusively while the database's readiness
/// barrier blocks reads, writes and repair. The approved cleanup policy retains
/// an exact-key backup and verifies its digest before applying it. Never
/// translate missed to late or change the persisted enum indices.
class PrayerHistoryMigration {
  new(this._box, this.directory);

  static const version = 'remove-legacy-missed-v1';
  final Box<int, PrayerCompletion> _box;
  final Directory directory;
  File get _backup => File(p.join(directory.path, '$version.backup.json'));
  File get _journal => File(p.join(directory.path, '$version.journal.json'));
  Future<void>? _applying;
  String? _applyingDigest;

  /// Writes a durable exact-key backup without mutating any history row.
  /// Returns the exact backup identity required by [apply].
  Future<String> prepare() async {
    await directory.create(recursive: true);
    if (await _journal.exists())
      return (await _readJournal())['backup_sha256'] as String;
    await _box.flushBox();
    final bytes = utf8.encode(
      jsonEncode({'version': version, 'rows': await _snapshot()}),
    );
    final digest = sha256.convert(bytes).toString();
    await _atomicWrite(_backup, bytes);
    await _writeJournal(digest, 'prepared');
    return digest;
  }

  /// Applies only the prepared backup identified by [approvedBackupSha256].
  /// Interrupted deletion is retryable; unrelated edits cause refusal. The
  /// completion marker is published only after the box's durable flush.
  Future<void> apply({required String approvedBackupSha256}) {
    if (_applying != null) {
      if (_applyingDigest != approvedBackupSha256) {
        return Future.error(
          StateError('A different backup review is in progress'),
        );
      }
      return _applying!;
    }
    _applyingDigest = approvedBackupSha256;
    return _applying = _apply(approvedBackupSha256).whenComplete(() {
      _applying = null;
      _applyingDigest = null;
    });
  }

  Future<void> _apply(String approvedDigest) async {
    final journal = await _readJournal();
    final bytes = await _backup.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    if (approvedDigest != digest || journal['backup_sha256'] != digest) {
      throw StateError(
        'The exact prepared history backup has not been approved',
      );
    }
    final backup = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (backup['version'] != version)
      throw StateError('Unknown history backup version');
    final rows = (backup['rows'] as List).cast<Map<String, dynamic>>();
    final byKey = {for (final row in rows) row['key'] as int: row};
    if (byKey.length != rows.length)
      throw StateError('Duplicate history backup keys');
    final current = await _snapshot();
    if (journal['phase'] == 'complete') {
      if (current.any(
        (row) => row['status_index'] == CompletionStatus.missed.index,
      )) {
        throw StateError('Completed migration still contains missed rows');
      }
      return;
    }
    final currentByKey = {for (final row in current) row['key'] as int: row};
    for (final row in current) {
      if (jsonEncode(byKey[row['key']]) != jsonEncode(row)) {
        throw StateError(
          'History changed after preparation; preserve it and prepare a new review',
        );
      }
    }
    for (final row in rows) {
      if (row['status_index'] != CompletionStatus.missed.index &&
          !currentByKey.containsKey(row['key'])) {
        throw StateError(
          'A non-missed history row is missing; refusing migration',
        );
      }
    }
    await _writeJournal(digest, 'applying');
    for (final row in current) {
      if (row['status_index'] == CompletionStatus.missed.index) {
        await _box.delete(row['key'] as int);
      }
    }
    await _box.flushBox();
    final expected = rows
        .where((row) => row['status_index'] != CompletionStatus.missed.index)
        .toList();
    if (jsonEncode(await _snapshot()) != jsonEncode(expected)) {
      throw StateError(
        'History changed during migration; backup retained, completion not marked',
      );
    }
    await _writeJournal(digest, 'complete');
  }

  Future<List<Map<String, dynamic>>> _snapshot() async {
    final keys = (await _box.getAllKeys()).toList()..sort();
    return [
      for (final key in keys)
        if (await _box.get(key) case final PrayerCompletion row)
          {'key': key, 'status_index': row.status.index, 'value': row.toJson()},
    ];
  }

  Future<Map<String, dynamic>> _readJournal() async {
    final value =
        jsonDecode(await _journal.readAsString()) as Map<String, dynamic>;
    if (value['version'] != version ||
        !['prepared', 'applying', 'complete'].contains(value['phase'])) {
      throw StateError('Unknown history migration journal');
    }
    return value;
  }

  Future<void> _writeJournal(String digest, String phase) => _atomicWrite(
    _journal,
    utf8.encode(
      jsonEncode({'version': version, 'backup_sha256': digest, 'phase': phase}),
    ),
  );

  Future<void> _atomicWrite(File target, List<int> bytes) async {
    final staging = File('${target.path}.staging');
    await staging.writeAsBytes(bytes, flush: true);
    await staging.rename(target.path);
  }
}
