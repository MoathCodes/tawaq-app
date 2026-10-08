// Fixture acquisition uses public SDK requests, never private cache rows.
import 'dart:convert';
import 'dart:io';

import 'package:dorar_hadith/dorar_hadith.dart';

/// Usage: fvm dart run tool/capture_sharh_fixtures.dart output.json 123 456
Future<void> main(List<String> args) async {
  if (args.length < 2)
    throw ArgumentError('Provide an output path and explanation IDs');
  final output = File(args.first).absolute;
  final temporary = await Directory.systemTemp.createTemp('tawaq-sharh-');
  final originalDirectory = Directory.current;
  Directory.current = temporary;
  try {
    final entries = await DorarClient.use((client) async {
      final entries = <Map<String, Object?>>[];
      for (final raw in args.skip(1)) {
        final id = SharhId(raw);
        final sharh = await client.getSharhById(id.value);
        sharh.document?.validate();
        entries.add({
          'id': id.value,
          'sourceUri': sharh.provenance?.sourceUri.toString(),
          'fetchedAt': sharh.provenance?.fetchedAt.toIso8601String(),
          'contentHash': sharh.document?.contentHash,
          'sharh': sharh.toJson(),
        });
      }
      return entries;
    });
    await output.writeAsString(
      const JsonEncoder.withIndent('  ').convert(entries),
    );
  } finally {
    Directory.current = originalDirectory;
    await temporary.delete(recursive: true);
  }
}
