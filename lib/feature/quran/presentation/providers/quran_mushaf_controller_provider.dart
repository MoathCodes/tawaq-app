import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quran_mushaf_controller_provider.g.dart';

/// Shared [MushafReaderController] for the Quran screen.
///
/// Reused across header selectors, mushaf panes, and study panel instead of
/// passing the controller through multiple widget layers.
@riverpod
MushafReaderController quranMushafController(Ref ref) {
  final controller = MushafReaderController();
  ref.onDispose(controller.dispose);
  return controller;
}
