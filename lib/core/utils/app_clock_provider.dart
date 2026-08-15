import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_clock_provider.g.dart';

/// Application-wide wall clock. Tests can override this single stream.
@Riverpod(keepAlive: true)
Stream<DateTime> appClock(Ref ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
}
