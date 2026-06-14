import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/feature/prayer/domain/services/adhan_time_utils.dart';

/// Category of scheduled prayer alert (adhan, iqamah, or sunnah time).
enum PrayerAlertKind {
  /// Obligatory prayer adhan.
  adhan,

  /// Iqamah after adhan when an offset is configured.
  iqamah,

  /// Sunnah time (sunrise, middle of night, last third).
  sunnah,
}

/// Sunnah prayers that can trigger notify-only alerts.
const List<Prayer> sunnahAlertPrayers = [
  Prayer.sunrise,
  Prayer.fajrAfter,
  Prayer.ishaBefore,
];

/// Obligatory prayers — alias for scheduler use.
const List<Prayer> obligatoryAlertPrayers = obligatoryAdhanPrayers;
