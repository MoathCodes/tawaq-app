import 'package:adhan_dart/adhan_dart.dart';
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
