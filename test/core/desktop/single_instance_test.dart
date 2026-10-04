import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/desktop/single_instance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tawaq/single_instance');
  const windowChannel = MethodChannel('window_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger
      ..setMockMethodCallHandler(channel, null)
      ..setMockMethodCallHandler(windowChannel, null);
  });

  test('activation uses the runner shared with duplicate launches', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    await activateDesktopWindow();

    expect(calls.single.method, 'activate');
  });

  for (final hidden in [false, true]) {
    test(
      'startup visibility is decided atomically by the runner ($hidden)',
      () async {
        final calls = <MethodCall>[];
        messenger
          ..setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          })
          ..setMockMethodCallHandler(windowChannel, (_) async {
            fail(
              'A separate hide/show could overwrite a concurrent activation',
            );
          });

        await completeDesktopActivationBootstrap(launchHidden: hidden);

        expect(calls.single.method, 'completeBootstrap');
        expect(calls.single.arguments, {'launchHidden': hidden});
      },
    );
  }

  for (final error in [
    PlatformException(code: 'unavailable'),
    MissingPluginException(),
  ]) {
    test(
      'keeps a visible recovery path when the runner fails ($error)',
      () async {
        final calls = <String>[];
        messenger
          ..setMockMethodCallHandler(channel, (_) async => throw error)
          ..setMockMethodCallHandler(windowChannel, (call) async {
            calls.add(call.method);
            if (call.method == 'isMinimized') return true;
            return null;
          });

        await completeDesktopActivationBootstrap(launchHidden: true);

        expect(calls, containsAllInOrder(['restore', 'show', 'focus']));
        expect(calls, isNot(contains('hide')));
      },
    );
  }
}
