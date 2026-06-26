import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';

void main() {
  group('dorarClientProvider', () {
    test('does not complete until dorarInit finishes', () async {
      final initGate = Completer<void>();
      var initStarted = false;
      var initFinished = false;

      final container = ProviderContainer(
        overrides: [
          dorarInitProvider.overrideWith((ref) async {
            initStarted = true;
            await initGate.future;
            initFinished = true;
          }),
        ],
      );
      addTearDown(container.dispose);

      var clientCompleted = false;
      final clientFuture = container.read(dorarClientProvider.future).then((_) {
        clientCompleted = true;
      });

      await Future<void>.delayed(Duration.zero);

      expect(initStarted, isTrue);
      expect(initFinished, isFalse);
      expect(clientCompleted, isFalse);

      initGate.complete();
      await clientFuture;

      expect(initFinished, isTrue);
      expect(clientCompleted, isTrue);
    });
  });
}
