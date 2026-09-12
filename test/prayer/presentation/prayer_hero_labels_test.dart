import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/hero_header/prayer_hero_labels.dart';
import 'package:tawaq/l10n/app_localizations_ar.dart';
import 'package:tawaq/l10n/app_localizations_en.dart';

void main() {
  group('prayer hero labels', () {
    test('describes elapsed current-prayer time in English', () {
      final l10n = AppLocalizationsEn();

      expect(
        prayerCardStateLabel(
          l10n: l10n,
          prayer: Prayer.dhuhr,
          isCountdown: false,
        ),
        'Current Prayer',
      );
      expect(
        prayerCardDurationLabel(
          l10n: l10n,
          prayer: Prayer.dhuhr,
          isCountdown: false,
        ),
        'Since prayer began',
      );
    });

    test('describes remaining next-prayer time in English', () {
      final l10n = AppLocalizationsEn();

      expect(
        prayerCardStateLabel(
          l10n: l10n,
          prayer: Prayer.asr,
          isCountdown: true,
        ),
        'Next Prayer',
      );
      expect(
        prayerCardDurationLabel(
          l10n: l10n,
          prayer: Prayer.asr,
          isCountdown: true,
        ),
        'Time remaining',
      );
    });

    test('localizes both state directions in Arabic', () {
      final l10n = AppLocalizationsAr();

      expect(
        prayerCardStateLabel(
          l10n: l10n,
          prayer: Prayer.dhuhr,
          isCountdown: false,
        ),
        'الصلاة الحالية',
      );
      expect(
        prayerCardDurationLabel(
          l10n: l10n,
          prayer: Prayer.dhuhr,
          isCountdown: false,
        ),
        'منذ بداية الصلاة',
      );
      expect(
        prayerCardStateLabel(
          l10n: l10n,
          prayer: Prayer.dhuhr,
          isCountdown: true,
        ),
        'الصلاة القادمة',
      );
      expect(
        prayerCardDurationLabel(
          l10n: l10n,
          prayer: Prayer.dhuhr,
          isCountdown: true,
        ),
        'الوقت المتبقي',
      );
    });

    test('uses neutral event wording for pseudo-prayer slots', () {
      final l10n = AppLocalizationsEn();

      for (final prayer in [
        Prayer.sunrise,
        Prayer.fajrAfter,
        Prayer.ishaBefore,
      ]) {
        expect(
          prayerCardStateLabel(
            l10n: l10n,
            prayer: prayer,
            isCountdown: false,
          ),
          'Current event',
        );
        expect(
          prayerCardDurationLabel(
            l10n: l10n,
            prayer: prayer,
            isCountdown: false,
          ),
          'Since event began',
        );
        expect(
          prayerCardStateLabel(
            l10n: l10n,
            prayer: prayer,
            isCountdown: true,
          ),
          'Next event',
        );
      }
    });

    test('keeps pseudo-prayer names localized exactly', () {
      final l10n = AppLocalizationsEn();

      expect(Prayer.sunrise.getLocaleName(l10n), 'Sunrise');
      expect(Prayer.fajrAfter.getLocaleName(l10n), 'Midnight');
      expect(
        Prayer.ishaBefore.getLocaleName(l10n),
        'Last Third Of The Night',
      );
    });
  });
}
