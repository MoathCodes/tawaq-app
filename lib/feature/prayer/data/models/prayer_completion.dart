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
  none;

  /// Returns the color of the badge for this status.
  Color getBadgeColor({bool isDark = false}) {
    return switch (this) {
      CompletionStatus.jamaah =>
        isDark ? Colors.green.shade900 : Colors.green.shade600,
      CompletionStatus.onTime =>
        isDark ? Colors.yellow.shade900 : Colors.yellow.shade600,
      CompletionStatus.late =>
        isDark ? Colors.orange.shade900 : Colors.orange.shade600,
      CompletionStatus.missed =>
        isDark ? Colors.red.shade900 : Colors.red.shade600,
      CompletionStatus.none => Colors.transparent,
    };
  }

  /// Returns the icon for this status.
  IconData? getIcon() {
    return switch (this) {
      CompletionStatus.jamaah => FIcons.users,
      CompletionStatus.onTime => FIcons.checkCheck,
      CompletionStatus.late => FIcons.clock,
      CompletionStatus.missed => FIcons.circleX,
      CompletionStatus.none => null,
    };
  }

  /// Returns the localized name of this status.
  String getLocaleName(AppLocalizations locale) {
    switch (this) {
      case CompletionStatus.jamaah:
        return locale.jamaah;
      case CompletionStatus.onTime:
        return locale.onTime;
      case CompletionStatus.late:
        return locale.late;
      case CompletionStatus.missed:
        return locale.missed;
      case CompletionStatus.none:
        return '';
    }
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