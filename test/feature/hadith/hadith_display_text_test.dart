import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_display_text.dart';

void main() {
  const record = DetailedHadith(
    hadith: '- Synthetic narration - internal punctuation',
    rawi: 'r',
    mohdith: 'm',
    book: 'b',
    numberOrPage: '1',
    grade: 'g',
  );
  test('only the verified category prefix is removed from the display', () {
    final category = record.copyWith(
      provenance: ResultProvenance(
        sourceUri: Uri.https('dorar.net', '/hadith-category/cat/fixture'),
        endpoint: 'categoryBrowse',
        fetchedAt: DateTime.utc(2026),
      ),
    );
    expect(
      hadithDisplayText(category),
      'Synthetic narration - internal punctuation',
    );
    expect(category.hadith, record.hadith);
    expect(category.toJson()['hadith'], record.hadith);
    expect(hadithDisplayText(record), record.hadith);
    final explanation = record.copyWith(
      provenance: ResultProvenance(
        sourceUri: Uri.https('dorar.net', '/sharh/fixture'),
        endpoint: 'sharh',
        fetchedAt: DateTime.utc(2026),
      ),
    );
    expect(hadithDisplayText(explanation), record.hadith);
  });
}
