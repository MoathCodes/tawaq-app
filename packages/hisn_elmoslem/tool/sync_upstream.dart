import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Shallow-clones [muslimpack/HisnElmoslem_App] into a temp dir, copies the
/// SQLite databases into this package, and writes [assets/upstream.lock.json].
///
/// Run from the package root:
/// ```bash
/// dart run tool/sync_upstream.dart
/// ```
///
/// Optional env:
/// - `HISN_UPSTREAM_REF` — branch/tag to checkout (default: upstream default branch)
const _upstreamRepo = 'https://github.com/muslimpack/HisnElmoslem_App.git';
const _upstreamDbRelative = 'hisnelmoslem/assets/db';

Future<void> main() async {
  final packageRoot = Directory.current.path;
  final targetDir = p.join(packageRoot, 'assets', 'database');
  final lockFile = p.join(packageRoot, 'assets', 'upstream.lock.json');
  final ref = Platform.environment['HISN_UPSTREAM_REF'];

  final tempParent = await Directory.systemTemp.createTemp('hisn_upstream_');
  final cloneDir = p.join(tempParent.path, 'repo');
  try {
    stdout.writeln(
      'Cloning $_upstreamRepo${ref == null ? '' : ' ($ref)'}…',
    );
    final cloneArgs = <String>[
      'clone',
      '--depth',
      '1',
      '--single-branch',
      if (ref != null) ...['--branch', ref],
      _upstreamRepo,
      cloneDir,
    ];
    final clone = await Process.run('git', cloneArgs);
    if (clone.exitCode != 0) {
      stderr.writeln(clone.stderr);
      exitCode = 1;
      return;
    }

    final upstreamDbDir = p.join(cloneDir, _upstreamDbRelative);
    if (!Directory(upstreamDbDir).existsSync()) {
      stderr.writeln('Upstream database directory not found: $upstreamDbDir');
      exitCode = 1;
      return;
    }

    const files = [
      'hisn_elmoslem.db',
      'commentary.db',
      'fake_hadith.db',
      'quran.ar.uthmani.v2.db',
    ];

    await Directory(targetDir).create(recursive: true);

    for (final file in files) {
      final source = File(p.join(upstreamDbDir, file));
      if (!source.existsSync()) {
        stderr.writeln('Missing upstream database: ${source.path}');
        exitCode = 1;
        return;
      }
      await source.copy(p.join(targetDir, file));
      stdout.writeln('Copied $file');
    }

    final upstreamCommit = await _readCommit(cloneDir);

    final counts = <String, Map<String, int>>{};
    counts['hisn_elmoslem.db'] = _countTables(
      p.join(targetDir, 'hisn_elmoslem.db'),
      {
        'titles': 'SELECT COUNT(*) AS c FROM titles',
        'contents': 'SELECT COUNT(*) AS c FROM contents',
      },
    );
    counts['commentary.db'] = _countTables(
      p.join(targetDir, 'commentary.db'),
      {
        'commentary': 'SELECT COUNT(*) AS c FROM commentary',
      },
    );
    counts['fake_hadith.db'] = _countTables(
      p.join(targetDir, 'fake_hadith.db'),
      {
        'fakeHadith': 'SELECT COUNT(*) AS c FROM fakeHadith',
      },
    );
    counts['quran.ar.uthmani.v2.db'] = _countTables(
      p.join(targetDir, 'quran.ar.uthmani.v2.db'),
      {
        'arabic_text': 'SELECT COUNT(*) AS c FROM arabic_text',
      },
    );

    final lock = {
      'source_repo': 'https://github.com/muslimpack/HisnElmoslem_App',
      'source_commit': upstreamCommit,
      'synced_at': DateTime.now().toUtc().toIso8601String(),
      'databases': counts,
    };

    await File(lockFile).writeAsString(
      const JsonEncoder.withIndent('  ').convert(lock),
    );
    stdout.writeln('Wrote ${p.basename(lockFile)}');
  } finally {
    if (tempParent.existsSync()) {
      await tempParent.delete(recursive: true);
    }
  }
}

Future<String> _readCommit(String repoRoot) async {
  final result = await Process.run('git', [
    '-C',
    repoRoot,
    'rev-parse',
    'HEAD',
  ]);
  if (result.exitCode != 0) return 'unknown';
  return (result.stdout as String).trim();
}

Map<String, int> _countTables(String dbPath, Map<String, String> queries) {
  final db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
  try {
    return {
      for (final entry in queries.entries)
        entry.key: db.select(entry.value).first['c']! as int,
    };
  } finally {
    db.close();
  }
}
