import 'package:freezed_annotation/freezed_annotation.dart';

part 'quran_note.freezed.dart';
part 'quran_note.g.dart';

/// A user reflection/note attached to a Quran ayah.
@freezed
abstract class QuranNote with _$QuranNote {
  /// Creates a [QuranNote].
  factory QuranNote({
    required String text,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _QuranNote;

  /// Deserializes a [QuranNote] from JSON.
  factory QuranNote.fromJson(Map<String, dynamic> json) =>
      _$QuranNoteFromJson(json);
}
