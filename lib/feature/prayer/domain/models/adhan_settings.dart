import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/models/schedule_alert_mode.dart';
import 'package:tawaq/gen/assets.gen.dart';

part 'adhan_settings.freezed.dart';
part 'adhan_settings.g.dart';

Duration _durationFromJson(int seconds) => Duration(seconds: seconds);
int _durationToJson(Duration duration) => duration.inSeconds;

/// Bundled adhan muezzin / style variants.
enum AdhanSound {
  /// Mishary Alafasi (legacy persisted key: `default`).
  @JsonValue('default')
  misharyAlafasi,

  /// Makkah adhan recording.
  @JsonValue('makkah')
  makkah,

  /// Abed Albasaei adhan recording.
  @JsonValue('abed_albasaei')
  abedAlbasaei,

  /// Ahmad Nufais adhan recording.
  @JsonValue('ahmad_nufais')
  ahmadNufais,

  /// Ghazi Al Saadoni adhan recording.
  @JsonValue('ghazi_al_saadoni')
  ghaziAlSaadoni,

  /// Hamad Deghreri adhan recording.
  @JsonValue('hamad_deghreri')
  hamadDeghreri,

  /// Hamdan Al Malki adhan recording.
  @JsonValue('hamdan_al_malki')
  hamdanAlMalki,

  /// Ibrahim Al Arkani adhan recording.
  @JsonValue('ibrahim_al_arkani')
  ibrahimAlArkani,

  /// Majed Al Hamathani adhan recording.
  @JsonValue('majed_al_hamathani')
  majedAlHamathani,

  /// Mansoor Al Zahrani adhan recording.
  @JsonValue('mansoor_al_zahrani')
  mansoorAlZahrani,

  /// Mohammad Al Menshawy adhan recording.
  @JsonValue('mohammad_al_menshawy')
  mohammadAlMenshawy,

  /// Mohammad Refat adhan recording.
  @JsonValue('mohammad_refat')
  mohammadRefat,

  /// Nasser Al Qatami adhan recording.
  @JsonValue('nasser_al_qatami')
  nasserAlQatami,

  /// Suhaib Khatba adhan recording.
  @JsonValue('suhaib_khatba')
  suhaibKhatba,
}

/// Bundled iqamah call variants.
enum IqamahSound {
  /// Mishary Alafasi (legacy persisted key: `default`).
  @JsonValue('default')
  misharyAlafasi,

  /// Yasser Al Dossari iqamah recording.
  @JsonValue('yasser_al_dossari')
  yasserAlDossari,

  /// Makkah iqamah recording.
  @JsonValue('makkah')
  makkah,

  /// Madinah iqamah recording.
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
  const factory({
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

    /// Hard ceiling guarding against a stuck/never-completing adhan sound.
    /// Stored in seconds for JSON compactness; defaults to 8 minutes.
    @JsonKey(
      name: 'sound_safety_cap_seconds',
      fromJson: _durationFromJson,
      toJson: _durationToJson,
    )
    @Default(Duration(minutes: 8))
    Duration soundSafetyCap,
  }) = _AdhanSettings;

  /// Default adhan settings.
  factory defaults() {
    return AdhanSettings(
      adhanModes: {
        for (final p in obligatoryAlertPrayers) p: ScheduleAlertMode.sound,
      },
      sunnahModes: {
        for (final p in sunnahAlertPrayers) p: ScheduleAlertMode.notifyOnly,
      },
    );
  }

  /// Parses persisted JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$AdhanSettingsFromJson(json);
}

/// Default alert mode for [kind].
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
