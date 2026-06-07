import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_metadata_parser.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_zone_splitter.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_sharh_metadata_card.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_sharh_text.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/durations.dart';
import 'package:tawaq/theme/radii.dart';

void main() {
  late List<Map<String, dynamic>> fixtures;

  setUpAll(() {
    final raw =
        File('test/fixtures/hadith_sharh_samples.json').readAsStringSync();
    fixtures = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  });

  Map<String, dynamic> fixture(String id) {
    return fixtures.firstWhere((entry) => entry['id'] == id);
  }

  Widget wrap(Widget child) {
    return FTheme(
      data: FThemeData(
        colors: FThemes.zinc.light.desktop.colors,
        typography: FThemes.zinc.light.desktop.typography,
        icons: FThemes.zinc.light.desktop.icons,
        touch: false,
        extensions: const [AppRadii.standard(), AppDurations.standard()],
      ),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  TextStyle baseStyle(FThemeData theme) {
    return theme.typography.sm.copyWith(
      fontFamily: FontFamily.iBMPlexSansArabic,
      height: 1.8,
    );
  }

  Iterable<String> visibleTexts(WidgetTester tester) sync* {
    for (final widget in tester.widgetList<Text>(find.byType(Text))) {
      if (widget.data case final text? when text.isNotEmpty) yield text;
    }
    for (final widget in tester.widgetList<ScopedSelectableText>(
      find.byType(ScopedSelectableText),
    )) {
      if (widget.data case final text when text.isNotEmpty) yield text;
    }
  }

  group('HadithSharhMetadataCard', () {
    testWidgets('renders matn prefix in blockquote area', (tester) async {
      final sample = fixture('113371');
      final zones = HadithSharhZoneSplitter.split(sample['sharh'] as String);
      final fields = HadithSharhMetadataParser.parse(zones.metadata);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return HadithSharhMetadataCard(
                fields: fields,
                matnPrefix: zones.matnPrefix,
                baseStyle: baseStyle(context.theme),
              );
            },
          ),
        ),
      );

      expect(zones.matnPrefix, isNotNull);
      expect(find.textContaining('السلامُ اسمٌ'), findsOneWidget);
    });

    testWidgets('keeps labels paired with values, not orphaned', (
      tester,
    ) async {
      final sample = fixture('113371');
      final zones = HadithSharhZoneSplitter.split(sample['sharh'] as String);
      final fields = HadithSharhMetadataParser.parse(zones.metadata);

      expect(fields.rawi, 'عبدالله بن مسعود');
      expect(fields.mohdith, 'الألباني');

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return HadithSharhMetadataCard(
                fields: fields,
                matnPrefix: zones.matnPrefix,
                baseStyle: baseStyle(context.theme),
              );
            },
          ),
        ),
      );

      final texts = visibleTexts(tester).toList(growable: false);

      expect(texts, contains('الراوي'));
      expect(texts, contains('عبدالله بن مسعود'));
      expect(texts, contains('المحدث'));
      expect(texts, contains('الألباني'));
      expect(texts, contains('التخريج'));
      expect(
        texts.any((text) => RegExp(r'^الراوي\s*:\s*$').hasMatch(text.trim())),
        isFalse,
        reason: 'raw metadata label line must not appear with trailing colon',
      );
      expect(
        texts.any((text) => RegExp(r'^المحدث\s*:\s*$').hasMatch(text.trim())),
        isFalse,
      );
      expect(
        texts.any(
          (text) => RegExp(r'^التخريج\s*:\s*$').hasMatch(text.trim()),
        ),
        isFalse,
      );
      expect(
        texts.any((text) => text.contains('المحدث :')),
        isFalse,
        reason: 'value text must not include the next field label',
      );
    });

    testWidgets('renders takhrij as one flowing paragraph', (tester) async {
      final sample = fixture('113371');
      final zones = HadithSharhZoneSplitter.split(sample['sharh'] as String);
      final fields = HadithSharhMetadataParser.parse(zones.metadata);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return HadithSharhMetadataCard(
                fields: fields,
                matnPrefix: zones.matnPrefix,
                baseStyle: baseStyle(context.theme),
              );
            },
          ),
        ),
      );

      final takhrijText = tester.widgetList<ScopedSelectableText>(
        find.byType(ScopedSelectableText),
      ).map((widget) => widget.data).whereType<String>().firstWhere(
            (text) => text.contains('أخرجه'),
          );

      expect(takhrijText, contains('أخرجه'));
      expect(takhrijText, contains('البخاري'));
      expect(takhrijText, isNot(contains('\n')));
    });
  });

  group('HadithSharhText wiring', () {
    testWidgets('shows metadata card with matn prefix from zones', (
      tester,
    ) async {
      final sample = fixture('113371');

      await tester.pumpWidget(
        wrap(HadithSharhText(text: sample['sharh'] as String)),
      );

      expect(find.byType(HadithSharhMetadataCard), findsOneWidget);
      expect(find.textContaining('السلامُ اسمٌ'), findsOneWidget);
      expect(find.text('الراوي'), findsOneWidget);
      expect(find.textContaining('عبدالله بن مسعود'), findsOneWidget);
    });

    testWidgets('shows metadata card when commentary is stub sharh id', (
      tester,
    ) async {
      const stubSharh = '''
ثلاثةٌ من الكُفرِ باللهِ : شَقُّ الجيبِ ، والنِّياحةُ ، والطَّعنُ في النَّسَبِ .
     الراوي :
        أبو هريرة |  المحدث :
        الألباني
        |
        المصدر :
        صحيح مسلم


        الصفحة أو الرقم: 431 |  خلاصة حكم المحدث : [صحيح]

          التخريج :
        أخرجه أبو ادود (1000)، وأحمد (20964)، وابن حبان (1878) جميعهم باختلاف يسير.



113343''';

      await tester.pumpWidget(wrap(const HadithSharhText(text: stubSharh)));

      expect(find.byType(HadithSharhMetadataCard), findsOneWidget);
      expect(find.text('الراوي'), findsOneWidget);
      expect(find.textContaining('أبو هريرة'), findsOneWidget);
    });
  });
}
