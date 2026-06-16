import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Demo app boots', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pump();
    expect(find.text('desktop_tray demo'), findsWidgets);
  });
}
