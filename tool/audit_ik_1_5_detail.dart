// ignore_for_file: avoid_print

import 'dart:io';

import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';

void main() {
  final raw = File('/tmp/ik_1_5_raw.html').readAsStringSync().trim();
  final parsed = TafsirTextParser.parse(
    raw,
    tafsirId: TafsirId.ibnKathir,
  ).segments;

  // True nested spans (open before close of prior)
  final trueNested = RegExp('<span[^>]*>(?:(?!</span>).)*<span', dotAll: true);
  print('true_nested_spans: ${trueNested.hasMatch(raw)}');

  print('\n=== BARE PARENS IN COMMENTARY SEGMENTS ===');
  for (var i = 0; i < parsed.length; i++) {
    if (parsed[i].kind.name != 'commentary') continue;
    for (final m in RegExp(r'\([^)]{3,}\)?').allMatches(parsed[i].text)) {
      print('seg$i: ${m.group(0)!.length > 100 ? '${m.group(0)!.substring(0, 100)}...' : m.group(0)}');
    }
  }

  print('\n=== ORPHAN CLOSE-PAREN SEGMENTS ===');
  for (var i = 0; i < parsed.length; i++) {
    final t = parsed[i].text;
    if (t.contains(')') && !t.contains('(') && parsed[i].kind.name == 'commentary') {
      print('seg$i: ${t.trim()}');
    }
  }

  print('\n=== AYAH-LIKE TEXT IN COMMENTARY (no ﴿) ===');
  for (var i = 0; i < parsed.length; i++) {
    if (parsed[i].kind.name != 'commentary') continue;
    final t = parsed[i].text;
    if (t.contains('اهدنا الصراط') ||
        t.contains('الحمد لله') ||
        t.contains('توكلنا') ||
        t.contains('فاتخذه وكيلا')) {
      print('seg$i snippet: ...${t.length > 200 ? t.substring(0, 200) : t}...');
    }
  }

  print('\n=== MEGA AYAH SEG 11 INTERNAL PARENS ===');
  final mega = parsed[11].text;
  for (final m in RegExp(r'\([^)]+\)').allMatches(mega)) {
    print('  inner: ${m.group(0)}');
  }
  print('  contains hadith dialogue: ${mega.contains("حمدني عبدي")}');
  print('  contains الحمد لله: ${mega.contains("الحمد لله")}');

  print('\n=== RAW FRAGMENTS WITHOUT OPENING SPAN ===');
  final fragments = [
    'قل هو الرحمن آمنا به وعليه توكلنا )',
    'رب المشرق والمغرب لا إله إلا هو فاتخذه وكيلا )',
    'الحمد لله الذي أنزل على عبده الكتاب )',
    'وأنه لما قام عبد الله يدعوه )',
    'سبحان الذي أسرى بعبده ليلا )',
    'اهدنا الصراط المستقيم',
    'وقيس ]',
    'كما قال الشاعر',
  ];
  for (final f in fragments) {
    print('$f => raw contains: ${raw.contains(f)}');
  }

  print('\n=== HONORIFIC CHECK ===');
  for (var i = 0; i < parsed.length; i++) {
    if (parsed[i].text.contains('صلى الله عليه وسلم')) {
      print('seg$i: unnormalized honorific');
    }
    if (parsed[i].text.contains('ﷺ')) {
      print('seg$i: has ﷺ');
    }
  }

  print('\n=== RESIDUAL HTML / DIV ===');
  for (var i = 0; i < parsed.length; i++) {
    if (RegExp('<[^>]+>').hasMatch(parsed[i].text)) {
      print('seg$i: HTML residual');
    }
  }
  print('raw ends with div: ${raw.endsWith("</div>")}');

  print('\n=== NORMALIZER SPACING SAMPLES ===');
  print('seg2 ref: "${parsed[2].text}"');
  print('seg23 ref: "${parsed[23].text}"');
}
