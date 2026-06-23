import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_layout_widgets.dart' show QuranMushafInitGate;
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'quran_mushaf_controller_provider.g.dart';

/// Shared [MushafReaderController] for the Quran screen.
///
/// Reused across header selectors, mushaf panes, and study panel instead of
/// passing the controller through multiple widget layers.
///
/// Does not watch [mushafLibraryInitProvider]: that async provider completes
/// after the first build and would dispose/recreate this controller while
/// in-flight page-info loads are still running (used-after-dispose on
/// [MushafPageNotifier]). Mushaf init is gated on the Quran route via
/// [QuranMushafInitGate]; [main] also calls ensureInitialized for early use.
@Riverpod(keepAlive: true)
MushafReaderController quranMushafController(Ref ref) {
  final initialPage =
      ref.read(quranScreenSettingsProvider).value?.pageInfo.pageNumber ?? 1;
  final controller = MushafReaderController(initialPage: initialPage);
  ref.onDispose(controller.dispose);
  return controller;
}
