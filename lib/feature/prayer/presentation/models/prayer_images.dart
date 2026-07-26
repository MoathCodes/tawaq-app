import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/gen/assets.gen.dart';

/// Extension on [Prayer] to provide UI-related assets and properties.
extension PrayerImageExtension on Prayer {
  /// Returns the preferred [Alignment] for the background image of this prayer.
  Alignment get alignment {
    return switch (this) {
      Prayer.fajr => Alignment.bottomCenter,
      Prayer.sunrise => Alignment.center,
      Prayer.dhuhr => Alignment.bottomCenter,
      Prayer.asr => Alignment.topCenter,
      Prayer.maghrib => Alignment.bottomCenter,
      Prayer.isha => Alignment.bottomCenter,
      Prayer.ishaBefore => Alignment.bottomCenter,
      Prayer.fajrAfter => Alignment.bottomCenter,
    };
  }

  /// Returns the [IconData] associated with this prayer.
  IconData get icon {
    return switch (this) {
      Prayer.fajr => FLucideIcons.sunrise,
      Prayer.sunrise => FLucideIcons.sun,
      Prayer.dhuhr => FLucideIcons.sunMedium,
      Prayer.asr => FLucideIcons.sunDim,
      Prayer.maghrib => FLucideIcons.sunset,
      Prayer.isha => FLucideIcons.moon,
      Prayer.ishaBefore => FLucideIcons.moonStar,
      Prayer.fajrAfter => FLucideIcons.sunrise,
    };
  }

  
}
