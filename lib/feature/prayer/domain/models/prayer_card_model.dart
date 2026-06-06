import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_card_model.freezed.dart';

/// Model representing information for a prayer card.
@freezed
abstract class PrayerCardInfo with _$PrayerCardInfo {
  /// Creates a [PrayerCardInfo] instance.
  const factory PrayerCardInfo({
    /// Countdown until the next anchor, or elapsed time since the current one
    /// (prefixed with `+`), formatted as `HH:MM:SS`.
    required String time,
    required Prayer prayer,
    required String adhanTime,
    required String iqamahTime,

    /// Whether the anchor time has passed and the user may log a status.
    required bool canSetStatus,

    /// Whether an iqamah offset is configured for [prayer].
    required bool showIqamah,
  }) = _PrayerCardInfo;

  /// Creates an empty [PrayerCardInfo] instance with default values.
  factory PrayerCardInfo.empty() => const PrayerCardInfo(
    time: '00:00',
    prayer: Prayer.fajrAfter,
    adhanTime: '00:00',
    iqamahTime: '00:00',
    canSetStatus: false,
    showIqamah: false,
  );
}
