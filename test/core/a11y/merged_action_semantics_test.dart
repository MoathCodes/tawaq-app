import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/a11y/semantics_wrappers.dart';
import 'package:tawaq/core/widgets/merged_action_semantics.dart';

void main() {
  testWidgets('named shell control retains actual activation', (tester) async {
    final semantics = tester.ensureSemantics();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MergedActionSemantics(
          label: 'Expand navigation',
          child: IconButton(
            onPressed: () => calls++,
            icon: const Icon(Icons.menu),
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.byType(MergedActionSemantics));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), true);
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    expect(calls, 1);
    semantics.dispose();
  });

  testWidgets('disabled composite cannot activate', (tester) async {
    final semantics = tester.ensureSemantics();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MergedActionSemantics(
          label: 'Unavailable',
          enabled: false,
          onTap: () => calls++,
          child: const Icon(Icons.menu),
        ),
      ),
    );
    final node = tester.getSemantics(find.byType(MergedActionSemantics));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), false);
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    expect(calls, 0);
    semantics.dispose();
  });

  testWidgets('selector labeling preserves semantic text editing', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SemanticsWrappers.labeledControl(
          label: 'Find Surah',
          excludeChild: true,
          child: Material(child: TextField(controller: controller)),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    final node = tester.getSemantics(find.byType(EditableText));
    expect(node.getSemanticsData().hasAction(SemanticsAction.setText), true);
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.setText,
      'الفاتحة',
    );
    await tester.pump();
    expect(controller.text, 'الفاتحة');
    semantics.dispose();
  });
}
