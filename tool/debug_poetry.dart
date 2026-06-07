// ignore_for_file: avoid_print

import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_poetry_splitter.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';

void main() {
  const cases = <String>[
    'قول جرير بن عطية الخطفي :\n'
        'أمير المؤمنين على صراط\n'
        'إذا اعوج الموارد مستقيم',
    'استشهد بقول ذي الرمة :\n'
        'على رأسه أم لنا نقتدي بها\n'
        'جماع أمور ليس نعصي لها أمرا',
    'يكون بالجنان واللسان والأركان ، كما قال الشاعر :\n'
        'أفادتكم النعماء مني ثلاثة يدي ولساني والضمير المحجبا\n'
        'ولكنهم اختلفوا',
  ];

  for (final text in cases) {
    print('=== INPUT ===');
    print(text);
    final expanded = TafsirPoetrySplitter.expand([
      TafsirTextSegment(text: text, kind: TafsirSegmentKind.commentary),
    ]);
    print('--- expand ---');
    for (final s in expanded) {
      print('${s.kind.name}: ${s.text}');
      print('  hemis: ${s.poetryHemistichs}');
    }
    final parsed = TafsirTextParser.parse(text.replaceAll('\n', '<br>')).segments;
    print('--- parser ---');
    for (final s in parsed) {
      if (s.kind == TafsirSegmentKind.poetry) {
        print('poetry: ${s.poetryHemistichs}');
      }
    }
    print('');
  }
}
