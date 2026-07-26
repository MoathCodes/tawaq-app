import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';

part 'quran_mushaf_controller_provider.g.dart';

/// Shared [MushafReaderController] for the Quran screen.
///
/// Reused across header selectors, mushaf panes, and study panel instead of
/// passing the controller through multiple widget layers.
@Riverpod(keepAlive: true)
MushafReaderController quranMushafController(Ref ref) {
  final settingsAsync = ref.read(quranScreenSettingsProvider);
  final initialPage = settingsAsync.value?.pageInfo.pageNumber ?? 1;
  final controller = MushafReaderController(initialPage: initialPage);
  ref.onDispose(controller.dispose);

  // Settings may still be hydrating on first read — restore once they land.
  if (!settingsAsync.hasValue) {
    var didRestore = false;
    ref.listen(quranScreenSettingsProvider, (previous, next) {
      if (didRestore) return;
      final page = next.value?.pageInfo.pageNumber;
      if (page == null) return;
      didRestore = true;
      if (controller.currentPage != page) {
        controller.jumpToPage(page);
      }
    });
  }

  return controller;
}
