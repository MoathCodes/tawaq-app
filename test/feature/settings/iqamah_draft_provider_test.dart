import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/iqamah_draft_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class _TestPrayerSettings extends PrayerSettingsNotifier {
  @override
  Future<PrayerSettings> build() async {
    return PrayerSettings.defaultSettings().copyWith(
      iqamahSettings: {
        Prayer.fajr: 10,
        Prayer.dhuhr: 20,
        Prayer.asr: 15,
        Prayer.maghrib: 5,
        Prayer.isha: 20,
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(tzdata.initializeTimeZones);

  group('IqamahDraft sync', () {
    late ProviderContainer container;
    late ProviderSubscription<IqamahDraftState> draftSub;

    setUp(() async {
      container = ProviderContainer(
        overrides: [
          prayerSettingsProvider.overrideWith(_TestPrayerSettings.new),
        ],
      );
      await container.read(prayerSettingsProvider.future);
      // Keep autoDispose draft alive across the test body.
      draftSub = container.listen(iqamahDraftProvider, (_, _) {});
    });

    tearDown(() {
      draftSub.close();
      container.dispose();
    });

    test('edit A + save B preserves unsaved A draft', () async {
      final draft = container.read(iqamahDraftProvider.notifier);

      draft.controller(Prayer.fajr).text = '42';
      expect(draft.isUnsaved(Prayer.fajr), isTrue);
      expect(draft.controller(Prayer.fajr).text, '42');

      container
          .read(prayerSettingsProvider.notifier)
          .updatePrayerIqamahTime(Prayer.dhuhr, 30);

      // Allow listen → sync to run.
      await Future<void>.delayed(Duration.zero);

      expect(draft.controller(Prayer.fajr).text, '42');
      expect(draft.isUnsaved(Prayer.fajr), isTrue);
      expect(draft.controller(Prayer.dhuhr).text, '30');
      expect(draft.isUnsaved(Prayer.dhuhr), isFalse);
    });
  });
}
