import 'dart:async';

import 'package:desktop_tray/desktop_tray.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/app/desktop/desktop_tray_service.dart';
import 'package:tawaq/app/desktop/desktop_window_controller.dart';
import 'package:tawaq/core/desktop/window_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const activationChannel = MethodChannel('tawaq/single_instance');
  const windowChannel = MethodChannel('window_manager');
  const trayChannel = MethodChannel('desktop_tray');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late ProviderContainer container;
  late bool visible;
  late bool focused;
  late List<String> commands;

  setUp(() {
    container = ProviderContainer();
    visible = true;
    focused = false;
    commands = [];
    messenger
      ..setMockMethodCallHandler(activationChannel, (call) async {
        commands.add(call.method);
        visible = true;
        focused = true;
        return null;
      })
      ..setMockMethodCallHandler(windowChannel, (call) async {
        switch (call.method) {
          case 'isVisible':
            return visible;
          case 'isMaximized':
            return false;
          case 'hide':
            commands.add('hide');
            visible = false;
        }
        return null;
      })
      ..setMockMethodCallHandler(trayChannel, (call) async => true);
  });

  tearDown(() async {
    await container.read(desktopTrayServiceProvider).dispose();
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    messenger
      ..setMockMethodCallHandler(activationChannel, null)
      ..setMockMethodCallHandler(windowChannel, null)
      ..setMockMethodCallHandler(trayChannel, null);
  });

  for (final initiallyVisible in [true, false]) {
    test(
      'tray click activates a ${initiallyVisible ? 'visible' : 'hidden'} window',
      () async {
        visible = initiallyVisible;
        await container.read(nativeWindowStateProvider.future);
        container.read(desktopTrayServiceProvider).onTrayIconMouseUp();
        // Await the same in-flight request made by the tray callback.
        await container.read(desktopWindowControllerProvider).showMainWindow();

        expect(commands, ['activate']);
        expect(visible, isTrue);
        expect(focused, isTrue);
        expect(
          container.read(nativeWindowStateProvider).requireValue.visible,
          isTrue,
        );
      },
    );
  }

  test(
    'double-click shares the in-flight activation and never hides',
    () async {
      final gate = Completer<void>();
      messenger.setMockMethodCallHandler(activationChannel, (call) async {
        commands.add(call.method);
        await gate.future;
        focused = true;
        return null;
      });
      container.read(desktopTrayServiceProvider)
        ..onTrayIconMouseDown()
        ..onTrayIconMouseUp()
        ..onTrayIconMouseDown()
        ..onTrayIconMouseUp();
      final activation = container
          .read(desktopWindowControllerProvider)
          .showMainWindow();
      await Future<void>.delayed(Duration.zero);
      expect(commands, ['activate']);
      gate.complete();
      await activation;
      expect(focused, isTrue);
      expect(visible, isTrue);
    },
  );

  test('a failed activation can be retried', () async {
    messenger.setMockMethodCallHandler(activationChannel, (_) async {
      throw PlatformException(code: 'activation_failed');
    });
    final controller = container.read(desktopWindowControllerProvider);
    await expectLater(
      controller.showMainWindow(),
      throwsA(isA<PlatformException>()),
    );
    messenger.setMockMethodCallHandler(activationChannel, (call) async {
      commands.add(call.method);
      return null;
    });
    await controller.showMainWindow();
    expect(commands, ['activate']);
  });

  test('the context menu still explicitly hides the visible window', () async {
    await container.read(nativeWindowStateProvider.future);
    container
        .read(desktopTrayServiceProvider)
        .onTrayMenuItemClick(TrayMenuItem(key: 'show', label: 'Hide Tawaq'));
    await Future<void>.delayed(Duration.zero);

    expect(commands, ['hide']);
    expect(visible, isFalse);
  });

  test('concurrent initialization creates only one tray icon', () async {
    final gate = Completer<void>();
    var icons = 0;
    messenger.setMockMethodCallHandler(trayChannel, (call) async {
      if (call.method == 'setIcon') {
        icons++;
        await gate.future;
      }
      return true;
    });
    final tray = container.read(desktopTrayServiceProvider);
    final first = tray.ensureInitialized();
    final second = tray.ensureInitialized();
    await Future<void>.delayed(Duration.zero);
    expect(icons, 1);
    gate.complete();
    await Future.wait([first, second]);
    expect(tray.isAvailable, isTrue);
  });

  test(
    'registration failure leaves a visible window and no listener',
    () async {
      messenger.setMockMethodCallHandler(trayChannel, (call) async {
        if (call.method == 'setIcon') {
          throw PlatformException(code: 'TRAY_UNAVAILABLE');
        }
        return true;
      });
      final tray = container.read(desktopTrayServiceProvider);
      await tray.ensureInitialized();
      await container.read(desktopWindowControllerProvider).hideMainWindow();
      expect(tray.isAvailable, isFalse);
      expect(desktopTray.hasListeners, isFalse);
      expect(visible, isTrue);
      expect(commands, isNot(contains('hide')));
    },
  );
}
