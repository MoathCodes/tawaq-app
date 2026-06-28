import 'package:json_annotation/json_annotation.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';

/// Layout modes for reading Quran.
enum QuranReadingLayout {
  /// Double page view.
  doublePage,

  /// Study mode with translation/tafsir.
  studyMode,
}

/// JSON converter for [QuranTextScale] supporting legacy integer indices.
class QuranTextScaleConverter
    implements JsonConverter<QuranTextScale, Object?> {
  /// Creates a [QuranTextScaleConverter].
  const QuranTextScaleConverter();

  @override
  QuranTextScale fromJson(Object? json) => QuranTextScale.fromJsonValue(json);

  @override
  String toJson(QuranTextScale object) => object.name;
}
