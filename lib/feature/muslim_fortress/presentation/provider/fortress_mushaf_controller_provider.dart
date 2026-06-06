import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_quran_passage.dart' show FortressQuranPassage;

part 'fortress_mushaf_controller_provider.g.dart';

/// Shared [MushafReaderController] for fortress Quranic passages.
///
/// Reused across [FortressQuranPassage] instances instead of creating one
/// controller per passage widget.
@Riverpod(keepAlive: true)
MushafReaderController fortressMushafController(Ref ref) {
  final controller = MushafReaderController();
  ref.onDispose(controller.dispose);
  return controller;
}
