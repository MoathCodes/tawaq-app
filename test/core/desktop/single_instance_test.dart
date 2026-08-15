import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/desktop/single_instance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tawaq/single_instance');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'consumes the native pending activation value',
    () async {
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            received = call;
            return true;
          });

      expect(await takePendingDesktopActivate(), isTrue);
      expect(received?.method, 'takePendingActivation');
    },
    skip: !Platform.isLinux,
  );

  test(
    'keeps the window visible when the native query fails',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            throw PlatformException(code: 'unavailable');
          });

      expect(await takePendingDesktopActivate(), isTrue);
    },
    skip: !Platform.isLinux,
  );
}
