import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Copies Hisn al-Muslim database assets from the upstream app submodule
/// into this package and writes [assets/upstream.lock.json].
///
/// Run from the package root:
/// ```bash
/// dart run tool/sync_upstream.dart
/// ```
Future<void> main() async {
  final packageRoot = Directory.current.path;
  final upstreamDbDir = p.normalize(
    p.join(packageRoot, '..', 'HisnElmoslem_App', 'hisnelmoslem', 'assets', 'db'),
  );
  final targetDir = p.join(packageRoot, 'assets', 'database');
  final lockFile = p.join(packageRoot, 'assets', 'upstream.lock.json');

  if (!Directory(upstreamDbDir).existsSync()) {
    stderr.writeln(
      'Upstream database directory not found: $upstreamDbDir\n'
      'Ensure packages/HisnElmoslem_App submodule is initialized.',
    );
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

  final upstreamCommit = await _readUpstreamCommit(
    p.dirname(upstreamDbDir),
  );

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
}

Future<String> _readUpstreamCommit(String hisnelmoslemRoot) async {
  final gitDir = p.normalize(
    p.join(hisnelmoslemRoot, '..', '..', '.git'),
  );
  if (!Directory(gitDir).existsSync()) {
    return 'unknown';
  }

  final result = await Process.run(
    'git',
    ['-C', p.dirname(hisnelmoslemRoot), 'rev-parse', 'HEAD'],
  );
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
