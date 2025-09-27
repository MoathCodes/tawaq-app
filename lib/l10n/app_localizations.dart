import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @adhan.
  ///
  /// In en, this message translates to:
  /// **'Adhan'**
  String get adhan;

  /// No description provided for @adhanAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Adhan adjustments (minutes)'**
  String get adhanAdjustments;

  /// No description provided for @adhanHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String adhanHoursAgo(int hours);

  /// No description provided for @adhanHoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours left'**
  String adhanHoursLeft(int hours);

  /// No description provided for @adhanMinsAgo.
  ///
  /// In en, this message translates to:
  /// **'{mins} minutes ago'**
  String adhanMinsAgo(int mins);

  /// No description provided for @adhanMinsLeft.
  ///
  /// In en, this message translates to:
  /// **'{mins} minutes left'**
  String adhanMinsLeft(int mins);

  /// No description provided for @advancedSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Display Settings'**
  String get appearance;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize the app\'s appearance.'**
  String get appearanceSubtitle;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Hasanat'**
  String get appName;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @asr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @autoSelectOrMap.
  ///
  /// In en, this message translates to:
  /// **'Auto Select or Map'**
  String get autoSelectOrMap;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @basicParametersTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Parameters'**
  String get basicParametersTitle;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// No description provided for @calculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation Method'**
  String get calculationMethod;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @changingTimezone.
  ///
  /// In en, this message translates to:
  /// **'Changing Timezone'**
  String get changingTimezone;

  /// No description provided for @chooseCalculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose your calculation method'**
  String get chooseCalculationMethod;

  /// No description provided for @chooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose Location'**
  String get chooseLocation;

  /// No description provided for @colorTheme.
  ///
  /// In en, this message translates to:
  /// **'Color Theme'**
  String get colorTheme;

  /// No description provided for @colorThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the apps color themes.'**
  String get colorThemeSubtitle;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed •'**
  String get completed;

  /// No description provided for @completionStatus.
  ///
  /// In en, this message translates to:
  /// **'Completion Status'**
  String get completionStatus;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @currentPrayer.
  ///
  /// In en, this message translates to:
  /// **'Current Prayer'**
  String get currentPrayer;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @customParametersCollapsedHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to configure custom calculation parameters'**
  String get customParametersCollapsedHint;

  /// No description provided for @customParametersLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom parameters'**
  String get customParametersLabel;

  /// No description provided for @customParametersTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Parameters'**
  String get customParametersTitle;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @detectTimezone.
  ///
  /// In en, this message translates to:
  /// **'Detect timezone'**
  String get detectTimezone;

  /// No description provided for @detectTimezoneNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Timezone detection is not implemented here.'**
  String get detectTimezoneNotImplemented;

  /// No description provided for @deviceLocationNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Using device location is not implemented here.'**
  String get deviceLocationNotImplemented;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dragTheMapTip.
  ///
  /// In en, this message translates to:
  /// **'Drag the map to position the pin'**
  String get dragTheMapTip;

  /// No description provided for @dubai.
  ///
  /// In en, this message translates to:
  /// **'Dubai'**
  String get dubai;

  /// No description provided for @editsSavedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your changes have been saved successfully.'**
  String get editsSavedDescription;

  /// No description provided for @editsSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Edits were saved'**
  String get editsSavedTitle;

  /// No description provided for @egyptian.
  ///
  /// In en, this message translates to:
  /// **'Egyptian General Authority of Survey'**
  String get egyptian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @errorNotFoundPage.
  ///
  /// In en, this message translates to:
  /// **'we couldn\'t find this page please make sure you entered the correct url.'**
  String get errorNotFoundPage;

  /// No description provided for @errorOccurredWhile.
  ///
  /// In en, this message translates to:
  /// **'Error Occurred While {whileError}'**
  String errorOccurredWhile(String whileError);

  /// No description provided for @errorUpdatingLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Your coordinates were updated successfully, but we couldn\'t get your location name. This won\'t affect the app\'s functionality.'**
  String get errorUpdatingLocationDescription;

  /// No description provided for @errorUpdatingLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while updating location'**
  String get errorUpdatingLocationTitle;

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajir'**
  String get fajr;

  /// No description provided for @fajrAngleLabel.
  ///
  /// In en, this message translates to:
  /// **'Fajr Angle (°)'**
  String get fajrAngleLabel;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting Location'**
  String get gettingLocation;

  /// No description provided for @green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get green;

  /// No description provided for @hadith.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get hadith;

  /// No description provided for @highLatitudeRule_middleOfTheNight.
  ///
  /// In en, this message translates to:
  /// **'Middle of the Night'**
  String get highLatitudeRule_middleOfTheNight;

  /// No description provided for @highLatitudeRule_seventhOfTheNight.
  ///
  /// In en, this message translates to:
  /// **'Seventh of the Night'**
  String get highLatitudeRule_seventhOfTheNight;

  /// No description provided for @highLatitudeRule_twilightAngle.
  ///
  /// In en, this message translates to:
  /// **'Twilight Angle'**
  String get highLatitudeRule_twilightAngle;

  /// No description provided for @highLatitudeRuleLabel.
  ///
  /// In en, this message translates to:
  /// **'High Latitude Rule'**
  String get highLatitudeRuleLabel;

  /// No description provided for @invalidCoordinatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid latitude and longitude values.'**
  String get invalidCoordinatesDescription;

  /// No description provided for @invalidCoordinatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid Coordinates'**
  String get invalidCoordinatesTitle;

  /// No description provided for @invalidParametersDescription.
  ///
  /// In en, this message translates to:
  /// **'Please check your input values.'**
  String get invalidParametersDescription;

  /// No description provided for @invalidParametersTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid Parameters'**
  String get invalidParametersTitle;

  /// No description provided for @iqamah.
  ///
  /// In en, this message translates to:
  /// **'Iqamah'**
  String get iqamah;

  /// No description provided for @iqamahAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Iqamah Adjustment'**
  String get iqamahAdjustment;

  /// No description provided for @iqamahAfterAdhan.
  ///
  /// In en, this message translates to:
  /// **'Iqamah (minutes after adhan)'**
  String get iqamahAfterAdhan;

  /// No description provided for @iqamahSubtitleMessage.
  ///
  /// In en, this message translates to:
  /// **'+{iqamahMins} minutes'**
  String iqamahSubtitleMessage(int iqamahMins);

  /// No description provided for @isha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// No description provided for @ishaAngleLabel.
  ///
  /// In en, this message translates to:
  /// **'Isha Angle (°)'**
  String get ishaAngleLabel;

  /// No description provided for @ishaIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Isha Interval (min)'**
  String get ishaIntervalLabel;

  /// No description provided for @islamicTheme.
  ///
  /// In en, this message translates to:
  /// **'Manuscript'**
  String get islamicTheme;

  /// No description provided for @jamaah.
  ///
  /// In en, this message translates to:
  /// **'Jamaah'**
  String get jamaah;

  /// No description provided for @jamaahRate.
  ///
  /// In en, this message translates to:
  /// **'Jamaah Rate'**
  String get jamaahRate;

  /// No description provided for @jumuah.
  ///
  /// In en, this message translates to:
  /// **'Jumuah'**
  String get jumuah;

  /// No description provided for @karachi.
  ///
  /// In en, this message translates to:
  /// **'University of Islamic Sciences, Karachi'**
  String get karachi;

  /// No description provided for @kuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get kuwait;

  /// No description provided for @lastThirdOfTheNight.
  ///
  /// In en, this message translates to:
  /// **'Last Third Of The Night'**
  String get lastThirdOfTheNight;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @lateRate.
  ///
  /// In en, this message translates to:
  /// **'Late Rate'**
  String get lateRate;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @loadingLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading Location Settings'**
  String get loadingLocationSettings;

  /// No description provided for @locationSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set geographical location and prayer time calculation method.'**
  String get locationSectionSubtitle;

  /// No description provided for @locationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location & Calculation'**
  String get locationSectionTitle;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @madhab_hanafi.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get madhab_hanafi;

  /// No description provided for @madhab_shafi.
  ///
  /// In en, this message translates to:
  /// **'Shafi'**
  String get madhab_shafi;

  /// No description provided for @madhabLabel.
  ///
  /// In en, this message translates to:
  /// **'Madhab'**
  String get madhabLabel;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @maghribAngleLabel.
  ///
  /// In en, this message translates to:
  /// **'Maghrib Angle (°)'**
  String get maghribAngleLabel;

  /// No description provided for @midnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get midnight;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minute;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @missedRate.
  ///
  /// In en, this message translates to:
  /// **'Missed Rate'**
  String get missedRate;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @moonsightingCommittee.
  ///
  /// In en, this message translates to:
  /// **'Moonsighting Committee'**
  String get moonsightingCommittee;

  /// No description provided for @morocco.
  ///
  /// In en, this message translates to:
  /// **'Morocco'**
  String get morocco;

  /// No description provided for @muslimFortress.
  ///
  /// In en, this message translates to:
  /// **'Muslim Fortress'**
  String get muslimFortress;

  /// No description provided for @muslimWorldLeague.
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get muslimWorldLeague;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get nextPrayer;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResults;

  /// No description provided for @northAmerica.
  ///
  /// In en, this message translates to:
  /// **'North America (ISNA)'**
  String get northAmerica;

  /// No description provided for @onTime.
  ///
  /// In en, this message translates to:
  /// **'On Time'**
  String get onTime;

  /// No description provided for @onTimePrayersLast30Days.
  ///
  /// In en, this message translates to:
  /// **'On time prayers (last 30 days)'**
  String get onTimePrayersLast30Days;

  /// No description provided for @onTimePrayersLast365Days.
  ///
  /// In en, this message translates to:
  /// **'On time prayers (last 365 days)'**
  String get onTimePrayersLast365Days;

  /// No description provided for @onTimePrayersLast7Days.
  ///
  /// In en, this message translates to:
  /// **'On time prayers (last 7 days)'**
  String get onTimePrayersLast7Days;

  /// No description provided for @onTimeRate.
  ///
  /// In en, this message translates to:
  /// **'On Time Rate'**
  String get onTimeRate;

  /// No description provided for @optionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalHint;

  /// No description provided for @orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get orange;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pageNotFound;

  /// No description provided for @pageNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'This page doesn\'t exist. Please go back to the home page.'**
  String get pageNotFoundDescription;

  /// No description provided for @parametersSavedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your custom parameters have been saved successfully.'**
  String get parametersSavedDescription;

  /// No description provided for @parametersSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Parameters Saved'**
  String get parametersSavedTitle;

  /// No description provided for @placeholdersHint.
  ///
  /// In en, this message translates to:
  /// **'Madhab and other options can be configured later. These inputs are placeholders.'**
  String get placeholdersHint;

  /// No description provided for @playerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Player Analytics'**
  String get playerAnalytics;

  /// No description provided for @pleaseSelectMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a calculation method.'**
  String get pleaseSelectMethod;

  /// No description provided for @prayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayer;

  /// No description provided for @prayerSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Settings for prayer times, tracking, and related configurations.'**
  String get prayerSettingsSubtitle;

  /// No description provided for @prayerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Settings'**
  String get prayerSettingsTitle;

  /// No description provided for @prayerTimeAdjustmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Time Adjustments (minutes)'**
  String get prayerTimeAdjustmentsTitle;

  /// No description provided for @prayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get prayerTimes;

  /// No description provided for @prayerTrackerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your prayers and stay consistent, click on a prayer to mark it as completed.'**
  String get prayerTrackerSubtitle;

  /// No description provided for @prayerTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Tracker'**
  String get prayerTrackerTitle;

  /// No description provided for @prepareForPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prepare yourself for the prayer.'**
  String get prepareForPrayer;

  /// No description provided for @qatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get qatar;

  /// No description provided for @quran.
  ///
  /// In en, this message translates to:
  /// **'Holy Quran'**
  String get quran;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @remembrance.
  ///
  /// In en, this message translates to:
  /// **'Remembrance'**
  String get remembrance;

  /// No description provided for @resetCompleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Parameters have been reset to default values.'**
  String get resetCompleteDescription;

  /// No description provided for @resetCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Complete'**
  String get resetCompleteTitle;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @rose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get rose;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveParameters.
  ///
  /// In en, this message translates to:
  /// **'Save Parameters'**
  String get saveParameters;

  /// No description provided for @searchForMore.
  ///
  /// In en, this message translates to:
  /// **'Search for more options'**
  String get searchForMore;

  /// No description provided for @searchPlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get searchPlaceLabel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @setupPrayerSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll guide you through a few quick steps. You can change these later in Settings.'**
  String get setupPrayerSettingsSubtitle;

  /// No description provided for @setupPrayerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your prayer settings.'**
  String get setupPrayerSettingsTitle;

  /// No description provided for @setupPreferences.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your preferences.'**
  String get setupPreferences;

  /// No description provided for @signedExampleHint.
  ///
  /// In en, this message translates to:
  /// **'20 or -10'**
  String get signedExampleHint;

  /// No description provided for @singapore.
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get singapore;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @slate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get slate;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @stone.
  ///
  /// In en, this message translates to:
  /// **'Stone'**
  String get stone;

  /// No description provided for @streakInDays.
  ///
  /// In en, this message translates to:
  /// **'{streak} days'**
  String streakInDays(int streak);

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @tehran.
  ///
  /// In en, this message translates to:
  /// **'Tehran'**
  String get tehran;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get timeFormat;

  /// No description provided for @timeSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure time display format and Iqamah times for each prayer.'**
  String get timeSectionSubtitle;

  /// No description provided for @timeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Time Display & Iqamah'**
  String get timeSectionTitle;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @tipHoldCtrlToRotate.
  ///
  /// In en, this message translates to:
  /// **'Tip: Hold Ctrl and drag to rotate and tilt the map.'**
  String get tipHoldCtrlToRotate;

  /// No description provided for @toggleArabic.
  ///
  /// In en, this message translates to:
  /// **'Toggle Arabic'**
  String get toggleArabic;

  /// No description provided for @turkiye.
  ///
  /// In en, this message translates to:
  /// **'Turkey (Diyanet)'**
  String get turkiye;

  /// No description provided for @ummAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm Al-Qura University'**
  String get ummAlQura;

  /// No description provided for @use24HourFormat.
  ///
  /// In en, this message translates to:
  /// **'Use 24-hour format'**
  String get use24HourFormat;

  /// No description provided for @useDeviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Use device location'**
  String get useDeviceLocation;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use My Location'**
  String get useMyLocation;

  /// No description provided for @useSystemTimezone.
  ///
  /// In en, this message translates to:
  /// **'Use System Timezone'**
  String get useSystemTimezone;

  /// No description provided for @violet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get violet;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @welcomeToApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the app!'**
  String get welcomeToApp;

  /// No description provided for @wizardStep_calculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation Method'**
  String get wizardStep_calculationMethod;

  /// No description provided for @wizardStep_getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get wizardStep_getStarted;

  /// No description provided for @wizardStep_iqamahAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Iqamah & Adjustments'**
  String get wizardStep_iqamahAdjustments;

  /// No description provided for @wizardStep_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get wizardStep_location;

  /// No description provided for @wizardStep_timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get wizardStep_timeFormat;

  /// No description provided for @wizardStep_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get wizardStep_welcome;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @yellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get yellow;

  /// No description provided for @zinc.
  ///
  /// In en, this message translates to:
  /// **'Zinc'**
  String get zinc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
