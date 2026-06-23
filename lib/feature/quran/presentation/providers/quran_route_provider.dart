import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/routing/route_provider.dart';

part 'quran_route_provider.g.dart';

/// Whether the Quran route is the active shell destination.
@Riverpod(keepAlive: true)
class QuranRouteActive extends _$QuranRouteActive {
  @override
  bool build() {
    final router = ref.watch(appRouterProvider);
    void sync() {
      state = const QuranRoute().containsLocation(router.state.uri.path);
    }

    sync();
    router.routerDelegate.addListener(sync);
    ref.onDispose(() => router.routerDelegate.removeListener(sync));
    return const QuranRoute().containsLocation(router.state.uri.path);
  }
}
