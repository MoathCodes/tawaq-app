import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Localized labels for [AdhanSound] muezzin variants.
extension AdhanSoundLocale on AdhanSound {
  /// Returns the localized muezzin name for the adhan sound picker.
  String getLocaleName(AppLocalizations l10n) {
    return switch (this) {
      AdhanSound.misharyAlafasi => l10n.adhanMuezzinMisharyAlafasi,
      AdhanSound.makkah => l10n.adhanMuezzinMakkah,
      AdhanSound.abedAlbasaei => l10n.adhanMuezzinAbedAlbasaei,
      AdhanSound.ahmadNufais => l10n.adhanMuezzinAhmadNufais,
      AdhanSound.ghaziAlSaadoni => l10n.adhanMuezzinGhaziAlSaadoni,
      AdhanSound.hamadDeghreri => l10n.adhanMuezzinHamadDeghreri,
      AdhanSound.hamdanAlMalki => l10n.adhanMuezzinHamdanAlMalki,
      AdhanSound.ibrahimAlArkani => l10n.adhanMuezzinIbrahimAlArkani,
      AdhanSound.majedAlHamathani => l10n.adhanMuezzinMajedAlHamathani,
      AdhanSound.mansoorAlZahrani => l10n.adhanMuezzinMansoorAlZahrani,
      AdhanSound.mohammadAlMenshawy => l10n.adhanMuezzinMohammadAlMenshawy,
      AdhanSound.mohammadRefat => l10n.adhanMuezzinMohammadRefat,
      AdhanSound.nasserAlQatami => l10n.adhanMuezzinNasserAlQatami,
      AdhanSound.suhaibKhatba => l10n.adhanMuezzinSuhaibKhatba,
    };
  }
}

/// Localized labels for [IqamahSound] variants.
extension IqamahSoundLocale on IqamahSound {
  /// Returns the localized name for the iqamah sound picker.
  String getLocaleName(AppLocalizations l10n) {
    return switch (this) {
      IqamahSound.misharyAlafasi => l10n.adhanMuezzinMisharyAlafasi,
      IqamahSound.yasserAlDossari => l10n.iqamahMuezzinYasserAlDossari,
      IqamahSound.makkah => l10n.adhanMuezzinMakkah,
      IqamahSound.madinah => l10n.iqamahMuezzinMadinah,
    };
  }
}
