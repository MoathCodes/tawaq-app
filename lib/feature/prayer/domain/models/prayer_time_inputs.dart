import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart'
    show PrayerSettings;
import 'package:timezone/timezone.dart';

part 'prayer_time_inputs.freezed.dart';

/// Minimal prayer-time computation inputs derived from persisted settings.
///
/// Narrower than [PrayerSettings] so live clocks and schedulers rebuild only
/// when method, coordinates, timezone, or adhan adjustments change — not on
/// iqamah or format tweaks.
@freezed
abstract class PrayerTimeInputs with _$PrayerTimeInputs {
  /// Creates [PrayerTimeInputs].
  const factory({
    required CalculationMethod method,
    required Coordinates coordinates,
    required Location location,

    /// Per-prayer adhan minute offsets baked into the shared day timeline.
    @Default(<Prayer, int>{}) Map<Prayer, int> adhanAdjustments,
  }) = _PrayerTimeInputs;
}
