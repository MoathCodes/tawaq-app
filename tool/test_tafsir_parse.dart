// ignore_for_file: avoid_print

import 'dart:io';

import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';

void main(List<String> args) {
  final file = args.isNotEmpty ? args[0] : '/tmp/ik_1_5_raw.html';
  final raw = File(file).readAsStringSync();
  final parsed = TafsirTextParser.parse(
    raw,
    tafsirId: TafsirId.ibnKathir,
  ).segments;
  print('=== $file (${parsed.length} segments) ===');
  for (var i = 0; i < parsed.length; i++) {
    final s = parsed[i];
    if (s.kind == TafsirSegmentKind.ayah && s.text.length > 100) {
      print('LONG AYAH seg$i len=${s.text.length}');
    }
    if (s.text.contains('توكلنا') ||
        s.text.contains('ولا يهيضون') ||
        s.text.contains('الضالين )') ||
        s.text.contains('الضالين)')) {
      print('MATCH seg$i kind=${s.kind.name}: ${s.text}');
    }
    if (s.kind == TafsirSegmentKind.poetry) {
      print('POETRY seg$i hemis=${s.poetryHemistichs}');
    }
  }
}
