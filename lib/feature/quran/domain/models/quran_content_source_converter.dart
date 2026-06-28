import 'package:json_annotation/json_annotation.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';

TranslationId? _translationIdFromPersistedString(String value) {
  for (final source in TranslationId.values) {
    if (source.name == value) return source;
  }
  for (final source in TranslationId.values) {
    if (source.displayName == value) return source;
  }
  return null;
}

TafsirId? _tafsirIdFromPersistedString(String value) {
  const legacyNames = {
    'tabari': TafsirId.baghawi,
    'تفسير الطبري': TafsirId.baghawi,
    'Tafsir Al-Tabari': TafsirId.baghawi,
  };
  final legacy = legacyNames[value];
  if (legacy != null) return legacy;

  for (final source in TafsirId.values) {
    if (source.name == value) return source;
  }
  for (final source in TafsirId.values) {
    if (source.arabicName == value) return source;
  }
  for (final source in TafsirId.values) {
    if (source.englishName == value) return source;
  }
  return null;
}

/// JSON converter for [TranslationId] storing enum identifiers in persisted state.
class TranslationIdConverter implements JsonConverter<TranslationId, Object?> {
  /// Creates a [TranslationIdConverter].
  const TranslationIdConverter();

  @override
  TranslationId fromJson(Object? json) {
    if (json is String) {
      return _translationIdFromPersistedString(json) ?? kDefaultTranslationId;
    }
    return kDefaultTranslationId;
  }

  @override
  String toJson(TranslationId object) => object.name;
}

/// JSON converter for [TafsirId] storing enum identifiers in persisted state.
class TafsirIdConverter implements JsonConverter<TafsirId, Object?> {
  /// Creates a [TafsirIdConverter].
  const TafsirIdConverter();

  @override
  TafsirId fromJson(Object? json) {
    if (json is String) {
      return _tafsirIdFromPersistedString(json) ?? kDefaultTafsirId;
    }
    return kDefaultTafsirId;
  }

  @override
  String toJson(TafsirId object) => object.name;
}
