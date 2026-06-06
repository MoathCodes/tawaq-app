import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_ayah_widget.dart';
import '../test_utils.dart';

void main() {
  testWidgets('MushafPage renders content', (WidgetTester tester) async {
    final mockRepo = MockQuranRepository();
    final controller = MushafReaderController.withRepository(
      repository: mockRepo,
      initialPage: 1,
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: MaterialApp(
          home: Scaffold(body: MushafPage(page: 1, controller: controller)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(PageAyahWidget), findsOneWidget);
    expect(find.byType(PageNumberWidget), findsOneWidget);
    expect(find.byType(JuzWidget), findsOneWidget);
    expect(find.byType(SurahHeaderWidget), findsOneWidget); // Page 1 has header
  });
}
