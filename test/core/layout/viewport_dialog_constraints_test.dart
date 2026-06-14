import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';

void main() {
  group('dialogConstraints', () {
    testWidgets('clamps minWidth to viewport fraction', (tester) async {
      late BoxConstraints constraints;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(300, 600)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                constraints = dialogConstraints(
                  context,
                  minWidth: 320,
                  preferredHeight: 300,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(constraints.minWidth, 270);
      expect(constraints.maxWidth, 270);
      expect(constraints.maxHeight, 300);
    });

    testWidgets('respects preferred width on wide viewports', (tester) async {
      late BoxConstraints constraints;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1200, 900)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                constraints = dialogConstraints(
                  context,
                  preferredWidth: 480,
                  minWidth: 320,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(constraints.minWidth, 320);
      expect(constraints.maxWidth, 480);
    });

    testWidgets(
      'selectPopoverPortalConstraints uses auto width with viewport height',
      (tester) async {
        late FPortalConstraints portalConstraints;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  portalConstraints = selectPopoverPortalConstraints(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(
          portalConstraints,
          const FAutoWidthPortalConstraints(maxHeight: 300),
        );
      },
    );

    testWidgets(
      'selectPopoverPortalConstraints clamps height on short viewports',
      (tester) async {
        late FPortalConstraints portalConstraints;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 300)),
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  portalConstraints = selectPopoverPortalConstraints(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(
          portalConstraints,
          const FAutoWidthPortalConstraints(maxHeight: 255),
        );
      },
    );
  });
}
