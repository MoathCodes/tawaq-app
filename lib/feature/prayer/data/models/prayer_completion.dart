import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/assets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hasanat/l10n/app_localizations.dart';

part 'prayer_completion.freezed.dart';
part 'prayer_completion.g.dart';

/// The status of a prayer completion.
enum CompletionStatus {
  /// The prayer was performed in congregation.
  jamaah,

  /// The prayer was performed on time.
  onTime,

  /// The prayer was performed late.
  late,

  /// The prayer was missed.
  missed,

  /// The prayer has not been performed yet.
  none
  ;

  /// Returns the color of the badge for this status.
  Color getBadgeColor({bool isDark = false}) {
    return switch (this) {
      .jamaah =>
        isDark
            ? const Color(0xFF4ade80) // Light emerald for dark mode
            : const Color(0xFF16a34a), // Darker emerald for light mode
      .onTime =>
        isDark
            ? const Color(0xFF38bdf8) // Light sky blue for dark mode
            : const Color(0xFF0284c7), // Darker sky blue for light mode
      .late =>
        isDark
            ? const Color(0xFFfbbf24) // Light amber for dark mode
            : const Color(0xFFd97706), // Darker amber for light mode
      .missed =>
        isDark
            ? const Color(0xFFf87171) // Light red for dark mode
            : const Color(0xFFdc2626), // Darker red for light mode
      .none => Colors.transparent,
    };
  }

  /// Returns the icon for this status.
  IconData? getIcon() {
    return switch (this) {
      .jamaah => FIcons.users,
      .onTime => FIcons.checkCheck,
      .late => FIcons.clock,
      .missed => FIcons.circleX,
      .none => null,
    };
  }

  /// Returns the localized name of this status.
  String getLocaleName(AppLocalizations locale) {
    return switch (this) {
      .jamaah => locale.jamaah,
      .onTime => locale.onTime,
      .late => locale.late,
      .missed => locale.missed,
      .none => '',
    };
  }
}

/// A prayer completion.
@freezed
abstract class PrayerCompletion with _$PrayerCompletion {
  /// Creates a new instance of [PrayerCompletion].
  factory PrayerCompletion({
    /// The unique identifier of the prayer completion.
    required int? id,

    /// The prayer that was completed.
    required Prayer prayer,

    /// The time the prayer was completed.
    required DateTime completionTime,

    /// The status of the prayer completion.
    required CompletionStatus status,
  }) = _PrayerCompletion;

  /// Creates a new instance of [PrayerCompletion] from a JSON object.
  factory PrayerCompletion.fromJson(Map<String, dynamic> json) =>
      _$PrayerCompletionFromJson(json);
  // @override
  // Map<String, dynamic> toJson() => _$PrayerCompletionToJson(this);
}
