import 'package:flutter_test/flutter_test.dart';

/// Mirrors the single-flight latch in
/// `lib/core/desktop/desktop_shutdown.dart` (`_shutdownFuture ??= …`).
///
/// Kept as a pattern test so we do not import the full desktop shutdown graph
/// (prayer dispatcher → other workstreams) from this focused suite.
void main() {
  test('shutdown single-flight latch coalesces concurrent callers', () async {
    Future<void>? latch;
    var runs = 0;

    Future<void> shutdown() {
      return latch ??= () async {
        runs++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }();
    }

    final first = shutdown();
    final second = shutdown();
    expect(identical(first, second), isTrue);

    await Future.wait([first, second]);
    expect(runs, 1);
    expect(latch, isNotNull);
  });
}
