import 'package:flutter/material.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section.dart';

/// Location settings tab body.
class SettingsLocationTab extends StatelessWidget {
  /// Creates [SettingsLocationTab].
  const SettingsLocationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrayerLocationSettings();
  }
}
