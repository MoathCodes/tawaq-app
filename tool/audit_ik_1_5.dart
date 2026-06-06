// ignore_for_file: avoid_print

import 'dart:io';

import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_poetry_splitter.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_segment_repair.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_normalizer.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';

void main() {
  final raw = File('/tmp/ik_1_5_raw.html').readAsStringSync().trim();

  print('=== RAW STATS ===');
  print('char_length: ${raw.length}');

  final spanClassPattern = RegExp(
    '<span\\s+class=["\']([^"\']+)["\']',
    caseSensitive: false,
  );
  final spanPattern = RegExp(
    '<span\\s+class=["\']([^"\']+)["\']>(.*?)</span>',
    caseSensitive: false,
    dotAll: true,
  );
  final brPattern = RegExp(r'<br\s*/?>', caseSensitive: false);
  final divOpen = RegExp('<div[^>]*>', caseSensitive: false);
  final divClose = RegExp('</div>', caseSensitive: false);

  final classCounts = <String, int>{};
  for (final m in spanClassPattern.allMatches(raw)) {
    final cls = m.group(1)!.toLowerCase();
    classCounts[cls] = (classCounts[cls] ?? 0) + 1;
  }
  print('br_count: ${brPattern.allMatches(raw).length}');
  print('div_open: ${divOpen.allMatches(raw).length}');
  print('div_close: ${divClose.allMatches(raw).length}');
  print('span_class_counts: $classCounts');
  print('total_spans: ${spanPattern.allMatches(raw).length}');

  // Nested spans
  print('nested_spans: ${RegExp("<span[^>]*>.*<span", dotAll: true).hasMatch(raw)}');

  // All spans inventory
  print('\n=== SPAN INVENTORY ===');
  var spanIdx = 0;
  for (final m in spanPattern.allMatches(raw)) {
    final cls = m.group(1)!.toLowerCase();
    final inner = m.group(2)!.replaceAll(RegExp('<[^>]+>'), '');
    final kind = _classify(cls, inner);
    print('[$spanIdx] class=$cls kind=${kind.name} len=${inner.length}');
    print('    ${_trunc(inner, 180)}');
    spanIdx++;
  }

  // Bare parenthetical quotes outside spans
  final strippedForBare = raw.replaceAll(
    RegExp('<span[^>]*>.*?</span>', dotAll: true),
    '<<<SPAN>>>',
  );
  print('\n=== BARE PAREN QUOTES (outside spans) ===');
  var bareIdx = 0;
  for (final m in RegExp(r'\([^)]{3,120}\)').allMatches(strippedForBare)) {
    final q = m.group(0)!;
    if (q.contains('<<<SPAN>>>')) continue;
    print('[$bareIdx] ${_trunc(q, 120)}');
    bareIdx++;
  }
  print('bare_paren_count: $bareIdx');

  // Unclosed parens / broken markup
  print('\n=== BROKEN MARKUP PATTERNS ===');
  if (raw.contains('] .')) print('FOUND: stray ] . pattern');
  if (RegExp(r'\)\s*<span').hasMatch(raw)) print('FOUND: ) immediately before span');
  if (RegExp(r'[^)]\)\s*<span class="t2">').hasMatch(raw)) {
    print('FOUND: unclosed ayah before t2 reference');
  }

  // Pipeline steps
  print('\n=== PIPELINE STEPS ===');
  final normalized = raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp('</div>', caseSensitive: false), '')
      .replaceAll(RegExp('<div[^>]*>', caseSensitive: false), '');

  final preRepair = <TafsirTextSegment>[];
  var lastEnd = 0;
  for (final match in spanPattern.allMatches(normalized)) {
    if (match.start > lastEnd) {
      final commentary = normalized.substring(lastEnd, match.start);
      final cleaned = commentary.replaceAll(RegExp('<[^>]+>'), '').trimRight();
      if (cleaned.trim().isNotEmpty) {
        preRepair.add(TafsirTextSegment(text: cleaned, kind: TafsirSegmentKind.commentary));
      }
    }
    final cssClass = match.group(1)?.trim() ?? '';
    final inner = match.group(2)!.replaceAll(RegExp('<[^>]+>'), '');
    if (inner.isNotEmpty) {
      preRepair.add(TafsirTextSegment(text: inner, kind: _classify(cssClass, inner)));
    }
    lastEnd = match.end;
  }
  if (lastEnd < normalized.length) {
    final tail = normalized.substring(lastEnd).replaceAll(RegExp('<[^>]+>'), '').trimRight();
    if (tail.trim().isNotEmpty) {
      preRepair.add(TafsirTextSegment(text: tail, kind: TafsirSegmentKind.commentary));
    }
  }

  print('after_span_parse: ${preRepair.length} segments');
  _printKindCounts('pre_repair', preRepair);

  final postRepair = TafsirSegmentRepair.repair(preRepair);
  print('after_repair: ${postRepair.length} segments');
  if (postRepair.length != preRepair.length) {
    print('REPAIR CHANGES:');
    for (var i = 0; i < postRepair.length; i++) {
      final changed = i >= preRepair.length ||
          postRepair[i].text != preRepair[i].text ||
          postRepair[i].kind != preRepair[i].kind;
      if (changed) {
        print('  [$i] ${postRepair[i].kind.name}: ${_trunc(postRepair[i].text, 120)}');
      }
    }
  }
  _printKindCounts('post_repair', postRepair);

  final postNormalize = postRepair
      .map(
        (s) => TafsirTextSegment(
          text: _normText(s),
          kind: s.kind,
          poetryHemistichs: s.poetryHemistichs,
        ),
      )
      .toList();
  _printKindCounts('post_normalize', postNormalize);

  final finalSegments = TafsirPoetrySplitter.expand(postNormalize);
  print('after_poetry: ${finalSegments.length} segments');
  _printKindCounts('final', finalSegments);

  final parsed = TafsirTextParser.parse(raw);
  print('\n=== FULL PARSER OUTPUT (${parsed.length} segments) ===');
  for (var i = 0; i < parsed.length; i++) {
    final s = parsed[i];
    final hemis = s.poetryHemistichs;
    print('[$i] ${s.kind.name}${hemis != null ? ' hemis=$hemis' : ''}');
    print('    ${_trunc(s.text, 250)}');
  }

  // Poetry lines in raw
  print('\n=== POETRY CANDIDATES IN RAW ===');
  for (var i = 0; i < normalized.split('\n').length; i++) {
    final line = normalized.split('\n')[i];
    if (RegExp(r'\s{4,}').hasMatch(line)) {
      print('4+spaces line[$i]: ${_trunc(line, 150)}');
    }
    if (line.contains('الشاعر')) {
      final lines = normalized.split('\n');
      if (i + 1 < lines.length) {
        print('after الشاعر line[$i+1]: ${_trunc(lines[i + 1], 150)}');
      }
    }
  }

  // Issue scan
  print('\n=== ISSUE SCAN ===');
  var issueNum = 0;

  for (var i = 0; i < parsed.length; i++) {
    if (RegExp('<[^>]+>').hasMatch(parsed[i].text)) {
      issueNum++;
      print('ISSUE $issueNum [HIGH] residual HTML seg $i');
      print('  ${_trunc(parsed[i].text, 120)}');
    }
  }

  // Bare ayah in commentary
  for (var i = 0; i < parsed.length; i++) {
    if (parsed[i].kind != TafsirSegmentKind.commentary) continue;
    for (final m in RegExp(r'\([^)]{5,}\)').allMatches(parsed[i].text)) {
      final q = m.group(0)!;
      issueNum++;
      print('ISSUE $issueNum [MEDIUM] bare paren in commentary seg $i');
      print('  snippet: ${_trunc(q, 100)}');
    }
  }

  // t2 editorial
  for (var i = 0; i < parsed.length; i++) {
    if (parsed[i].kind == TafsirSegmentKind.reference) {
      final t = parsed[i].text;
      if (!RegExp(r'^\s*\[.+\]\s*$').hasMatch(t.trim())) {
        issueNum++;
        print('ISSUE $issueNum [MEDIUM] t2 not standard citation seg $i');
        print('  ${_trunc(t, 120)}');
      }
      if (t.contains('فقال') || t.contains('وقال')) {
        issueNum++;
        print('ISSUE $issueNum [HIGH] t2 editorial فقال seg $i');
        print('  ${_trunc(t, 120)}');
      }
    }
  }

  // t3 classification
  for (final m in spanPattern.allMatches(normalized)) {
    if (m.group(1)!.toLowerCase() == 't3') {
      final inner = m.group(2)!.replaceAll(RegExp('<[^>]+>'), '');
      final isXref = TafsirSegmentRepair.isSurahCrossReference(inner);
      print('T3: xref=$isXref | ${_trunc(inner, 100)}');
    }
  }

  // Mega t3 span check
  for (final m in spanPattern.allMatches(normalized)) {
    final inner = m.group(2)!.replaceAll(RegExp('<[^>]+>'), '');
    if (inner.length > 300) {
      issueNum++;
      print('ISSUE $issueNum [HIGH] oversized t3 span len=${inner.length}');
      print('  start: ${_trunc(inner, 80)}');
      print('  end: ${_trunc(inner.substring(inner.length - 80), 80)}');
    }
  }

  // Unclosed ayah quotes
  for (var i = 0; i < parsed.length; i++) {
    final t = parsed[i].text;
    if (t.contains('الآية') && !t.contains('﴿')) {
      issueNum++;
      print('ISSUE $issueNum [MEDIUM] الآية marker without ayah styling seg $i kind=${parsed[i].kind.name}');
      print('  ${_trunc(t, 150)}');
    }
  }

  // Poetry detection
  for (final line in normalized.split('\n')) {
    if (RegExp(r'\s{4,}').hasMatch(line)) {
      final detected = parsed.any(
        (s) =>
            s.kind == TafsirSegmentKind.poetry &&
            (s.poetryHemistichs?.any((h) => line.contains(h.trim())) ?? false),
      );
      if (!detected) {
        issueNum++;
        print('ISSUE $issueNum [MEDIUM] 4+ space line not poetry');
        print('  ${_trunc(line, 150)}');
      }
    }
  }

  // br poetry after الشاعر
  final lines = normalized.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains('الشاعر') && i + 1 < lines.length) {
      final next = lines[i + 1];
      final detected = parsed.any(
        (s) => s.kind == TafsirSegmentKind.poetry && s.text.contains(next.trim().substring(0, 10)),
      );
      if (!detected) {
        issueNum++;
        print('ISSUE $issueNum [MEDIUM] br-separated poetry after الشاعر');
        print('  line1: ${_trunc(lines[i], 80)}');
        print('  line2: ${_trunc(next, 80)}');
      }
    }
  }

  // Honorific normalization
  for (var i = 0; i < parsed.length; i++) {
    if (parsed[i].text.contains('صلى الله عليه وسلم')) {
      issueNum++;
      print('ISSUE $issueNum [LOW] honorific not normalized seg $i');
    }
  }

  // Stray bracket
  for (var i = 0; i < parsed.length; i++) {
    if (RegExp(r'^\s*\]').hasMatch(parsed[i].text) || parsed[i].text.contains('] .')) {
      issueNum++;
      print('ISSUE $issueNum [MEDIUM] stray bracket seg $i');
      print('  ${_trunc(parsed[i].text, 120)}');
    }
  }

  print('\nspan_count=${spanPattern.allMatches(normalized).length}');
  print('final_segment_count=${parsed.length}');
  print('issue_count=$issueNum');
}

TafsirSegmentKind _classify(String cssClass, String content) {
  switch (cssClass.toLowerCase()) {
    case 'aya':
    case 't4':
      return TafsirSegmentKind.ayah;
    case 't3':
      return TafsirSegmentRepair.isSurahCrossReference(content)
          ? TafsirSegmentKind.crossReference
          : TafsirSegmentKind.ayah;
    case 't1':
      return TafsirSegmentKind.qiraatQuote;
    case 't2':
      return TafsirSegmentKind.reference;
    default:
      return TafsirSegmentKind.commentary;
  }
}

String _normText(TafsirTextSegment s) {
  final normalized = TafsirTextNormalizer.normalize(s.text);
  if (s.kind == TafsirSegmentKind.ayah) {
    return TafsirTextNormalizer.formatAyahDisplay(normalized);
  }
  return normalized;
}

void _printKindCounts(String label, List<TafsirTextSegment> segments) {
  final counts = <TafsirSegmentKind, int>{};
  for (final s in segments) {
    counts[s.kind] = (counts[s.kind] ?? 0) + 1;
  }
  print('$label kinds: ${counts.map((k, v) => MapEntry(k.name, v))}');
}

String _trunc(String s, int max) {
  final oneLine = s.replaceAll('\n', r'\n');
  if (oneLine.length <= max) return oneLine;
  return '${oneLine.substring(0, max)}...';
}
