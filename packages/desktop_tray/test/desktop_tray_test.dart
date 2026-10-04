import 'dart:async';

import 'package:desktop_tray/desktop_tray.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Listener with DesktopTrayListener {
  int activations = 0;
  TrayMenuItem? selected;

  @override
  void onTrayIconMouseUp() => activations++;

  @override
  void onTrayMenuItemClick(TrayMenuItem item) => selected = item;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('desktop_tray');
  const codec = StandardMethodCodec();
  late _Listener listener;

  Future<void> send(MethodCall call) {
    final done = Completer<void>();
    binding.channelBuffers.push(
      'desktop_tray',
      codec.encodeMethodCall(call),
      (_) => done.complete(),
    );
    return done.future;
  }

  setUp(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => true,
    );
    listener = _Listener();
    desktopTray.addListener(listener);
  });

  tearDown(() async {
    await desktopTray.destroy();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('primary activation reaches the completion callback on each click', () async {
    await send(const MethodCall('onTrayIconMouseUp'));
    await send(const MethodCall('onTrayIconMouseUp'));
    expect(listener.activations, 2);
  });

  test('live menu replacements dispatch only the current menu items', () async {
    final old = TrayMenuItem(key: 'show', label: 'Show Tawaq');
    final next = TrayMenuItem(key: 'show', label: 'Hide Tawaq');
    await desktopTray.setContextMenu(TrayMenu(items: [old]));
    await desktopTray.setContextMenu(TrayMenu(items: [next]));
    await send(MethodCall('onTrayMenuItemClick', {'id': old.id}));
    expect(listener.selected, isNull);
    await send(MethodCall('onTrayMenuItemClick', {'id': next.id}));
    expect(listener.selected, same(next));
  });

  test('destroy drops listeners and a recreated tray receives activation', () async {
    await desktopTray.destroy();
    await send(const MethodCall('onTrayIconMouseUp'));
    expect(listener.activations, 0);
    desktopTray.addListener(listener);
    await send(const MethodCall('onTrayIconMouseUp'));
    expect(listener.activations, 1);
  });
}
