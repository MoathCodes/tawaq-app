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
    Locale('en')
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

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

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

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajir'**
  String get fajr;

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

  /// No description provided for @iqamah.
  ///
  /// In en, this message translates to:
  /// **'Iqamah'**
  String get iqamah;

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

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @midnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get midnight;

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

  /// No description provided for @muslimFortress.
  ///
  /// In en, this message translates to:
  /// **'Muslim Fortress'**
  String get muslimFortress;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get nextPrayer;

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

  /// No description provided for @orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get orange;

  /// No description provided for @playerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Player Analytics'**
  String get playerAnalytics;

  /// No description provided for @prayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayer;

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

  /// No description provided for @rose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get rose;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

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

  /// No description provided for @toggleArabic.
  ///
  /// In en, this message translates to:
  /// **'Toggle Arabic'**
  String get toggleArabic;

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
      'that was used.');
}
