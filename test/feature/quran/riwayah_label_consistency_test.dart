import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
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
  group('resolveReciterForAyahPlayback', () {
    testWidgets(
      'returns current reciter timed moshafs first, then other timed reciters',
      (tester) async {
        final current = _reciter(
          id: 1,
          name: 'Current',
          moshaf: [
            _moshaf(id: 10, name: 'Current Untimed'),
            _moshaf(id: 11, name: 'Current Timed', timingReadId: 1),
          ],
        );
        final other = _reciter(
          id: 2,
          name: 'Other',
          moshaf: [
            _moshaf(id: 20, name: 'Other Timed', timingReadId: 2),
            _moshaf(id: 21, name: 'Other Untimed'),
          ],
        );

        late List<ReciterPick> result;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedReciterProvider.overrideWith((ref) => current),
              recitersProvider.overrideWith((ref) => [current, other]),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                result = resolveReciterForAyahPlayback(ref);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(result, hasLength(2));
        expect(result[0].reciter.id, 1);
        expect(result[0].moshaf.id, 11);
        expect(result[1].reciter.id, 2);
        expect(result[1].moshaf.id, 20);
      },
    );

    testWidgets(
      'returns all timed reciters when no current reciter is selected',
      (tester) async {
        final other = _reciter(
          id: 2,
          name: 'Other',
          moshaf: [
            _moshaf(id: 20, name: 'Other Timed', timingReadId: 2),
          ],
        );

        late List<ReciterPick> result;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedReciterProvider.overrideWith((ref) => null),
              recitersProvider.overrideWith((ref) => [other]),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                result = resolveReciterForAyahPlayback(ref);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(result, hasLength(1));
        expect(result[0].reciter.id, 2);
        expect(result[0].moshaf.id, 20);
      },
    );

    testWidgets(
      'returns empty list when no timed moshafs exist',
      (tester) async {
        final current = _reciter(
          id: 1,
          name: 'Current',
          moshaf: [
            _moshaf(id: 10, name: 'Current Untimed'),
          ],
        );

        late List<ReciterPick> result;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedReciterProvider.overrideWith((ref) => current),
              recitersProvider.overrideWith((ref) => [current]),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                result = resolveReciterForAyahPlayback(ref);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(result, isEmpty);
      },
    );
  });
}
