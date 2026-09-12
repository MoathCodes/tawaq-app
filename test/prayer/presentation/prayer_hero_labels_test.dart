import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/hero_header/prayer_hero_labels.dart';
import 'package:tawaq/l10n/app_localizations_ar.dart';
import 'package:tawaq/l10n/app_localizations_en.dart';

void main() {
  group('prayer hero labels', () {
    test('describes elapsed current-prayer time in English', () {
      final l10n = AppLocalizationsEn();

      expect(
        prayerCardStateLabel(l10n: l10n, isCountdown: false),
        'Current Prayer',
      );
      expect(
        prayerCardDurationLabel(l10n: l10n, isCountdown: false),
        'Since prayer began',
      );
    });

    test('describes remaining next-prayer time in English', () {
      final l10n = AppLocalizationsEn();

      expect(
        prayerCardStateLabel(l10n: l10n, isCountdown: true),
        'Next Prayer',
      );
      expect(
        prayerCardDurationLabel(l10n: l10n, isCountdown: true),
        'Time remaining',
      );
    });

    test('localizes both state directions in Arabic', () {
      final l10n = AppLocalizationsAr();

      expect(
        prayerCardStateLabel(l10n: l10n, isCountdown: false),
        'الصلاة الحالية',
      );
      expect(
        prayerCardDurationLabel(l10n: l10n, isCountdown: false),
        'منذ بداية الصلاة',
      );
      expect(
        prayerCardStateLabel(l10n: l10n, isCountdown: true),
        'الصلاة القادمة',
      );
      expect(
        prayerCardDurationLabel(l10n: l10n, isCountdown: true),
        'الوقت المتبقي',
      );
    });
  });
}
