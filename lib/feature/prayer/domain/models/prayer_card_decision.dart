import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_card_decision.freezed.dart';

/// Lightweight DTO that captures only the data a UI needs to render a single
/// prayer card.
///
/// * [referenceTime] – the timestamp the card should **count to** (if
///   [isCountdown] is `true`) or how long **ago** it occurred (if `false`).
/// * [prayer]        – which prayer the card is about.
/// * [isCountdown]   – `true`  ➜ show time *until*  [referenceTime]
///                     `false` ➜ show time *since* [referenceTime].
@freezed
abstract class PrayerCardDecision with _$PrayerCardDecision {
  const factory PrayerCardDecision({
    required DateTime referenceTime,
    required Prayer prayer,
    required bool isCountdown,
  }) = _PrayerCardDecision;
}
