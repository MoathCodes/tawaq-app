import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The live system appearance, released when no theme observes it.
final platformBrightnessProvider = StreamProvider<Brightness>((ref) {
  final binding = WidgetsBinding.instance;
  final changes = StreamController<Brightness>();
  final observer = _BrightnessObserver(
    () => changes.add(binding.platformDispatcher.platformBrightness),
  );
  binding.addObserver(observer);
  ref.onDispose(() {
    binding.removeObserver(observer);
    unawaited(changes.close());
  });
  return Stream<Brightness>.multi((events) {
    events.add(binding.platformDispatcher.platformBrightness);
    final subscription = changes.stream.listen(events.add);
    events.onCancel = subscription.cancel;
  });
});

class _BrightnessObserver extends WidgetsBindingObserver {
  _BrightnessObserver(this.onChange);
  final VoidCallback onChange;
  @override
  void didChangePlatformBrightness() => onChange();
}
