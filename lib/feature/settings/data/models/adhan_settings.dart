import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/models/schedule_alert_mode.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart' show AdhanSettingsNotifier;
import 'package:tawaq/gen/assets.gen.dart';

part 'adhan_settings.freezed.dart';
part 'adhan_settings.g.dart';

/// Bundled adhan muezzin / style variants.
enum AdhanSound {
  /// Mishary Alafasi (legacy persisted key: `default`).
  @JsonValue('default')
  misharyAlafasi,

  @JsonValue('makkah')
  makkah,

  @JsonValue('abed_albasaei')
  abedAlbasaei,

  @JsonValue('ahmad_nufais')
  ahmadNufais,

  @JsonValue('ghazi_al_saadoni')
  ghaziAlSaadoni,

  @JsonValue('hamad_deghreri')
  hamadDeghreri,

  @JsonValue('hamdan_al_malki')
  hamdanAlMalki,

  @JsonValue('ibrahim_al_arkani')
  ibrahimAlArkani,

  @JsonValue('majed_al_hamathani')
  majedAlHamathani,

  @JsonValue('mansoor_al_zahrani')
  mansoorAlZahrani,

  @JsonValue('mohammad_al_menshawy')
  mohammadAlMenshawy,

  @JsonValue('mohammad_refat')
  mohammadRefat,

  @JsonValue('nasser_al_qatami')
  nasserAlQatami,

  @JsonValue('suhaib_khatba')
  suhaibKhatba,
}

/// Bundled iqamah call variants.
enum IqamahSound {
  /// Mishary Alafasi (legacy persisted key: `default`).
  @JsonValue('default')
  misharyAlafasi,

  @JsonValue('yasser_al_dossari')
  yasserAlDossari,

  @JsonValue('makkah')
  makkah,

  @JsonValue('madinah')
  madinah,
}

/// Corner placement for the compact adhan alert window.
enum AdhanAlertPosition {
  /// Top trailing corner (respects RTL).
  @JsonValue('top_end')
  topEnd,

  /// Top leading corner (respects RTL).
  @JsonValue('top_start')
  topStart,

  /// Screen center.
  @JsonValue('center')
  center,
}

/// Extension methods for [AdhanSound].
extension AdhanSoundX on AdhanSound {
  /// Bundled asset path for [prayer].
  ///
  /// Fajr uses the shared [Assets.audio.adhan.fajr] recording for every muezzin
  /// until per-muezzin Fajr assets are available.
  String assetPathFor(Prayer prayer) {
    if (prayer == Prayer.fajr) {
      return Assets.audio.adhan.fajr;
    }

    final adhan = Assets.audio.adhan;
    return switch (this) {
      AdhanSound.misharyAlafasi => adhan.misharyAlafasi,
      AdhanSound.makkah => adhan.makkah,
      AdhanSound.abedAlbasaei => adhan.abedAlbasaei,
      AdhanSound.ahmadNufais => adhan.ahmadNufais,
      AdhanSound.ghaziAlSaadoni => adhan.ghaziAlSaadoni,
      AdhanSound.hamadDeghreri => adhan.hamadDeghreri,
      AdhanSound.hamdanAlMalki => adhan.hamdanAlMalki,
      AdhanSound.ibrahimAlArkani => adhan.ibrahimAlArkani,
      AdhanSound.majedAlHamathani => adhan.majedAlHamathani,
      AdhanSound.mansoorAlZahrani => adhan.mansoorAlZahrani,
      AdhanSound.mohammadAlMenshawy => adhan.mohammadAlMenshawy,
      AdhanSound.mohammadRefat => adhan.mohammadRefat,
      AdhanSound.nasserAlQatami => adhan.nasserAlQatami,
      AdhanSound.suhaibKhatba => adhan.suhaibKhatba,
    };
  }
}

/// Extension methods for [IqamahSound].
extension IqamahSoundX on IqamahSound {
  /// Bundled asset path for [prayer].
  String assetPathFor(Prayer prayer) {
    final iqamah = Assets.audio.iqamah;
    return switch (this) {
      IqamahSound.misharyAlafasi => iqamah.misharyAlafasi,
      IqamahSound.yasserAlDossari => iqamah.yasserAlDossari,
      IqamahSound.makkah => iqamah.makkah,
      IqamahSound.madinah => iqamah.madinah,
    };
  }
}

/// Persisted desktop prayer alert notification and playback preferences.
@freezed
abstract class AdhanSettings with _$AdhanSettings {
  /// Creates [AdhanSettings].
  const factory AdhanSettings({
    @JsonKey(
      name: 'enabled',
      fromJson: prayerAlertModesFromJson,
      toJson: prayerAlertModesToJson,
    )
    required Map<Prayer, ScheduleAlertMode> adhanModes,

    @JsonKey(
      name: 'iqamah_modes',
      fromJson: prayerAlertModesFromJson,
      toJson: prayerAlertModesToJson,
    )
    @Default({})
    Map<Prayer, ScheduleAlertMode> iqamahModes,

    @JsonKey(
      name: 'sunnah_modes',
      fromJson: prayerAlertModesFromJson,
      toJson: prayerAlertModesToJson,
    )
    @Default({})
    Map<Prayer, ScheduleAlertMode> sunnahModes,

    @Default(AdhanSound.misharyAlafasi) AdhanSound sound,
    @Default(IqamahSound.misharyAlafasi) IqamahSound iqamahSound,
    @Default(80) double volume,
    @Default(false) bool muteAll,

    /// How late (in minutes) a crossing may be noticed and still fire, e.g.
    /// after the machine wakes from sleep. Beyond this the alert is skipped
    /// rather than playing a stale adhan.
    ///
    /// 20 minutes is a deliberate grace: long enough that a prayer missed while
    /// the machine slept still fires when you come back shortly after, but
    /// short enough that it never bleeds into the next prayer (even
    /// maghrib→isha, which can be only ~30 min apart) or nags you about a call
    /// you already prayed an hour ago.
    @Default(20) int catchUpWindowMinutes,
    @Default(true) bool showAdhanAlert,
    @Default(true) bool showOsNotification,
    @Default(AdhanAlertPosition.topEnd) AdhanAlertPosition alertPosition,
  }) = _AdhanSettings;

  /// Default adhan settings.
  factory AdhanSettings.defaults() {
    return AdhanSettings(
      adhanModes: {
        for (final p in obligatoryAlertPrayers) p: ScheduleAlertMode.sound,
      },
      sunnahModes: {
        for (final p in sunnahAlertPrayers) p: ScheduleAlertMode.notifyOnly,
      },
    );
  }

  /// Parses JSON persisted by [AdhanSettingsNotifier].
  factory AdhanSettings.fromJson(Map<String, dynamic> json) =>
      _$AdhanSettingsFromJson(json);
}

/// Default alert mode when [kind] has no explicit entry for [prayer].
ScheduleAlertMode defaultScheduleAlertModeFor(PrayerAlertKind kind) {
  return switch (kind) {
    PrayerAlertKind.adhan => ScheduleAlertMode.sound,
    PrayerAlertKind.iqamah => ScheduleAlertMode.sound,
    PrayerAlertKind.sunnah => ScheduleAlertMode.notifyOnly,
  };
}

/// Returns the alert mode for [kind] and [prayer].
ScheduleAlertMode adhanSettingsModeFor(
  AdhanSettings settings,
  PrayerAlertKind kind,
  Prayer prayer,
) {
  final explicit = switch (kind) {
    PrayerAlertKind.adhan => settings.adhanModes[prayer],
    PrayerAlertKind.iqamah => settings.iqamahModes[prayer],
    PrayerAlertKind.sunnah => settings.sunnahModes[prayer],
  };

  return explicit ?? defaultScheduleAlertModeFor(kind);
}

/// Returns a copy of [settings] with [mode] set for [kind] and [prayer].
AdhanSettings adhanSettingsWithMode(
  AdhanSettings settings,
  PrayerAlertKind kind,
  Prayer prayer,
  ScheduleAlertMode mode,
) {
  final sanitized =
      kind == PrayerAlertKind.sunnah && mode == ScheduleAlertMode.sound
      ? ScheduleAlertMode.notifyOnly
      : mode;

  return switch (kind) {
    PrayerAlertKind.adhan => settings.copyWith(
      adhanModes: {...settings.adhanModes, prayer: sanitized},
    ),
    PrayerAlertKind.iqamah => settings.copyWith(
      iqamahModes: {...settings.iqamahModes, prayer: sanitized},
    ),
    PrayerAlertKind.sunnah => settings.copyWith(
      sunnahModes: {...settings.sunnahModes, prayer: sanitized},
    ),
  };
}
