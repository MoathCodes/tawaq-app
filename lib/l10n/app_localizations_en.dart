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
  String get adhanAdjustments => 'Adhan adjustments (minutes)';

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
  String get advancedSettingsTitle => 'Advanced Settings';

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
  String get autoSelectOrMap => 'Auto Select or Map';

  @override
  String get back => 'Back';

  @override
  String get basicParametersTitle => 'Basic Parameters';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String get blue => 'Blue';

  @override
  String get calculationMethod => 'Calculation Method';

  @override
  String get cancel => 'Cancel';

  @override
  String get changingTimezone => 'Changing Timezone';

  @override
  String get chooseCalculationMethod => 'Choose your calculation method';

  @override
  String get chooseLocation => 'Choose Location';

  @override
  String get colorTheme => 'Color Theme';

  @override
  String get colorThemeSubtitle => 'Change the apps color themes.';

  @override
  String get completed => 'Completed •';

  @override
  String get completionStatus => 'Completion Status';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get currentPrayer => 'Current Prayer';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get customParametersCollapsedHint =>
      'Tap to configure custom calculation parameters';

  @override
  String get customParametersLabel => 'Custom parameters';

  @override
  String get customParametersTitle => 'Custom Parameters';

  @override
  String get dark => 'Dark';

  @override
  String get detectTimezone => 'Detect timezone';

  @override
  String get detectTimezoneNotImplemented =>
      'Timezone detection is not implemented here.';

  @override
  String get deviceLocationNotImplemented =>
      'Using device location is not implemented here.';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get done => 'Done';

  @override
  String get dragTheMapTip => 'Drag the map to position the pin';

  @override
  String get dubai => 'Dubai';

  @override
  String get editsSavedDescription =>
      'Your changes have been saved successfully.';

  @override
  String get editsSavedTitle => 'Edits were saved';

  @override
  String get egyptian => 'Egyptian General Authority of Survey';

  @override
  String get english => 'English';

  @override
  String get errorNotFoundPage =>
      'we couldn\'t find this page please make sure you entered the correct url.';

  @override
  String errorOccurredWhile(String whileError) {
    return 'Error Occurred While $whileError';
  }

  @override
  String get errorUpdatingLocationDescription =>
      'Your coordinates were updated successfully, but we couldn\'t get your location name. This won\'t affect the app\'s functionality.';

  @override
  String get errorUpdatingLocationTitle =>
      'Error occurred while updating location';

  @override
  String get fajr => 'Fajir';

  @override
  String get fajrAngleLabel => 'Fajr Angle (°)';

  @override
  String get gettingLocation => 'Getting Location';

  @override
  String get green => 'Green';

  @override
  String get hadith => 'Hadith';

  @override
  String get highLatitudeRule_middleOfTheNight => 'Middle of the Night';

  @override
  String get highLatitudeRule_seventhOfTheNight => 'Seventh of the Night';

  @override
  String get highLatitudeRule_twilightAngle => 'Twilight Angle';

  @override
  String get highLatitudeRuleLabel => 'High Latitude Rule';

  @override
  String get invalidCoordinatesDescription =>
      'Please enter valid latitude and longitude values.';

  @override
  String get invalidCoordinatesTitle => 'Invalid Coordinates';

  @override
  String get invalidParametersDescription => 'Please check your input values.';

  @override
  String get invalidParametersTitle => 'Invalid Parameters';

  @override
  String get iqamah => 'Iqamah';

  @override
  String get iqamahAdjustment => 'Iqamah Adjustment';

  @override
  String get iqamahAfterAdhan => 'Iqamah (minutes after adhan)';

  @override
  String get iqamahSavedDescription =>
      'Your iqamah adjustments have been saved successfully.';

  @override
  String get iqamahSavedTitle => 'Iqamah adjustments saved';

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
  String get ishaAngleLabel => 'Isha Angle (°)';

  @override
  String get ishaIntervalLabel => 'Isha Interval (min)';

  @override
  String get islamicTheme => 'Manuscript';

  @override
  String get jamaah => 'Jamaah';

  @override
  String get jamaahRate => 'Jamaah Rate';

  @override
  String get jumuah => 'Jumuah';

  @override
  String get karachi => 'University of Islamic Sciences, Karachi';

  @override
  String get kuwait => 'Kuwait';

  @override
  String get lastThirdOfTheNight => 'Last Third Of The Night';

  @override
  String get late => 'Late';

  @override
  String get lateRate => 'Late Rate';

  @override
  String get latitude => 'Latitude';

  @override
  String get light => 'Light';

  @override
  String get loadingLocationSettings => 'Loading Location Settings';

  @override
  String get locationSectionSubtitle =>
      'Set geographical location and prayer time calculation method.';

  @override
  String get locationSectionTitle => 'Location & Calculation';

  @override
  String get lockToPreventEdits => 'Lock to prevent edits';

  @override
  String get longitude => 'Longitude';

  @override
  String get madhab_hanafi => 'Hanafi';

  @override
  String get madhab_shafi => 'Shafi';

  @override
  String get madhabLabel => 'Madhab';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get maghribAngleLabel => 'Maghrib Angle (°)';

  @override
  String get midnight => 'Midnight';

  @override
  String get minute => 'minute';

  @override
  String get missed => 'Missed';

  @override
  String get missedRate => 'Missed Rate';

  @override
  String get monthly => 'Monthly';

  @override
  String get moonsightingCommittee => 'Moonsighting Committee';

  @override
  String get morocco => 'Morocco';

  @override
  String get muslimFortress => 'Muslim Fortress';

  @override
  String get muslimWorldLeague => 'Muslim World League';

  @override
  String get neutral => 'Neutral';

  @override
  String get next => 'Next';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get noResults => 'No results found.';

  @override
  String get northAmerica => 'North America (ISNA)';

  @override
  String get onTime => 'On Time';

  @override
  String get onTimePrayersLast30Days => 'On time prayers (last 30 days)';

  @override
  String get onTimePrayersLast365Days => 'On time prayers (last 365 days)';

  @override
  String get onTimePrayersLast7Days => 'On time prayers (last 7 days)';

  @override
  String get onTimeRate => 'On Time Rate';

  @override
  String get optionalHint => 'Optional';

  @override
  String get orange => 'Orange';

  @override
  String get other => 'Other';

  @override
  String get pageNotFound => 'Page Not Found';

  @override
  String get pageNotFoundDescription =>
      'This page doesn\'t exist. Please go back to the home page.';

  @override
  String get parametersSavedDescription =>
      'Your custom parameters have been saved successfully.';

  @override
  String get parametersSavedTitle => 'Parameters Saved';

  @override
  String get placeholdersHint =>
      'Madhab and other options can be configured later. These inputs are placeholders.';

  @override
  String get playerAnalytics => 'Player Analytics';

  @override
  String get pleaseSelectMethod => 'Please select a calculation method.';

  @override
  String get prayer => 'Prayer';

  @override
  String get prayerSettingsSubtitle =>
      'Settings for prayer times, tracking, and related configurations.';

  @override
  String get prayerSettingsTitle => 'Prayer Settings';

  @override
  String get prayerTimeAdjustmentsTitle => 'Prayer Time Adjustments (minutes)';

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
  String get qatar => 'Qatar';

  @override
  String get quran => 'Holy Quran';

  @override
  String get red => 'Red';

  @override
  String get remembrance => 'Remembrance';

  @override
  String get resetCompleteDescription =>
      'Parameters have been reset to default values.';

  @override
  String get resetCompleteTitle => 'Reset Complete';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get rose => 'Rose';

  @override
  String get save => 'Save';

  @override
  String get saveParameters => 'Save Parameters';

  @override
  String get searchForMore => 'Search for more options';

  @override
  String get searchPlaceLabel => 'Search for a place';

  @override
  String get settings => 'Settings';

  @override
  String get setupPrayerSettingsSubtitle =>
      'We\'ll guide you through a few quick steps. You can change these later in Settings.';

  @override
  String get setupPrayerSettingsTitle => 'Let\'s set up your prayer settings.';

  @override
  String get setupPreferences => 'Let\'s set up your preferences.';

  @override
  String get signedExampleHint => '20 or -10';

  @override
  String get singapore => 'Singapore';

  @override
  String get skip => 'Skip';

  @override
  String get slate => 'Slate';

  @override
  String get status => 'Status';

  @override
  String get stone => 'Stone';

  @override
  String streakInDays(int streak) {
    return '$streak days';
  }

  @override
  String get sunrise => 'Sunrise';

  @override
  String get tehran => 'Tehran';

  @override
  String get timeFormat => 'Time Format';

  @override
  String get timeSectionSubtitle =>
      'Configure time display format and Iqamah times for each prayer.';

  @override
  String get timeSectionTitle => 'Time Display & Iqamah';

  @override
  String get timezone => 'Timezone';

  @override
  String get tipHoldCtrlToRotate =>
      'Tip: Hold Ctrl and drag to rotate and tilt the map.';

  @override
  String get toggleArabic => 'Toggle Arabic';

  @override
  String get turkiye => 'Turkey (Diyanet)';

  @override
  String get ummAlQura => 'Umm Al-Qura University';

  @override
  String get unlockToEditCoordinates => 'Unlock to edit coordinates';

  @override
  String get use24HourFormat => 'Use 24-hour format';

  @override
  String get useDeviceLocation => 'Use device location';

  @override
  String get useMyLocation => 'Use My Location';

  @override
  String get useSystemTimezone => 'Use System Timezone';

  @override
  String get violet => 'Violet';

  @override
  String get weekly => 'Weekly';

  @override
  String get welcomeToApp => 'Welcome to the app!';

  @override
  String get wizardStep_calculationMethod => 'Calculation Method';

  @override
  String get wizardStep_getStarted => 'Get Started';

  @override
  String get wizardStep_iqamahAdjustments => 'Iqamah & Adjustments';

  @override
  String get wizardStep_location => 'Location';

  @override
  String get wizardStep_timeFormat => 'Time Format';

  @override
  String get wizardStep_welcome => 'Welcome';

  @override
  String get yearly => 'Yearly';

  @override
  String get yellow => 'Yellow';

  @override
  String get zinc => 'Zinc';
}
