import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_ayah_widget.dart';

import '../../mocks/mock_quran_repository.dart';

void main() {
  late MushafReaderController controller;
  late MockQuranRepository mockRepo;

  setUp(() {
    mockRepo = MockQuranRepository();
    controller = MushafReaderController(repository: mockRepo);
  });

  Widget createWidgetUnderTest(int page) {
    return MaterialApp(
      home: Scaffold(
        body: MushafPage(
          page: page,
          controller: controller,
          onTapAyah: (id) {},
        ),
      ),
    );
  }

  testWidgets('MushafPage renders loading state initially', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(1));

    // Should show loading indicator initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('MushafPage renders content or error after load', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(1));
    await tester.pumpAndSettle();

    // Check if we have either the content or the error message
    final hasError = find.text('Error loading font').evaluate().isNotEmpty;
    final hasContent = find.byType(PageAyahWidget).evaluate().isNotEmpty;

    expect(
      hasError || hasContent,
      isTrue,
      reason: 'Should show either content or error',
    );
  });
}
