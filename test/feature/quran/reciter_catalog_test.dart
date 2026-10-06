import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logger/logger.dart';
import 'package:tawaq/feature/quran/data/repository/recitation_repository.dart';
import 'package:tawaq/feature/quran/data/sources/mp3quran_api.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';

const saved = Reciter(
  id: 7,
  name: 'Saved reciter',
  moshaf: [
    Moshaf(
      id: 11,
      name: 'Saved riwayah',
      server: 'https://example.invalid/audio/',
      surahList: [1],
      surahTotal: 1,
    ),
  ],
);

void main() {
  test('stale valid catalog restores exact identities immediately while offline refresh stalls', () async {
    final root = await Directory.systemTemp.createTemp('tawaq-catalog-');
    addTearDown(() => root.delete(recursive: true));
    final network = Completer<http.Response>();
    final started = Completer<void>();
    var requests = 0;
    final client = MockClient((request) {
      requests++;
      if (!started.isCompleted) started.complete();
      return network.future;
    });
    final cache = RecitationCache(
      client: client,
      logger: Logger(),
      rootOverride: root,
    );
    await cache.writeCatalog([saved.toJson()]);
    final file = File('${root.path}/catalog.json');
    final stale = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    stale['savedAt'] = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String();
    await file.writeAsString(jsonEncode(stale));
    final repository = RecitationRepository(
      api: Mp3QuranApi(client: client, logger: Logger()),
      cache: cache,
      logger: Logger(),
    );
    final values = await Future.wait([
      repository.reciters(),
      repository.reciters(),
    ]).timeout(const Duration(milliseconds: 250));
    expect(values, [
      [saved],
      [saved],
    ]);
    await started.future.timeout(const Duration(milliseconds: 250));
    expect(requests, 1);
    network.completeError(const SocketException('offline'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(await repository.reciters(), [saved]);
    expect(
      await cache.readCatalog(allowStale: true),
      jsonDecode(jsonEncode([saved.toJson()])),
    );
  });

  test('invalid cached identities fall through and invalid network data never replaces disk', () async {
    final root = await Directory.systemTemp.createTemp(
      'tawaq-invalid-catalog-',
    );
    addTearDown(() => root.delete(recursive: true));
    final client = MockClient(
      (_) async => http.Response('{"reciters": []}', 200),
    );
    final cache = RecitationCache(
      client: client,
      logger: Logger(),
      rootOverride: root,
    );
    final invalid = saved
        .copyWith(moshaf: [saved.moshaf.single.copyWith(server: '', id: -1)])
        .toJson();
    await cache.writeCatalog([invalid]);
    final repository = RecitationRepository(
      api: Mp3QuranApi(client: client, logger: Logger()),
      cache: cache,
      logger: Logger(),
    );
    await expectLater(repository.reciters(), throwsFormatException);
    expect(
      await cache.readCatalog(allowStale: true),
      jsonDecode(jsonEncode([invalid])),
    );
  });
}
