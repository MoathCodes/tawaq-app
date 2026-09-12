import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';

const _timed = Moshaf(
  id: 11,
  name: 'Hafs murattal',
  server: 'https://example.com/',
  surahList: [1],
  surahTotal: 1,
  timingReadId: 42,
);

const _untimed = Moshaf(
  id: 10,
  name: 'Hafs mujawwad',
  server: 'https://example.com/',
  surahList: [1],
  surahTotal: 1,
);

const _first = Reciter(id: 1, name: 'First', moshaf: [_timed, _untimed]);
const _second = Reciter(id: 2, name: 'Second', moshaf: [_timed]);

class _Settings extends RecitationSettingsNotifier {
  _Settings(this.settings);

  final RecitationSettings settings;

  @override
  Future<RecitationSettings> build() async {
    state = AsyncData(settings);
    return settings;
  }
}

ProviderContainer _container({
  required List<Reciter> reciters,
  RecitationSettings settings = const RecitationSettings(),
}) => ProviderContainer(
  overrides: [
    recitersProvider.overrideWith((ref) async => reciters),
    recitationSettingsProvider.overrideWith(() => _Settings(settings)),
  ],
);

void main() {
  group('selectedRecitation explicit selection (TAW-70)', () {
    test(
      'stays unset with no persisted reciter despite timed catalog',
      () async {
        final container = _container(reciters: [_first, _second]);
        addTearDown(container.dispose);

        expect(await container.read(selectedRecitationProvider.future), isNull);
      },
    );

    test('stays unset when only a moshaf is persisted', () async {
      final container = _container(
        reciters: [_first],
        settings: const RecitationSettings(moshafId: 11),
      );
      addTearDown(container.dispose);

      expect(await container.read(selectedRecitationProvider.future), isNull);
    });

    test('stays unset for an unmatched persisted id', () async {
      final container = _container(
        reciters: [_first, _second],
        settings: const RecitationSettings(reciterId: 999, moshafId: 11),
      );
      addTearDown(container.dispose);

      expect(await container.read(selectedRecitationProvider.future), isNull);
    });

    test('stays unset for an unmatched persisted moshaf id', () async {
      final container = _container(
        reciters: [_first, _second],
        settings: const RecitationSettings(reciterId: 1, moshafId: 999),
      );
      addTearDown(container.dispose);

      expect(await container.read(selectedRecitationProvider.future), isNull);
    });

    test(
      'stays unset when persisted moshaf belongs to another reciter',
      () async {
        final container = _container(
          reciters: [_first, _second],
          settings: const RecitationSettings(reciterId: 2, moshafId: 10),
        );
        addTearDown(container.dispose);

        expect(await container.read(selectedRecitationProvider.future), isNull);
      },
    );

    test('restores a valid persisted selection unchanged', () async {
      final container = _container(
        reciters: [_first, _second],
        settings: const RecitationSettings(reciterId: 2, moshafId: 11),
      );
      addTearDown(container.dispose);

      final selected = await container.read(selectedRecitationProvider.future);
      expect(selected?.reciter, _second);
      expect(selected?.moshaf.id, 11);
    });

    test('stays unset for an empty catalog', () async {
      final container = _container(reciters: []);
      addTearDown(container.dispose);

      expect(await container.read(selectedRecitationProvider.future), isNull);
    });

    test('stays unset for a reciter with no moshaf entries', () async {
      const emptyReciter = Reciter(id: 3, name: 'Empty', moshaf: []);
      final container = _container(
        reciters: [emptyReciter],
        settings: const RecitationSettings(reciterId: 3, moshafId: 11),
      );
      addTearDown(container.dispose);

      expect(await container.read(selectedRecitationProvider.future), isNull);
    });

    test('cleared settings return to unset instead of a fallback', () async {
      final container = _container(
        reciters: [_first],
        settings: const RecitationSettings(reciterId: 1, moshafId: 11),
      );
      addTearDown(container.dispose);

      expect(
        await container.read(selectedRecitationProvider.future),
        isNotNull,
      );

      container.read(recitationSettingsProvider.notifier).state =
          const AsyncData(RecitationSettings());
      container.invalidate(selectedRecitationProvider);

      expect(await container.read(selectedRecitationProvider.future), isNull);
    });
  });
}
