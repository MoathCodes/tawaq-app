import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/settings/data/models/adhan_settings.dart';
import 'package:tawaq/gen/assets.gen.dart';

void main() {
  group('AdhanSound.assetPathFor', () {
    test('all muezzins share the same Fajr recording', () {
      for (final sound in AdhanSound.values) {
        expect(
          sound.assetPathFor(Prayer.fajr),
          Assets.audio.adhan.fajr,
        );
      }
    });

    test('non-Fajr prayers use the selected muezzin asset', () {
      expect(
        AdhanSound.misharyAlafasi.assetPathFor(Prayer.dhuhr),
        Assets.audio.adhan.misharyAlafasi,
      );
      expect(
        AdhanSound.makkah.assetPathFor(Prayer.isha),
        Assets.audio.adhan.makkah,
      );
      expect(
        AdhanSound.nasserAlQatami.assetPathFor(Prayer.asr),
        Assets.audio.adhan.nasserAlQatami,
      );
    });
  });

  group('IqamahSound.assetPathFor', () {
    test('each variant maps to its bundled iqamah asset', () {
      expect(
        IqamahSound.misharyAlafasi.assetPathFor(Prayer.dhuhr),
        Assets.audio.iqamah.misharyAlafasi,
      );
      expect(
        IqamahSound.yasserAlDossari.assetPathFor(Prayer.maghrib),
        Assets.audio.iqamah.yasserAlDossari,
      );
      expect(
        IqamahSound.makkah.assetPathFor(Prayer.isha),
        Assets.audio.iqamah.makkah,
      );
      expect(
        IqamahSound.madinah.assetPathFor(Prayer.asr),
        Assets.audio.iqamah.madinah,
      );
    });
  });
}
