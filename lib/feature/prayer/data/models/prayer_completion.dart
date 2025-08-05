import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/assets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hasanat/l10n/app_localizations.dart';

part 'prayer_completion.freezed.dart';
part 'prayer_completion.g.dart';

enum CompletionStatus {
  jamaah,
  onTime,
  late,
  missed,
  none;

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

  IconData? getIcon() {
    return switch (this) {
      CompletionStatus.jamaah => FIcons.users,
      CompletionStatus.onTime => FIcons.checkCheck,
      CompletionStatus.late => FIcons.clock,
      CompletionStatus.missed => FIcons.circleX,
      CompletionStatus.none => null,
    };
  }

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

@freezed
abstract class PrayerCompletion with _$PrayerCompletion {
  factory PrayerCompletion({
    required int? id,
    required Prayer prayer,
    required DateTime completionTime,
    required CompletionStatus status,
  }) = _PrayerCompletion;

  factory PrayerCompletion.fromJson(Map<String, dynamic> json) =>
      _$PrayerCompletionFromJson(json);
  // @override
  // Map<String, dynamic> toJson() => _$PrayerCompletionToJson(this);
}
