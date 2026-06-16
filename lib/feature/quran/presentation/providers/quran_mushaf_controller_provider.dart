import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'quran_mushaf_controller_provider.g.dart';

/// Shared [MushafReaderController] for the Quran screen.
///
/// Reused across header selectors, mushaf panes, and study panel instead of
/// passing the controller through multiple widget layers.
@Riverpod(keepAlive: true)
MushafReaderController quranMushafController(Ref ref) {
  final initialPage =
      ref.read(quranScreenSettingsProvider).value?.pageInfo.pageNumber ?? 1;
  final controller = MushafReaderController(initialPage: initialPage);
  ref.onDispose(controller.dispose);
  return controller;
}
