import 'package:timezone/timezone.dart' as tz;

/// Frequently used IANA timezone ids shown near the top of pickers.
const commonTimezones = <String>[
  'Asia/Riyadh',
  'Asia/Dubai',
  'Asia/Kuwait',
  'Asia/Qatar',
  'Asia/Bahrain',
  'Africa/Cairo',
  'Asia/Baghdad',
  'Asia/Damascus',
  'Asia/Amman',
  'Asia/Beirut',
  'Europe/Istanbul',
  'Europe/London',
  'Europe/Paris',
  'America/New_York',
  'America/Los_Angeles',
  'Asia/Tokyo',
  'Australia/Sydney',
];

/// Returns all known timezones sorted for settings UI.
///
/// [selected] is pinned first, then [commonTimezones], then alphabetical.
List<tz.Location> sortTimezones({
  required Iterable<tz.Location> locations,
  tz.Location? selected,
}) {
  final allLocations = locations.toList()
    ..sort((a, b) {
      if (selected != null) {
        if (a.name == selected.name) return -1;
        if (b.name == selected.name) return 1;
      }

      final aIsCommon =
          commonTimezones.contains(a.name) && a.name != selected?.name;
      final bIsCommon =
          commonTimezones.contains(b.name) && b.name != selected?.name;

      if (aIsCommon && !bIsCommon) return -1;
      if (!aIsCommon && bIsCommon) return 1;

      return a.name.compareTo(b.name);
    });

  return allLocations;
}
