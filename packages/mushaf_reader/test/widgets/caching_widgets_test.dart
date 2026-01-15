import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import '../test_utils.dart';

class SlowMockQuranRepository extends MockQuranRepository {
  @override
  JuzModel? getJuzSync(int number) => null; // Simulate cache miss

  @override
  Future<JuzModel> getJuz(int number) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return super.getJuz(number);
  }
}

void main() {
  testWidgets('SurahNameWidget.fromSurahNumber loads and renders', (
    WidgetTester tester,
  ) async {
    final mockRepo = MockQuranRepository();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: SurahNameWidget.fromSurahNumber(1, repository: mockRepo),
      ),
    );

    // Initial state: SizedBox.shrink (empty)
    // Actually FutureBuilder might build immediately if future completes immediately?
    // Microtask?
    // Let's check.

    await tester.pump(); // Frame

    // Wait for future
    await tester.pumpAndSettle();

    // Should render Text 'S1' (from mock)
    expect(find.text('S1'), findsOneWidget);
  });

  testWidgets('JuzWidget loads synchronously when cached', (
    WidgetTester tester,
  ) async {
    final mockRepo = MockQuranRepository();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: JuzWidget(number: 1, repository: mockRepo),
      ),
    );

    // Should render immediately because getJuzSync returns data
    expect(find.text('Juz 1'), findsOneWidget);
  });

  testWidgets('JuzWidget loads asynchronously when cache miss', (
    WidgetTester tester,
  ) async {
    final slowRepo = SlowMockQuranRepository();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: JuzWidget(number: 1, repository: slowRepo),
      ),
    );

    // Initial state: Empty (FutureBuilder waiting)
    expect(find.text('Juz 1'), findsNothing);

    // Wait for future
    await tester.pumpAndSettle();

    // Now it should show
    expect(find.text('Juz 1'), findsOneWidget);
  });
}
