import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';

void main() {
  final cardInfo1 = PrayerTrackerCardModel(
      completion: PrayerCompletion(
        prayer: Prayer.fajr,
        id: 2,
        completionTime: DateTime(2023, 10, 1, 5, 30),
        status: CompletionStatus.jamaah,
      ),
      prayer: Prayer.asr,
      adhan: "4:00 PM",
      subtitle: '1 hour ago',
      isCurrentPrayer: false,
      isTimePassed: true);

  final cardInfo2 = PrayerTrackerCardModel(
      completion: PrayerCompletion(
        prayer: Prayer.fajr,
        id: 2,
        completionTime: DateTime(2023, 10, 1, 5, 30),
        status: CompletionStatus.onTime,
      ),
      prayer: Prayer.asr,
      adhan: "4:00 PM",
      subtitle: '1 hour ago',
      isCurrentPrayer: false,
      isTimePassed: true);
  print(cardInfo1 == cardInfo2);
  assert(cardInfo1 == cardInfo2, "The two card models should be equal.");
}
