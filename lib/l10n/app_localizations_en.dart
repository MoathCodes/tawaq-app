// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get adhan => 'Adhan';

  @override
  String adhanHoursAgo(int hours) {
    final intl.NumberFormat hoursNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String hoursString = hoursNumberFormat.format(hours);

    return '$hoursString hours ago';
  }

  @override
  String adhanHoursLeft(int hours) {
    final intl.NumberFormat hoursNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String hoursString = hoursNumberFormat.format(hours);

    return '$hoursString hours left';
  }

  @override
  String adhanMinsAgo(int mins) {
    final intl.NumberFormat minsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String minsString = minsNumberFormat.format(mins);

    return '$minsString minutes ago';
  }

  @override
  String adhanMinsLeft(int mins) {
    final intl.NumberFormat minsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String minsString = minsNumberFormat.format(mins);

    return '$minsString minutes left';
  }

  @override
  String get appearance => 'Display Settings';

  @override
  String get appearanceSubtitle => 'Customize the app\'s appearance.';

  @override
  String get appName => 'Hasanat';

  @override
  String get arabic => 'Arabic';

  @override
  String get asr => 'Asr';

  @override
  String get blue => 'Blue';

  @override
  String get colorTheme => 'Color Theme';

  @override
  String get colorThemeSubtitle => 'Change the apps color themes.';

  @override
  String get completed => 'Completed •';

  @override
  String get completionStatus => 'Completion Status';

  @override
  String get currentPrayer => 'Current Prayer';

  @override
  String get dark => 'Dark';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get english => 'English';

  @override
  String get errorNotFoundPage =>
      'we couldn\'t find this page please make sure you entered the correct url.';

  @override
  String get fajr => 'Fajir';

  @override
  String get green => 'Green';

  @override
  String get hadith => 'Hadith';

  @override
  String get iqamah => 'Iqamah';

  @override
  String iqamahSubtitleMessage(int iqamahMins) {
    final intl.NumberFormat iqamahMinsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String iqamahMinsString = iqamahMinsNumberFormat.format(iqamahMins);

    return '+$iqamahMinsString minutes';
  }

  @override
  String get isha => 'Isha';

  @override
  String get islamicTheme => 'Manuscript';

  @override
  String get jamaah => 'Jamaah';

  @override
  String get lastThirdOfTheNight => 'Last Third Of The Night';

  @override
  String get late => 'Late';

  @override
  String get light => 'Light';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get midnight => 'Midnight';

  @override
  String get missed => 'Missed';

  @override
  String get muslimFortress => 'Muslim Fortress';

  @override
  String get neutral => 'Neutral';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get onTime => 'On Time';

  @override
  String get orange => 'Orange';

  @override
  String get prayer => 'Prayer';

  @override
  String get prayerTimes => 'Prayer Times';

  @override
  String get prayerTrackerSubtitle =>
      'Track your prayers and stay consistent, click on a prayer to mark it as completed.';

  @override
  String get prayerTrackerTitle => 'Prayer Tracker';

  @override
  String get prepareForPrayer => 'Prepare yourself for the prayer.';

  @override
  String get quran => 'Holy Quran';

  @override
  String get red => 'Red';

  @override
  String get remembrance => 'Remembrance';

  @override
  String get rose => 'Rose';

  @override
  String get settings => 'Settings';

  @override
  String get slate => 'Slate';

  @override
  String get status => 'Status';

  @override
  String get stone => 'Stone';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get toggleArabic => 'Toggle Arabic';

  @override
  String get violet => 'Violet';

  @override
  String get yellow => 'Yellow';

  @override
  String get zinc => 'Zinc';
}
