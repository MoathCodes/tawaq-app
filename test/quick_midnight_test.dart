import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/use_cases/compute_prayer_card_decision.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  tz.initializeTimeZones();

  // Test the specific 11:15 PM scenario
  final location = getLocation('Asia/Riyadh');
  final testTime = TZDateTime(location, 2024, 1, 15, 23, 15);

  // Create mock prayer times data
  const coordinates = Coordinates(24.7136, 46.6753); // Riyadh
  final calculationParams = CalculationMethod.ummAlQura.getParams();

  // Create a Gregorian date for prayer calculations
  final gregorianDate = DateTime(2024, 1, 15);
  // final dateComponents = DateComponents.from(gregorianDate);

  // Calculate prayer times for the test date
  final prayerTimes = PrayerTimesData.calculate(
    coordinates: coordinates,
    date: gregorianDate,
    calculationParameters: calculationParams,
  );

  // Create prayer times data objects
  final todaysPrayerTimes = PrayerTimesData(
    date: gregorianDate,
    params: calculationParams,
    coordinates: coordinates,
    fajr: prayerTimes.fajr,
    sunrise: prayerTimes.sunrise,
    dhuhr: prayerTimes.dhuhr,
    asr: prayerTimes.asr,
    maghrib: prayerTimes.maghrib,
    isha: prayerTimes.isha,
    fajrAfter: prayerTimes.fajr.add(const Duration(days: 1)),
    ishaBefore: prayerTimes.isha.subtract(const Duration(days: 1)),
  );

  // Create sunnah times from prayer times
  final todaysSunnahTimes = SunnahTimes(prayerTimes);

  // Test the decision logic
  final decision = computePrayerCardDecision(
    currentTime: testTime,
    location: location,
    todaysPrayerTimes: todaysPrayerTimes,
    yesterdaysPrayerTimes: todaysPrayerTimes, // Using same for simplicity
    todaysSunnahTimes: todaysSunnahTimes,
    yesterdaysSunnahTimes: todaysSunnahTimes,
  );

  print("=== TEST RESULTS ===");
  print(
      "Test time: ${testTime.hour}:${testTime.minute.toString().padLeft(2, '0')}");
  print("Decision prayer: ${decision.prayer}");
  print("Reference time: ${decision.referenceTime}");
  print("Is countdown: ${decision.isCountdown}");
  print(
      "Duration until reference: ${decision.referenceTime.difference(testTime)}");

  // Check if midnight time comes from SunnahTimes
  final midnightFromSunnah =
      TZDateTime.from(todaysSunnahTimes.middleOfTheNight, location);
  final fajrFromPrayer = TZDateTime.from(todaysPrayerTimes.fajr, location);

  print("\n=== TIME SOURCE VERIFICATION ===");
  print("Midnight from SunnahTimes: $midnightFromSunnah");
  print("Fajr from PrayerTimes: $fajrFromPrayer");
  print("Decision reference time: ${decision.referenceTime}");
  print("Using SunnahTimes? ${decision.referenceTime == midnightFromSunnah}");

  // Verify the fix
  if (decision.prayer == Prayer.fajrAfter &&
      decision.isCountdown &&
      decision.referenceTime == midnightFromSunnah) {
    print("\n✅ SUCCESS: Midnight logic is working correctly!");
    print(
        "The prayer card will show countdown to midnight from SunnahTimes, not PrayerTimes.");
  } else {
    print("\n❌ FAILURE: Midnight logic needs fixing.");
  }
}
