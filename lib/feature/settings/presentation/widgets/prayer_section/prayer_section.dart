import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/utils/text_extensions.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/sections/time_section.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerSection extends ConsumerStatefulWidget {
  final double maxWidth;
  const PrayerSection({super.key, this.maxWidth = 800});

  @override
  ConsumerState<PrayerSection> createState() => _PrayerSectionState();
}

class _PrayerSectionState extends ConsumerState<PrayerSection>
    with TickerProviderStateMixin {
  late final FSelectController<tz.Location> _locationController;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: "اعدادات الصلاة",
      subtitle: "الإعدادات الخاصة بالصلاة ومواقيتها وتعقبها.",
      sections: [
        SettingsSection(
          crossAxisAlignment: CrossAxisAlignment.center,
          title: "الموقع والحساب",
          subtitle: "تحديد الموقع الجغرافي وطريقة حساب مواقيت الصلاة.",
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            child: Column(
              spacing: 20,
              children: [
                FCard(
                  title: const Text("الإحداثيات الجغرافية"),
                  child: Column(
                    spacing: 8,
                    children: [
                      // Location selection buttons
                      Row(
                        spacing: 12,
                        children: [
                          Expanded(
                            child: FButton(
                              onPress: () {
                                // Placeholder - open map for location selection
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FIcons.mapPin, size: 16),
                                  SizedBox(width: 8),
                                  Text("خريطة"),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: FButton(
                              onPress: () {
                                // Placeholder - open city search
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FIcons.search, size: 16),
                                  SizedBox(width: 8),
                                  Text("البحث"),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: FButton(
                              onPress: () {
                                // Placeholder - detect current location
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FIcons.navigation, size: 16),
                                  SizedBox(width: 8),
                                  Text("الحالي"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Coordinates display
                      const Row(
                        spacing: 12,
                        children: [
                          Expanded(
                            child: FTextField(
                              label: Text('خط العرض'),
                              hint: '21.55826',
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true, signed: false),
                            ),
                          ),
                          Expanded(
                            child: FTextField(
                              label: Text('خط الطول'),
                              hint: '39.26189',
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true, signed: false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: FCard(
                        title: const Text("المنطقة الزمنية"),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: FSelect<tz.Location>.search(
                                controller: _locationController,
                                searchFieldProperties:
                                    const FSelectSearchFieldProperties(
                                  hint: "ابحث للمزيد من الخيارات",
                                ),
                                emptyBuilder: (context, value, child) =>
                                    Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 8,
                                    children: [
                                      const Icon(FIcons.searchX),
                                      const Text("لا يوجد نتائج").sm,
                                    ],
                                  ),
                                ),
                                onChange: (value) {
                                  if (value == null) return;
                                  _locationController.value = value;
                                  ref
                                      .read(prayerSettingsNotifierProvider
                                          .notifier)
                                      .setLocation(value);
                                },
                                format: (p0) {
                                  return p0.name;
                                },
                                contentBuilder: (context, data) {
                                  return [
                                    for (final loc in data.values.whereIndexed(
                                        (index, loc) => index < 16))
                                      FSelectItem(loc.name, loc)
                                  ];
                                },
                                searchLoadingBuilder: (context, value, child) =>
                                    const FProgress.circularIcon(),
                                filter: (query) async {
                                  final location = await _loadTimezones();
                                  return query.isEmpty
                                      ? location
                                      : location.where((loc) => loc.name
                                          .toLowerCase()
                                          .contains(query.toLowerCase()));
                                },
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: FButton.icon(
                                child: const Icon(FIcons.locate),
                                onPress: () async {
                                  final String currentTimeZone =
                                      await FlutterTimezone.getLocalTimezone();
                                  final location =
                                      tz.getLocation(currentTimeZone);
                                  _locationController.value = location;
                                  ref
                                      .read(prayerSettingsNotifierProvider
                                          .notifier)
                                      .setLocation(location);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: FCard(
                        title: const Text("طريقة الحساب"),
                        child: FSelect<String>(
                          format: (value) => value,
                          children: [
                            FSelectItem("رابطة العالم الإسلامي",
                                "رابطة العالم الإسلامي"),
                            FSelectItem("جامعة أم القرى", "جامعة أم القرى"),
                            FSelectItem("الهيئة المصرية العامة للمساحة",
                                "الهيئة المصرية العامة للمساحة"),
                            FSelectItem("جامعة العلوم الإسلامية كراتشي",
                                "جامعة العلوم الإسلامية كراتشي"),
                          ],
                          onChange: (value) {
                            // Placeholder - no functionality
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        TimeSection(maxWidth: widget.maxWidth)
      ],
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final location = ref.read(prayerSettingsNotifierProvider);
    _locationController = FSelectController<tz.Location>(
        vsync: this, value: location.valueOrNull?.location);
  }

  Future<List<tz.Location>> _loadTimezones() async {
    final commonTimezones = [
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

    return Future.microtask(() {
      final database = tz.timeZoneDatabase;
      final allLocations = database.locations.values.toList();
      final currentLocation =
          ref.read(prayerSettingsNotifierProvider).valueOrNull?.location;

      // Sort with selected location first, then common timezones, then alphabetically
      allLocations.sort((a, b) {
        // Selected location always comes first
        if (currentLocation != null) {
          if (a.name == currentLocation.name) return -1;
          if (b.name == currentLocation.name) return 1;
        }

        // Then common timezones (excluding the selected one to avoid duplication)
        final aIsCommon =
            commonTimezones.contains(a.name) && a.name != currentLocation?.name;
        final bIsCommon =
            commonTimezones.contains(b.name) && b.name != currentLocation?.name;

        if (aIsCommon && !bIsCommon) return -1;
        if (!aIsCommon && bIsCommon) return 1;

        return a.name.compareTo(b.name);
      });

      return allLocations;
    });
  }
}
