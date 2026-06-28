import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/timed_riwayat_suggestions.dart';

Moshaf _moshaf({
  required int id,
  required String name,
  int? timingReadId,
}) =>
    Moshaf(
      id: id,
      name: name,
      server: 'https://example.com/',
      surahList: List.generate(114, (i) => i + 1),
      surahTotal: 114,
      timingReadId: timingReadId,
    );

Reciter _reciter({
  required int id,
  required String name,
  required List<Moshaf> moshaf,
}) =>
    Reciter(id: id, name: name, moshaf: moshaf);

void main() {
  group('buildTimedRiwayatSuggestions', () {
    test('lists current reciter timed moshafs first', () {
      final current = _reciter(
        id: 1,
        name: 'Current',
        moshaf: [
          _moshaf(id: 10, name: 'Current Untimed'),
          _moshaf(id: 11, name: 'Current Timed A', timingReadId: 1),
          _moshaf(id: 12, name: 'Current Timed B', timingReadId: 2),
        ],
      );
      final other = _reciter(
        id: 2,
        name: 'Other',
        moshaf: [
          _moshaf(id: 20, name: 'Other Timed', timingReadId: 3),
        ],
      );

      final result = buildTimedRiwayatSuggestions(current, [current, other]);

      expect(result, hasLength(3));
      expect(result[0].reciter.id, 1);
      expect(result[0].moshaf.id, 11);
      expect(result[1].reciter.id, 1);
      expect(result[1].moshaf.id, 12);
      expect(result[2].reciter.id, 2);
      expect(result[2].moshaf.id, 20);
    });

    test('lists all timed reciters when no current reciter', () {
      final r1 = _reciter(
        id: 1,
        name: 'One',
        moshaf: [_moshaf(id: 11, name: 'Timed 1', timingReadId: 1)],
      );
      final r2 = _reciter(
        id: 2,
        name: 'Two',
        moshaf: [
          _moshaf(id: 20, name: 'Untimed'),
          _moshaf(id: 21, name: 'Timed 2', timingReadId: 2),
        ],
      );

      final result = buildTimedRiwayatSuggestions(null, [r1, r2]);

      expect(result, hasLength(2));
      expect(result[0].reciter.id, 1);
      expect(result[0].moshaf.id, 11);
      expect(result[1].reciter.id, 2);
      expect(result[1].moshaf.id, 21);
    });

    test('excludes current reciter from the second group', () {
      final current = _reciter(
        id: 1,
        name: 'Current',
        moshaf: [
          _moshaf(id: 11, name: 'Timed', timingReadId: 1),
        ],
      );

      final result = buildTimedRiwayatSuggestions(current, [current]);

      expect(result, hasLength(1));
      expect(result[0].reciter.id, 1);
      expect(result[0].moshaf.id, 11);
    });

    test('returns empty list when no timed moshafs exist', () {
      final current = _reciter(
        id: 1,
        name: 'Current',
        moshaf: [_moshaf(id: 10, name: 'Untimed')],
      );

      final result = buildTimedRiwayatSuggestions(current, [current]);

      expect(result, isEmpty);
    });
  });
}
