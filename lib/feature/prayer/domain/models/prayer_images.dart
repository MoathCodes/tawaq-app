import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/gen/assets.gen.dart';

extension PrayerImageExtension on Prayer {
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

  IconData get icon {
    return switch (this) {
      Prayer.fajr => FIcons.sunrise,
      Prayer.sunrise => FIcons.sun,
      Prayer.dhuhr => FIcons.sunMedium,
      Prayer.asr => FIcons.sunDim,
      Prayer.maghrib => FIcons.sunset,
      Prayer.isha => FIcons.moon,
      Prayer.ishaBefore => FIcons.moonStar,
      Prayer.fajrAfter => FIcons.sunrise,
    };
  }

  String get imagePath {
    return switch (this) {
      Prayer.fajr => Assets.images.fajr.path,
      Prayer.sunrise => Assets.images.sunrise.path,
      Prayer.dhuhr => Assets.images.duhr.path,
      Prayer.asr => Assets.images.asr.path,
      Prayer.maghrib => Assets.images.magrib.path,
      Prayer.isha => Assets.images.isha.path,
      Prayer.ishaBefore => Assets.images.lastThirdOfNight.path,
      Prayer.fajrAfter => Assets.images.midnight.path,
    };
  }
}
