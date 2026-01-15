import 'package:hasanat/feature/quran/domain/models/quran_layouts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quran_reader_provider.g.dart';

/// Notifier for the Quran reading layout.
@riverpod
class QuranReaderNotifier extends _$QuranReaderNotifier {
  @override
  QuranReadingLayout build() {
    return QuranReadingLayout.studyMode;
  }

  /// Sets the layout.
  set layout(QuranReadingLayout layout) {
    state = layout;
  }
}
