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

  /// No description provided for @a11yExpandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get a11yExpandSidebar;

  /// No description provided for @a11yNavigationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get a11yNavigationUnavailable;

  /// No description provided for @a11yOpenLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open location settings'**
  String get a11yOpenLocationSettings;

  /// No description provided for @a11ySettingsDecreaseIqamah.
  ///
  /// In en, this message translates to:
  /// **'Decrease {prayer} iqamah minutes'**
  String a11ySettingsDecreaseIqamah(String prayer);

  /// No description provided for @a11ySettingsIncreaseIqamah.
  ///
  /// In en, this message translates to:
  /// **'Increase {prayer} iqamah minutes'**
  String a11ySettingsIncreaseIqamah(String prayer);

  /// No description provided for @a11ySettingsResetIqamah.
  ///
  /// In en, this message translates to:
  /// **'Reset {prayer} iqamah to default'**
  String a11ySettingsResetIqamah(String prayer);

  /// No description provided for @a11ySwitchToDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark theme'**
  String get a11ySwitchToDarkTheme;

  /// No description provided for @a11ySwitchToLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch to light theme'**
  String get a11ySwitchToLightTheme;

  /// No description provided for @a11yWindowClose.
  ///
  /// In en, this message translates to:
  /// **'Close window'**
  String get a11yWindowClose;

  /// No description provided for @a11yWindowMaximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize window'**
  String get a11yWindowMaximize;

  /// No description provided for @a11yWindowMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize window'**
  String get a11yWindowMinimize;

  /// No description provided for @a11yWindowRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore window'**
  String get a11yWindowRestore;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @addReflection.
  ///
  /// In en, this message translates to:
  /// **'Add a reflection...'**
  String get addReflection;

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

  /// No description provided for @adhanAlertPositionCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get adhanAlertPositionCenter;

  /// No description provided for @adhanAlertPositionLabel.
  ///
  /// In en, this message translates to:
  /// **'Alert position'**
  String get adhanAlertPositionLabel;

  /// No description provided for @adhanAlertPositionTopEnd.
  ///
  /// In en, this message translates to:
  /// **'Top right'**
  String get adhanAlertPositionTopEnd;

  /// No description provided for @adhanAlertPositionTopStart.
  ///
  /// In en, this message translates to:
  /// **'Top left'**
  String get adhanAlertPositionTopStart;

  /// No description provided for @adhanAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Adhan — {prayer}'**
  String adhanAlertTitle(String prayer);

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

  /// No description provided for @adhanMuezzinAbedAlbasaei.
  ///
  /// In en, this message translates to:
  /// **'Abed Al-Basaei'**
  String get adhanMuezzinAbedAlbasaei;

  /// No description provided for @adhanMuezzinAhmadNufais.
  ///
  /// In en, this message translates to:
  /// **'Ahmad Nufais'**
  String get adhanMuezzinAhmadNufais;

  /// No description provided for @adhanMuezzinGhaziAlSaadoni.
  ///
  /// In en, this message translates to:
  /// **'Ghazi Al-Saadoni'**
  String get adhanMuezzinGhaziAlSaadoni;

  /// No description provided for @adhanMuezzinHamadDeghreri.
  ///
  /// In en, this message translates to:
  /// **'Hamad Deghreri'**
  String get adhanMuezzinHamadDeghreri;

  /// No description provided for @adhanMuezzinHamdanAlMalki.
  ///
  /// In en, this message translates to:
  /// **'Hamdan Al-Malki'**
  String get adhanMuezzinHamdanAlMalki;

  /// No description provided for @adhanMuezzinIbrahimAlArkani.
  ///
  /// In en, this message translates to:
  /// **'Ibrahim Al-Arkani'**
  String get adhanMuezzinIbrahimAlArkani;

  /// No description provided for @adhanMuezzinMajedAlHamathani.
  ///
  /// In en, this message translates to:
  /// **'Majed Al-Hamathani'**
  String get adhanMuezzinMajedAlHamathani;

  /// No description provided for @adhanMuezzinMakkah.
  ///
  /// In en, this message translates to:
  /// **'Makkah'**
  String get adhanMuezzinMakkah;

  /// No description provided for @adhanMuezzinMansoorAlZahrani.
  ///
  /// In en, this message translates to:
  /// **'Mansoor Az-Zahrani'**
  String get adhanMuezzinMansoorAlZahrani;

  /// No description provided for @adhanMuezzinMisharyAlafasi.
  ///
  /// In en, this message translates to:
  /// **'Mishary Alafasi'**
  String get adhanMuezzinMisharyAlafasi;

  /// No description provided for @adhanMuezzinMohammadAlMenshawy.
  ///
  /// In en, this message translates to:
  /// **'Mohammad Al-Menshawy'**
  String get adhanMuezzinMohammadAlMenshawy;

  /// No description provided for @adhanMuezzinMohammadRefat.
  ///
  /// In en, this message translates to:
  /// **'Mohammad Refat'**
  String get adhanMuezzinMohammadRefat;

  /// No description provided for @adhanMuezzinNasserAlQatami.
  ///
  /// In en, this message translates to:
  /// **'Nasser Al-Qatami'**
  String get adhanMuezzinNasserAlQatami;

  /// No description provided for @adhanMuezzinSuhaibKhatba.
  ///
  /// In en, this message translates to:
  /// **'Suhaib Khatba'**
  String get adhanMuezzinSuhaibKhatba;

  /// No description provided for @adhanOsNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s time to pray.'**
  String get adhanOsNotificationBody;

  /// No description provided for @adhanPlayingTitle.
  ///
  /// In en, this message translates to:
  /// **'Adhan — {prayer}'**
  String adhanPlayingTitle(String prayer);

  /// No description provided for @adhanSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Desktop adhan alerts and sounds. The app must stay running in the system tray for adhan to play.'**
  String get adhanSectionSubtitle;

  /// No description provided for @adhanSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Adhan'**
  String get adhanSectionTitle;

  /// No description provided for @adhanShowAlertLabel.
  ///
  /// In en, this message translates to:
  /// **'Show adhan alert'**
  String get adhanShowAlertLabel;

  /// No description provided for @adhanShowOsNotificationLabel.
  ///
  /// In en, this message translates to:
  /// **'OS notification when hidden in tray'**
  String get adhanShowOsNotificationLabel;

  /// No description provided for @adhanSoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Adhan sound'**
  String get adhanSoundLabel;

  /// No description provided for @adhanStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get adhanStop;

  /// No description provided for @adhanVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Adhan volume'**
  String get adhanVolumeLabel;

  /// No description provided for @advancedSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize the app\'s theme and colors.'**
  String get appearanceSubtitle;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Tawaq'**
  String get appName;

  /// No description provided for @appTextSize.
  ///
  /// In en, this message translates to:
  /// **'App text size'**
  String get appTextSize;

  /// No description provided for @appTextSizeCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get appTextSizeCompact;

  /// No description provided for @appTextSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get appTextSizeExtraLarge;

  /// No description provided for @appTextSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get appTextSizeLarge;

  /// No description provided for @appTextSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get appTextSizeNormal;

  /// No description provided for @appTextSizeShortExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'XL'**
  String get appTextSizeShortExtraLarge;

  /// No description provided for @appTextSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Controls menus, labels, and other interface text.'**
  String get appTextSizeSubtitle;

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

  /// No description provided for @autoLocationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Tap to enable automatic location'**
  String get autoLocationDisabled;

  /// No description provided for @autoLocationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Location updates automatically'**
  String get autoLocationEnabled;

  /// No description provided for @autoLocationMapOverlay.
  ///
  /// In en, this message translates to:
  /// **'Location is updated automatically. Turn off the switch above to pick a location on the map.'**
  String get autoLocationMapOverlay;

  /// No description provided for @autoSelectOrMap.
  ///
  /// In en, this message translates to:
  /// **'Auto Select or Map'**
  String get autoSelectOrMap;

  /// No description provided for @ayahBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get ayahBookmark;

  /// No description provided for @ayahCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied {reference}'**
  String ayahCopied(String reference);

  /// No description provided for @ayahCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get ayahCopy;

  /// No description provided for @ayahLabel.
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get ayahLabel;

  /// No description provided for @ayahShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get ayahShare;

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

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'bookmarks'**
  String get bookmarks;

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

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @collapsePanel.
  ///
  /// In en, this message translates to:
  /// **'Collapse panel'**
  String get collapsePanel;

  /// No description provided for @colorTheme.
  ///
  /// In en, this message translates to:
  /// **'Color Theme'**
  String get colorTheme;

  /// No description provided for @colorThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Manuscript or Neutral.'**
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

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @decimalPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'0.0'**
  String get decimalPlaceholder;

  /// No description provided for @defaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Default location'**
  String get defaultLocation;

  /// No description provided for @defaultSurahName.
  ///
  /// In en, this message translates to:
  /// **'Al-Fatihah'**
  String get defaultSurahName;

  /// No description provided for @desktopForceMacStyleWindowControls.
  ///
  /// In en, this message translates to:
  /// **'Use macOS-style window controls'**
  String get desktopForceMacStyleWindowControls;

  /// No description provided for @desktopLaunchAtLogin.
  ///
  /// In en, this message translates to:
  /// **'Start at login'**
  String get desktopLaunchAtLogin;

  /// No description provided for @desktopLaunchAtLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Start hidden in tray was also enabled so adhan alerts work after login.'**
  String get desktopLaunchAtLoginHint;

  /// No description provided for @desktopLaunchToTray.
  ///
  /// In en, this message translates to:
  /// **'Start hidden in tray'**
  String get desktopLaunchToTray;

  /// No description provided for @desktopMinimizeToTray.
  ///
  /// In en, this message translates to:
  /// **'Hide to tray when minimizing'**
  String get desktopMinimizeToTray;

  /// No description provided for @desktopMinimizeToTrayOnClose.
  ///
  /// In en, this message translates to:
  /// **'Hide to tray when closing the window'**
  String get desktopMinimizeToTrayOnClose;

  /// No description provided for @desktopSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System tray, window behaviour, and startup on desktop.'**
  String get desktopSectionSubtitle;

  /// No description provided for @desktopSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get desktopSectionTitle;

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

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @errorLoadingTafsir.
  ///
  /// In en, this message translates to:
  /// **'Error loading tafsir'**
  String get errorLoadingTafsir;

  /// No description provided for @errorLoadingTranslation.
  ///
  /// In en, this message translates to:
  /// **'Error loading translation'**
  String get errorLoadingTranslation;

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

  /// No description provided for @expandPanel.
  ///
  /// In en, this message translates to:
  /// **'Expand panel'**
  String get expandPanel;

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

  /// No description provided for @footnote.
  ///
  /// In en, this message translates to:
  /// **'Footnote'**
  String get footnote;

  /// No description provided for @fortressAllChapters.
  ///
  /// In en, this message translates to:
  /// **'All adhkar'**
  String get fortressAllChapters;

  /// No description provided for @fortressBenefit.
  ///
  /// In en, this message translates to:
  /// **'Benefit'**
  String get fortressBenefit;

  /// No description provided for @fortressBrowseWeakHadith.
  ///
  /// In en, this message translates to:
  /// **'Weak & fabricated hadiths'**
  String get fortressBrowseWeakHadith;

  /// No description provided for @fortressCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get fortressCompleted;

  /// No description provided for @fortressDhikrCopied.
  ///
  /// In en, this message translates to:
  /// **'Dhikr copied'**
  String get fortressDhikrCopied;

  /// No description provided for @fortressEmptyFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon next to any section to add it here'**
  String get fortressEmptyFavoritesHint;

  /// No description provided for @fortressEmptyFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorite sections yet'**
  String get fortressEmptyFavoritesTitle;

  /// No description provided for @fortressEmptySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Try different search terms'**
  String get fortressEmptySearchHint;

  /// No description provided for @fortressEmptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get fortressEmptySearchTitle;

  /// No description provided for @fortressFakeHadithGuide.
  ///
  /// In en, this message translates to:
  /// **'Weak & fabricated hadith guide'**
  String get fortressFakeHadithGuide;

  /// No description provided for @fortressFakeHadithIntro.
  ///
  /// In en, this message translates to:
  /// **'Reference list from Hisn al-Muslim of hadiths scholars warn against.'**
  String get fortressFakeHadithIntro;

  /// No description provided for @fortressFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get fortressFavorites;

  /// No description provided for @fortressFilterAuthenticity.
  ///
  /// In en, this message translates to:
  /// **'Filter by grading'**
  String get fortressFilterAuthenticity;

  /// No description provided for @fortressFilterChaptersHint.
  ///
  /// In en, this message translates to:
  /// **'Filter chapters...'**
  String get fortressFilterChaptersHint;

  /// No description provided for @fortressFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get fortressFinish;

  /// No description provided for @fortressHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get fortressHideDetails;

  /// No description provided for @fortressLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load adhkar'**
  String get fortressLoadError;

  /// No description provided for @fortressMoreFavoriteChapters.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {Plus 1 more chapter…} other {Plus {count} more chapters…}}'**
  String fortressMoreFavoriteChapters(int count);

  /// No description provided for @fortressNoAdhkarInChapter.
  ///
  /// In en, this message translates to:
  /// **'No adhkar in this chapter'**
  String get fortressNoAdhkarInChapter;

  /// No description provided for @fortressNoFavoriteChapters.
  ///
  /// In en, this message translates to:
  /// **'No favorite chapters yet — bookmark one from the sidebar'**
  String get fortressNoFavoriteChapters;

  /// No description provided for @fortressNoRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations available right now'**
  String get fortressNoRecommendations;

  /// No description provided for @fortressNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get fortressNoSearchResults;

  /// No description provided for @fortressPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get fortressPrevious;

  /// No description provided for @fortressReadingHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the dhikr to count · Swipe horizontally to navigate · Space to count'**
  String get fortressReadingHint;

  /// No description provided for @fortressReadLong.
  ///
  /// In en, this message translates to:
  /// **'Long reading'**
  String get fortressReadLong;

  /// No description provided for @fortressReadMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium reading'**
  String get fortressReadMedium;

  /// No description provided for @fortressReadShort.
  ///
  /// In en, this message translates to:
  /// **'Short reading'**
  String get fortressReadShort;

  /// No description provided for @fortressRecommendedNow.
  ///
  /// In en, this message translates to:
  /// **'Recommended now'**
  String get fortressRecommendedNow;

  /// No description provided for @fortressRelatedHadith.
  ///
  /// In en, this message translates to:
  /// **'Related hadith'**
  String get fortressRelatedHadith;

  /// No description provided for @fortressRemainingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {None remaining} =1 {1 remaining} other {{count} remaining}}'**
  String fortressRemainingCount(int count);

  /// No description provided for @fortressRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get fortressRetry;

  /// No description provided for @fortressSearchContents.
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get fortressSearchContents;

  /// No description provided for @fortressSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search chapters and adhkar...'**
  String get fortressSearchHint;

  /// No description provided for @fortressSearchTitles.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get fortressSearchTitles;

  /// No description provided for @fortressSharh.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get fortressSharh;

  /// No description provided for @fortressShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get fortressShowDetails;

  /// No description provided for @fortressShowSharh.
  ///
  /// In en, this message translates to:
  /// **'Show explanation'**
  String get fortressShowSharh;

  /// No description provided for @fortressShowSource.
  ///
  /// In en, this message translates to:
  /// **'Show source'**
  String get fortressShowSource;

  /// No description provided for @fortressSourceReference.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get fortressSourceReference;

  /// No description provided for @fortressStartReading.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get fortressStartReading;

  /// No description provided for @fortressSupplicationCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 dhikr} other {{count} adhkar}}'**
  String fortressSupplicationCount(int count);

  /// No description provided for @fortressSupplicationsInSection.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 dhikr in this section} other {{count} adhkar in this section}}'**
  String fortressSupplicationsInSection(int count);

  /// No description provided for @fortressVirtue.
  ///
  /// In en, this message translates to:
  /// **'Virtue'**
  String get fortressVirtue;

  /// No description provided for @fortressWeakHadithWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: this dhikr is weak or fabricated'**
  String get fortressWeakHadithWarning;

  /// No description provided for @fortressWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse chapters from the list, or start from recommendations for your time or favorites.'**
  String get fortressWelcomeSubtitle;

  /// No description provided for @fortressWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a chapter and begin dhikr'**
  String get fortressWelcomeTitle;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting Location'**
  String get gettingLocation;

  /// No description provided for @goToPrayerPage.
  ///
  /// In en, this message translates to:
  /// **'Go to Prayer Page'**
  String get goToPrayerPage;

  /// No description provided for @graphicalAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Graphical Analysis'**
  String get graphicalAnalysis;

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

  /// No description provided for @hadithActiveFilters.
  ///
  /// In en, this message translates to:
  /// **'Active Filters'**
  String get hadithActiveFilters;

  /// No description provided for @hadithAlternateHadithSahih.
  ///
  /// In en, this message translates to:
  /// **'Alternate Authentic Hadith'**
  String get hadithAlternateHadithSahih;

  /// No description provided for @hadithAlternativeAuthentic.
  ///
  /// In en, this message translates to:
  /// **'Alternative Authentic Narrations'**
  String get hadithAlternativeAuthentic;

  /// No description provided for @hadithBackToSearch.
  ///
  /// In en, this message translates to:
  /// **'Back to search'**
  String get hadithBackToSearch;

  /// No description provided for @hadithBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get hadithBooks;

  /// No description provided for @hadithClearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get hadithClearAllFilters;

  /// No description provided for @hadithClearAllRecents.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get hadithClearAllRecents;

  /// No description provided for @hadithCopied.
  ///
  /// In en, this message translates to:
  /// **'Hadith copied'**
  String get hadithCopied;

  /// No description provided for @hadithDegreeAll.
  ///
  /// In en, this message translates to:
  /// **'All degrees'**
  String get hadithDegreeAll;

  /// No description provided for @hadithDegreeAuthenticChain.
  ///
  /// In en, this message translates to:
  /// **'Chains scholars ruled authentic'**
  String get hadithDegreeAuthenticChain;

  /// No description provided for @hadithDegreeAuthenticHadith.
  ///
  /// In en, this message translates to:
  /// **'Hadiths scholars ruled authentic'**
  String get hadithDegreeAuthenticHadith;

  /// No description provided for @hadithDegrees.
  ///
  /// In en, this message translates to:
  /// **'Degrees'**
  String get hadithDegrees;

  /// No description provided for @hadithDegreeWeakChain.
  ///
  /// In en, this message translates to:
  /// **'Chains scholars ruled weak'**
  String get hadithDegreeWeakChain;

  /// No description provided for @hadithDegreeWeakHadith.
  ///
  /// In en, this message translates to:
  /// **'Hadiths scholars ruled weak'**
  String get hadithDegreeWeakHadith;

  /// No description provided for @hadithDetailsTab.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hadithDetailsTab;

  /// No description provided for @hadithFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'{label}:'**
  String hadithFieldLabel(String label);

  /// No description provided for @hadithFilterTab.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get hadithFilterTab;

  /// No description provided for @hadithFoundations.
  ///
  /// In en, this message translates to:
  /// **'Foundations'**
  String get hadithFoundations;

  /// No description provided for @hadithGradeExplanation.
  ///
  /// In en, this message translates to:
  /// **'Grade Explanation'**
  String get hadithGradeExplanation;

  /// No description provided for @hadithLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get hadithLoadMore;

  /// No description provided for @hadithLoadSharh.
  ///
  /// In en, this message translates to:
  /// **'Load Explanation'**
  String get hadithLoadSharh;

  /// No description provided for @hadithLoadSharhFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sharh: {error}'**
  String hadithLoadSharhFailed(String error);

  /// No description provided for @hadithMuhaddith.
  ///
  /// In en, this message translates to:
  /// **'Muhaddith'**
  String get hadithMuhaddith;

  /// No description provided for @hadithNarrator.
  ///
  /// In en, this message translates to:
  /// **'Narrator'**
  String get hadithNarrator;

  /// No description provided for @hadithNarrators.
  ///
  /// In en, this message translates to:
  /// **'Narrators'**
  String get hadithNarrators;

  /// No description provided for @hadithNoBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No saved hadiths yet'**
  String get hadithNoBookmarks;

  /// No description provided for @hadithNoDetailedData.
  ///
  /// In en, this message translates to:
  /// **'No detailed data found for this hadith'**
  String get hadithNoDetailedData;

  /// No description provided for @hadithNoDetailsSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a hadith from results to view details'**
  String get hadithNoDetailsSelected;

  /// No description provided for @hadithNoMatchingResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results found'**
  String get hadithNoMatchingResults;

  /// No description provided for @hadithNoRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'No recent searches yet'**
  String get hadithNoRecentSearches;

  /// No description provided for @hadithOpenFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get hadithOpenFilters;

  /// No description provided for @hadithPageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load that page. Showing previous results.'**
  String get hadithPageLoadFailed;

  /// No description provided for @hadithRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get hadithRecentSearches;

  /// No description provided for @hadithRelatedLinks.
  ///
  /// In en, this message translates to:
  /// **'Related Links'**
  String get hadithRelatedLinks;

  /// No description provided for @hadithResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get hadithResetFilters;

  /// No description provided for @hadithResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No results} =1 {1 result} other {{count} results}}'**
  String hadithResultsCount(int count);

  /// No description provided for @hadithRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get hadithRetry;

  /// No description provided for @hadithScholars.
  ///
  /// In en, this message translates to:
  /// **'Scholars'**
  String get hadithScholars;

  /// No description provided for @hadithScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get hadithScope;

  /// No description provided for @hadithSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get hadithSearchAction;

  /// No description provided for @hadithSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search hadith...'**
  String get hadithSearchHint;

  /// No description provided for @hadithSearchMethod.
  ///
  /// In en, this message translates to:
  /// **'Search method'**
  String get hadithSearchMethod;

  /// No description provided for @hadithSearchMethodAllWords.
  ///
  /// In en, this message translates to:
  /// **'All words'**
  String get hadithSearchMethodAllWords;

  /// No description provided for @hadithSearchMethodAnyWord.
  ///
  /// In en, this message translates to:
  /// **'Any word'**
  String get hadithSearchMethodAnyWord;

  /// No description provided for @hadithSearchMethodExactMatch.
  ///
  /// In en, this message translates to:
  /// **'Exact match'**
  String get hadithSearchMethodExactMatch;

  /// No description provided for @hadithSearchZoneAll.
  ///
  /// In en, this message translates to:
  /// **'All hadiths'**
  String get hadithSearchZoneAll;

  /// No description provided for @hadithSearchZoneMarfoo.
  ///
  /// In en, this message translates to:
  /// **'Marfoo hadiths'**
  String get hadithSearchZoneMarfoo;

  /// No description provided for @hadithSearchZoneQudsi.
  ///
  /// In en, this message translates to:
  /// **'Qudsi hadiths'**
  String get hadithSearchZoneQudsi;

  /// No description provided for @hadithSearchZoneSahabaAthar.
  ///
  /// In en, this message translates to:
  /// **'Companion narrations'**
  String get hadithSearchZoneSahabaAthar;

  /// No description provided for @hadithSearchZoneSharh.
  ///
  /// In en, this message translates to:
  /// **'Hadith commentaries'**
  String get hadithSearchZoneSharh;

  /// No description provided for @hadithSharh.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get hadithSharh;

  /// No description provided for @hadithSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar Hadiths'**
  String get hadithSimilar;

  /// No description provided for @hadithSimilarHadith.
  ///
  /// In en, this message translates to:
  /// **'Similar Hadith'**
  String get hadithSimilarHadith;

  /// No description provided for @hadithSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get hadithSource;

  /// No description provided for @hadithSourceCitation.
  ///
  /// In en, this message translates to:
  /// **'{book} ({reference})'**
  String hadithSourceCitation(String book, String reference);

  /// Filter toggle for Dorar's specialist tab: limits results to hadiths that include takhrij in their metadata (Dorar UI label: متخصص).
  ///
  /// In en, this message translates to:
  /// **'Takhrij'**
  String get hadithSpecialist;

  /// Explains that enabling this filter limits results to hadiths with takhrij populated in result metadata.
  ///
  /// In en, this message translates to:
  /// **'Only return hadiths that include takhrij in their metadata'**
  String get hadithSpecialistHint;

  /// No description provided for @hadithStartSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Press Enter or Search to see results'**
  String get hadithStartSearchPrompt;

  /// No description provided for @hadithTakhrij.
  ///
  /// In en, this message translates to:
  /// **'Takhrij'**
  String get hadithTakhrij;

  /// No description provided for @hadithTypeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search...'**
  String get hadithTypeToSearch;

  /// No description provided for @hadithUsulHadith.
  ///
  /// In en, this message translates to:
  /// **'Usul al-Hadith'**
  String get hadithUsulHadith;

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

  /// No description provided for @hizbLabel.
  ///
  /// In en, this message translates to:
  /// **'Hizb {number}'**
  String hizbLabel(int number);

  /// No description provided for @integerPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'0'**
  String get integerPlaceholder;

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

  /// No description provided for @invalidParametersWithError.
  ///
  /// In en, this message translates to:
  /// **'{message} {error}'**
  String invalidParametersWithError(String message, String error);

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

  /// No description provided for @iqamahAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Iqamah — {prayer}'**
  String iqamahAlertTitle(String prayer);

  /// No description provided for @iqamahMuezzinMadinah.
  ///
  /// In en, this message translates to:
  /// **'Madinah'**
  String get iqamahMuezzinMadinah;

  /// No description provided for @iqamahMuezzinYasserAlDossari.
  ///
  /// In en, this message translates to:
  /// **'Yasser Al-Dossari'**
  String get iqamahMuezzinYasserAlDossari;

  /// No description provided for @iqamahOsNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Iqamah time has arrived.'**
  String get iqamahOsNotificationBody;

  /// No description provided for @iqamahPlayingTitle.
  ///
  /// In en, this message translates to:
  /// **'Iqamah — {prayer}'**
  String iqamahPlayingTitle(String prayer);

  /// No description provided for @iqamahSavedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your iqamah adjustments have been saved successfully.'**
  String get iqamahSavedDescription;

  /// No description provided for @iqamahSavedForPrayer.
  ///
  /// In en, this message translates to:
  /// **'Saved iqamah adjustment for {prayer}.'**
  String iqamahSavedForPrayer(String prayer);

  /// No description provided for @iqamahSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Iqamah adjustments saved'**
  String get iqamahSavedTitle;

  /// No description provided for @iqamahSoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Iqamah call'**
  String get iqamahSoundLabel;

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

  /// No description provided for @juzLabel.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String juzLabel(int number);

  /// No description provided for @karachi.
  ///
  /// In en, this message translates to:
  /// **'University of Islamic Sciences, Karachi'**
  String get karachi;

  /// No description provided for @keyboardShortcutsCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Available when using the app on desktop.'**
  String get keyboardShortcutsCategorySubtitle;

  /// No description provided for @keyboardShortcutsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reference list of keyboard shortcuts available on desktop. Shortcuts work app-wide from any screen, including this one. They cannot be customized.'**
  String get keyboardShortcutsSectionSubtitle;

  /// No description provided for @keyboardShortcutsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keyboardShortcutsSectionTitle;

  /// No description provided for @keyboardShortcutsTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keyboardShortcutsTabTitle;

  /// No description provided for @kuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get kuwait;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

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

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Loading Analytics'**
  String get loadingAnalytics;

  /// No description provided for @loadingLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading Location Settings'**
  String get loadingLocationSettings;

  /// No description provided for @loadingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Loading schedule'**
  String get loadingSchedule;

  /// No description provided for @locationCoordinatesLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not determine timezone from coordinates.'**
  String get locationCoordinatesLookupFailed;

  /// No description provided for @locationNoPlaceFound.
  ///
  /// In en, this message translates to:
  /// **'No place found at {coordinates}.'**
  String locationNoPlaceFound(String coordinates);

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Enable it in system settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your geographical location and timezone for accurate prayer times.'**
  String get locationSectionSubtitle;

  /// No description provided for @locationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSectionTitle;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get locationServicesDisabled;

  /// No description provided for @lockToPreventEdits.
  ///
  /// In en, this message translates to:
  /// **'Lock to prevent edits'**
  String get lockToPreventEdits;

  /// No description provided for @logPrayerStatus.
  ///
  /// In en, this message translates to:
  /// **'Prayer Status'**
  String get logPrayerStatus;

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

  /// No description provided for @menuAddBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get menuAddBookmark;

  /// No description provided for @menuAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get menuAddFavorite;

  /// No description provided for @menuCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get menuCopyText;

  /// No description provided for @menuOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get menuOpen;

  /// No description provided for @menuRemoveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get menuRemoveBookmark;

  /// No description provided for @menuRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get menuRemoveFavorite;

  /// No description provided for @midnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get midnight;

  /// No description provided for @mediaSessionAppName.
  ///
  /// In en, this message translates to:
  /// **'Tawaq'**
  String get mediaSessionAppName;

  /// No description provided for @mediaSessionAudioBy.
  ///
  /// In en, this message translates to:
  /// **'Audio by {source}'**
  String mediaSessionAudioBy(String source);

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

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResults;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @northAmerica.
  ///
  /// In en, this message translates to:
  /// **'North America (ISNA)'**
  String get northAmerica;

  /// No description provided for @noTafsirAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tafsir available for this ayah'**
  String get noTafsirAvailable;

  /// No description provided for @noTranslationAvailable.
  ///
  /// In en, this message translates to:
  /// **'No translation available for this ayah'**
  String get noTranslationAvailable;

  /// No description provided for @nowActive.
  ///
  /// In en, this message translates to:
  /// **'Now Active'**
  String get nowActive;

  /// No description provided for @onboardingFinishAction.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingFinishAction;

  /// No description provided for @onboardingFinishPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Set your location to preview today\'s prayer times.'**
  String get onboardingFinishPreviewUnavailable;

  /// No description provided for @onboardingFinishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your prayer times are ready. You can adjust any setting later from Settings.'**
  String get onboardingFinishSubtitle;

  /// No description provided for @onboardingFinishTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get onboardingFinishTitle;

  /// No description provided for @onboardingLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get onboardingLanguageArabic;

  /// No description provided for @onboardingLanguageArabicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Right-to-left layout with Arabic interface'**
  String get onboardingLanguageArabicSubtitle;

  /// No description provided for @onboardingLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get onboardingLanguageEnglish;

  /// No description provided for @onboardingLanguageEnglishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Left-to-right layout with English interface'**
  String get onboardingLanguageEnglishSubtitle;

  /// No description provided for @onboardingLanguageStepHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the language you prefer for menus and labels.'**
  String get onboardingLanguageStepHint;

  /// No description provided for @onboardingLocationTipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use your city only to calculate accurate prayer times. Your location is stored on this device.'**
  String get onboardingLocationTipSubtitle;

  /// No description provided for @onboardingLocationTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Why we need your location'**
  String get onboardingLocationTipTitle;

  /// No description provided for @onboardingOpenSetupAction.
  ///
  /// In en, this message translates to:
  /// **'Open setup'**
  String get onboardingOpenSetupAction;

  /// No description provided for @onboardingRerunSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Walk through language, location, prayer times, and notifications again.'**
  String get onboardingRerunSubtitle;

  /// No description provided for @onboardingRerunTitle.
  ///
  /// In en, this message translates to:
  /// **'Run setup again'**
  String get onboardingRerunTitle;

  /// No description provided for @onboardingSetUpLater.
  ///
  /// In en, this message translates to:
  /// **'Set up later'**
  String get onboardingSetUpLater;

  /// No description provided for @onboardingStepFinish.
  ///
  /// In en, this message translates to:
  /// **'Ready to go'**
  String get onboardingStepFinish;

  /// No description provided for @onboardingStepFinishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review today\'s schedule and start using {appName}.'**
  String onboardingStepFinishSubtitle(String appName);

  /// No description provided for @onboardingStepIqamah.
  ///
  /// In en, this message translates to:
  /// **'Iqamah offsets'**
  String get onboardingStepIqamah;

  /// No description provided for @onboardingStepIqamahSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Minutes after adhan until iqamah for each prayer.'**
  String get onboardingStepIqamahSubtitle;

  /// No description provided for @onboardingStepLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onboardingStepLanguage;

  /// No description provided for @onboardingStepLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick how you\'d like to use the app.'**
  String get onboardingStepLanguageSubtitle;

  /// No description provided for @onboardingStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get onboardingStepLocation;

  /// No description provided for @onboardingStepLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your city so prayer times match where you are.'**
  String get onboardingStepLocationSubtitle;

  /// No description provided for @onboardingStepNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get onboardingStepNotifications;

  /// No description provided for @onboardingStepNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose adhan sounds and how alerts appear.'**
  String get onboardingStepNotificationsSubtitle;

  /// No description provided for @onboardingStepPrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get onboardingStepPrayerTimes;

  /// No description provided for @onboardingStepPrayerTimesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calculation method and time format.'**
  String get onboardingStepPrayerTimesSubtitle;

  /// No description provided for @onboardingStepTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get onboardingStepTheme;

  /// No description provided for @onboardingStepThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme palette and interface text size.'**
  String get onboardingStepThemeSubtitle;

  /// No description provided for @onboardingStepWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get onboardingStepWelcome;

  /// No description provided for @onboardingStepWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick setup to personalize {appName} for you.'**
  String onboardingStepWelcomeSubtitle(String appName);

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll help you set up prayer times, notifications, and appearance in a few guided steps.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingWelcomeTipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can revisit any of these choices later in Settings.'**
  String get onboardingWelcomeTipSubtitle;

  /// No description provided for @onboardingWelcomeTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Take your time'**
  String get onboardingWelcomeTipTitle;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}'**
  String onboardingWelcomeTitle(String appName);

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

  /// No description provided for @onTimePrayersToday.
  ///
  /// In en, this message translates to:
  /// **'On time prayers (today)'**
  String get onTimePrayersToday;

  /// No description provided for @onTimeRate.
  ///
  /// In en, this message translates to:
  /// **'On Time Rate'**
  String get onTimeRate;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @openFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open folder'**
  String get openFolderFailed;

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

  /// No description provided for @pageJuzInfo.
  ///
  /// In en, this message translates to:
  /// **'Page {page} • Juz {juz}'**
  String pageJuzInfo(int page, int juz);

  /// No description provided for @pageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pageLabel(int page);

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

  /// No description provided for @performanceIndicator.
  ///
  /// In en, this message translates to:
  /// **'Performance Indicator'**
  String get performanceIndicator;

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

  /// No description provided for @prayerAlertDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get prayerAlertDismiss;

  /// No description provided for @prayerLocationRequiredAction.
  ///
  /// In en, this message translates to:
  /// **'Open location settings'**
  String get prayerLocationRequiredAction;

  /// No description provided for @prayerLocationRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer times need your coordinates. Open location settings to pick a city on the map or enter them manually.'**
  String get prayerLocationRequiredSubtitle;

  /// No description provided for @prayerLocationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get prayerLocationRequiredTitle;

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

  /// No description provided for @quranAyahSearchPreviewTruncated.
  ///
  /// In en, this message translates to:
  /// **'{preview}...'**
  String quranAyahSearchPreviewTruncated(String preview);

  /// No description provided for @quranDoublePageWidthFallback.
  ///
  /// In en, this message translates to:
  /// **'Not enough width for a two-page spread — showing one page.'**
  String get quranDoublePageWidthFallback;

  /// No description provided for @quranLayoutDoublePage.
  ///
  /// In en, this message translates to:
  /// **'Double Page'**
  String get quranLayoutDoublePage;

  /// No description provided for @quranLayoutStudyMode.
  ///
  /// In en, this message translates to:
  /// **'Study Mode'**
  String get quranLayoutStudyMode;

  /// No description provided for @quranNoMatchingReciters.
  ///
  /// In en, this message translates to:
  /// **'No matching reciters'**
  String get quranNoMatchingReciters;

  /// No description provided for @quranPlayAyah.
  ///
  /// In en, this message translates to:
  /// **'Play this ayah'**
  String get quranPlayAyah;

  /// No description provided for @quranPlayRange.
  ///
  /// In en, this message translates to:
  /// **'Play a range…'**
  String get quranPlayRange;

  /// No description provided for @quranPlaySelection.
  ///
  /// In en, this message translates to:
  /// **'Play selection'**
  String get quranPlaySelection;

  /// No description provided for @quranPlaySurah.
  ///
  /// In en, this message translates to:
  /// **'Play this surah'**
  String get quranPlaySurah;

  /// No description provided for @quranRangeChooseSyncedReciter.
  ///
  /// In en, this message translates to:
  /// **'Choose synced reciter'**
  String get quranRangeChooseSyncedReciter;

  /// No description provided for @quranRangeFrom.
  ///
  /// In en, this message translates to:
  /// **'From — surah & ayah'**
  String get quranRangeFrom;

  /// No description provided for @quranRangeFromAyah.
  ///
  /// In en, this message translates to:
  /// **'From — ayah'**
  String get quranRangeFromAyah;

  /// No description provided for @quranRangeFromShort.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get quranRangeFromShort;

  /// No description provided for @quranRangeFromSurah.
  ///
  /// In en, this message translates to:
  /// **'From — surah'**
  String get quranRangeFromSurah;

  /// No description provided for @quranRangeHizbBoundsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not load hizb boundaries'**
  String get quranRangeHizbBoundsNotFound;

  /// No description provided for @quranRangeHizbNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find the hizb for this ayah'**
  String get quranRangeHizbNotFound;

  /// No description provided for @quranRangeJuzBoundsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not load juz boundaries'**
  String get quranRangeJuzBoundsNotFound;

  /// No description provided for @quranRangeJuzNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find the juz for this ayah'**
  String get quranRangeJuzNotFound;

  /// No description provided for @quranRangeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'End behavior'**
  String get quranRangeModeLabel;

  /// No description provided for @quranRangePlay.
  ///
  /// In en, this message translates to:
  /// **'Play selection'**
  String get quranRangePlay;

  /// No description provided for @quranRangePresetAyah.
  ///
  /// In en, this message translates to:
  /// **'This ayah'**
  String get quranRangePresetAyah;

  /// No description provided for @quranRangePresetContinueFromHere.
  ///
  /// In en, this message translates to:
  /// **'Continue from here'**
  String get quranRangePresetContinueFromHere;

  /// No description provided for @quranRangePresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get quranRangePresetCustom;

  /// No description provided for @quranRangePresetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not apply this range preset'**
  String get quranRangePresetFailed;

  /// No description provided for @quranRangePresetHizb.
  ///
  /// In en, this message translates to:
  /// **'This hizb'**
  String get quranRangePresetHizb;

  /// No description provided for @quranRangePresetJuz.
  ///
  /// In en, this message translates to:
  /// **'This juz'**
  String get quranRangePresetJuz;

  /// No description provided for @quranRangePresetSurah.
  ///
  /// In en, this message translates to:
  /// **'This surah'**
  String get quranRangePresetSurah;

  /// No description provided for @quranRangeRepeatChip.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String quranRangeRepeatChip(int count);

  /// No description provided for @quranRangeRepeatEachAyah.
  ///
  /// In en, this message translates to:
  /// **'Repeat each ayah'**
  String get quranRangeRepeatEachAyah;

  /// No description provided for @quranRangeRepeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get quranRangeRepeatOnce;

  /// No description provided for @quranRangeRepeatSelection.
  ///
  /// In en, this message translates to:
  /// **'Repeat range'**
  String get quranRangeRepeatSelection;

  /// No description provided for @quranRangeRepeatTimes.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String quranRangeRepeatTimes(int count);

  /// No description provided for @quranRangeRepeatTwice.
  ///
  /// In en, this message translates to:
  /// **'Twice'**
  String get quranRangeRepeatTwice;

  /// No description provided for @quranRangeRequiresTimedReciter.
  ///
  /// In en, this message translates to:
  /// **'Select a synced reciter to play this ayah range'**
  String get quranRangeRequiresTimedReciter;

  /// No description provided for @quranRangeSave.
  ///
  /// In en, this message translates to:
  /// **'Save range'**
  String get quranRangeSave;

  /// No description provided for @quranRangeScope.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get quranRangeScope;

  /// No description provided for @quranRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Range & repeat for memorization'**
  String get quranRangeTitle;

  /// No description provided for @quranRangeTo.
  ///
  /// In en, this message translates to:
  /// **'To — surah & ayah'**
  String get quranRangeTo;

  /// No description provided for @quranRangeToAyah.
  ///
  /// In en, this message translates to:
  /// **'To — ayah'**
  String get quranRangeToAyah;

  /// No description provided for @quranRangeToShort.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get quranRangeToShort;

  /// No description provided for @quranRangeToSurah.
  ///
  /// In en, this message translates to:
  /// **'To — surah'**
  String get quranRangeToSurah;

  /// No description provided for @quranRecitationApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get quranRecitationApply;

  /// No description provided for @quranRecitationAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll'**
  String get quranRecitationAutoScroll;

  /// No description provided for @quranRecitationAutoScrollDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically scroll the mushaf page to follow the recitation position.'**
  String get quranRecitationAutoScrollDesc;

  /// No description provided for @quranRecitationCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get quranRecitationCancel;

  /// No description provided for @quranRecitationClosePlayer.
  ///
  /// In en, this message translates to:
  /// **'Close player'**
  String get quranRecitationClosePlayer;

  /// No description provided for @quranRecitationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Recitation playback coming soon'**
  String get quranRecitationComingSoon;

  /// No description provided for @quranRecitationDownloading.
  ///
  /// In en, this message translates to:
  /// **'Caching…'**
  String get quranRecitationDownloading;

  /// No description provided for @quranRecitationEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get quranRecitationEnded;

  /// No description provided for @quranRecitationGoToQuran.
  ///
  /// In en, this message translates to:
  /// **'Go to Quran'**
  String get quranRecitationGoToQuran;

  /// No description provided for @quranRecitationHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight ayah'**
  String get quranRecitationHighlight;

  /// No description provided for @quranRecitationHighlightAutoDisabled.
  ///
  /// In en, this message translates to:
  /// **'Highlight and auto-scroll disabled for this riwayah'**
  String get quranRecitationHighlightAutoDisabled;

  /// No description provided for @quranRecitationHighlightAutoEnabled.
  ///
  /// In en, this message translates to:
  /// **'Highlight and auto-scroll enabled for this riwayah'**
  String get quranRecitationHighlightAutoEnabled;

  /// No description provided for @quranRecitationHighlightDesc.
  ///
  /// In en, this message translates to:
  /// **'Highlight the currently playing ayah in the mushaf.'**
  String get quranRecitationHighlightDesc;

  /// No description provided for @quranRecitationHighlightNonHafsWarning.
  ///
  /// In en, this message translates to:
  /// **'Ayah highlighting may be inaccurate for this riwayah.'**
  String get quranRecitationHighlightNonHafsWarning;

  /// No description provided for @quranRecitationNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get quranRecitationNext;

  /// No description provided for @quranRecitationNextAyah.
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get quranRecitationNextAyah;

  /// No description provided for @quranRecitationNextSurah.
  ///
  /// In en, this message translates to:
  /// **'Next surah'**
  String get quranRecitationNextSurah;

  /// No description provided for @quranRecitationNoTiming.
  ///
  /// In en, this message translates to:
  /// **'Per-ayah playback isn\'t available for this reciter'**
  String get quranRecitationNoTiming;

  /// No description provided for @quranRecitationOfflineAutoSave.
  ///
  /// In en, this message translates to:
  /// **'Save while listening'**
  String get quranRecitationOfflineAutoSave;

  /// No description provided for @quranRecitationOfflineAutoSaveOffHint.
  ///
  /// In en, this message translates to:
  /// **'Listening still works online. Use Save for offline for the current surah.'**
  String get quranRecitationOfflineAutoSaveOffHint;

  /// No description provided for @quranRecitationOfflineAutoSaveOnHint.
  ///
  /// In en, this message translates to:
  /// **'Recitations are saved automatically while you listen.'**
  String get quranRecitationOfflineAutoSaveOnHint;

  /// No description provided for @quranRecitationOfflineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recitations saved yet.'**
  String get quranRecitationOfflineEmpty;

  /// No description provided for @quranRecitationOfflineFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String quranRecitationOfflineFileCount(int count);

  /// No description provided for @quranRecitationOfflineFiles.
  ///
  /// In en, this message translates to:
  /// **'Offline files'**
  String get quranRecitationOfflineFiles;

  /// No description provided for @quranRecitationOfflineInFolder.
  ///
  /// In en, this message translates to:
  /// **'In this folder'**
  String get quranRecitationOfflineInFolder;

  /// No description provided for @quranRecitationOfflineOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get quranRecitationOfflineOpenFolder;

  /// No description provided for @quranRecitationOfflineStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage used'**
  String get quranRecitationOfflineStorageUsed;

  /// No description provided for @quranRecitationOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved recitations'**
  String get quranRecitationOfflineSubtitle;

  /// No description provided for @quranRecitationOpenPlayer.
  ///
  /// In en, this message translates to:
  /// **'Open player'**
  String get quranRecitationOpenPlayer;

  /// No description provided for @quranRecitationPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get quranRecitationPause;

  /// No description provided for @quranRecitationPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get quranRecitationPlay;

  /// No description provided for @quranRecitationPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Playback failed: {error}'**
  String quranRecitationPlaybackFailed(String error);

  /// No description provided for @quranRecitationPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get quranRecitationPrevious;

  /// No description provided for @quranRecitationPreviousAyah.
  ///
  /// In en, this message translates to:
  /// **'Previous ayah'**
  String get quranRecitationPreviousAyah;

  /// No description provided for @quranRecitationPreviousSurah.
  ///
  /// In en, this message translates to:
  /// **'Previous surah'**
  String get quranRecitationPreviousSurah;

  /// No description provided for @quranRecitationRangeRepeat.
  ///
  /// In en, this message translates to:
  /// **'Range & repeat'**
  String get quranRecitationRangeRepeat;

  /// No description provided for @quranRecitationRepeatProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String quranRecitationRepeatProgress(int current, int total);

  /// No description provided for @quranRecitationRepeatScopeEachAyah.
  ///
  /// In en, this message translates to:
  /// **'Repeat each ayah'**
  String get quranRecitationRepeatScopeEachAyah;

  /// No description provided for @quranRecitationRepeatScopeSelection.
  ///
  /// In en, this message translates to:
  /// **'Repeat selection'**
  String get quranRecitationRepeatScopeSelection;

  /// No description provided for @quranRecitationSaveOffline.
  ///
  /// In en, this message translates to:
  /// **'Save for offline'**
  String get quranRecitationSaveOffline;

  /// No description provided for @quranRecitationSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved offline'**
  String get quranRecitationSavedOffline;

  /// No description provided for @quranRecitationSavingOffline.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get quranRecitationSavingOffline;

  /// No description provided for @quranRecitationSelectionLoopProgress.
  ///
  /// In en, this message translates to:
  /// **'Loop {current} of {total}'**
  String quranRecitationSelectionLoopProgress(int current, int total);

  /// No description provided for @quranRecitationSleepAfter.
  ///
  /// In en, this message translates to:
  /// **'After {minutes} minutes'**
  String quranRecitationSleepAfter(String minutes);

  /// No description provided for @quranRecitationSleepEndOfAyah.
  ///
  /// In en, this message translates to:
  /// **'End of current ayah'**
  String get quranRecitationSleepEndOfAyah;

  /// No description provided for @quranRecitationSleepEndOfRange.
  ///
  /// In en, this message translates to:
  /// **'End of range'**
  String get quranRecitationSleepEndOfRange;

  /// No description provided for @quranRecitationSleepEndOfSurah.
  ///
  /// In en, this message translates to:
  /// **'End of surah'**
  String get quranRecitationSleepEndOfSurah;

  /// No description provided for @quranRecitationSleepOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get quranRecitationSleepOff;

  /// No description provided for @quranRecitationSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get quranRecitationSleepTimer;

  /// No description provided for @quranRecitationStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get quranRecitationStop;

  /// No description provided for @quranRecitationSwitchReciter.
  ///
  /// In en, this message translates to:
  /// **'Switch reciter'**
  String get quranRecitationSwitchReciter;

  /// No description provided for @quranRecitationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No reciter is available for playback'**
  String get quranRecitationUnavailable;

  /// No description provided for @quranRecitationVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get quranRecitationVolume;

  /// No description provided for @quranReciterFilterDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get quranReciterFilterDownloaded;

  /// No description provided for @quranReciterFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get quranReciterFilters;

  /// No description provided for @quranReciterRiwayahCount.
  ///
  /// In en, this message translates to:
  /// **'{count} riwayat'**
  String quranReciterRiwayahCount(int count);

  /// No description provided for @quranReciterRiwayahTitle.
  ///
  /// In en, this message translates to:
  /// **'Reciter & riwayah'**
  String get quranReciterRiwayahTitle;

  /// Shown when the selected riwayah lacks timing and is auto-upgraded
  ///
  /// In en, this message translates to:
  /// **'This riwayah doesn\'t support ayah sync. Switched to {riwayah}.'**
  String quranReciterRiwayahUpgraded(String riwayah);

  /// No description provided for @quranReciterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a reciter…'**
  String get quranReciterSearchHint;

  /// No description provided for @quranReciterStyleMujawwad.
  ///
  /// In en, this message translates to:
  /// **'Mujawwad'**
  String get quranReciterStyleMujawwad;

  /// No description provided for @quranReciterStyleMurattal.
  ///
  /// In en, this message translates to:
  /// **'Murattal'**
  String get quranReciterStyleMurattal;

  /// No description provided for @quranReciterSurahOnly.
  ///
  /// In en, this message translates to:
  /// **'Surah playback only'**
  String get quranReciterSurahOnly;

  /// No description provided for @quranReciterTimed.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get quranReciterTimed;

  /// No description provided for @quranSelectReciter.
  ///
  /// In en, this message translates to:
  /// **'Select reciter'**
  String get quranSelectReciter;

  /// No description provided for @quranSurahLabel.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}'**
  String quranSurahLabel(String surah);

  /// No description provided for @quranTextSize.
  ///
  /// In en, this message translates to:
  /// **'Quran text size'**
  String get quranTextSize;

  /// No description provided for @quranTextSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get quranTextSizeExtraLarge;

  /// No description provided for @quranTextSizeIndependentNote.
  ///
  /// In en, this message translates to:
  /// **'Quran reading size is independent of app and system text scaling.'**
  String get quranTextSizeIndependentNote;

  /// No description provided for @quranTextSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get quranTextSizeLarge;

  /// No description provided for @quranTextSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get quranTextSizeMedium;

  /// No description provided for @quranTextSizePreview.
  ///
  /// In en, this message translates to:
  /// **'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'**
  String get quranTextSizePreview;

  /// No description provided for @quranTextSizePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get quranTextSizePreviewLabel;

  /// No description provided for @quranTextSizeShortExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'XL'**
  String get quranTextSizeShortExtraLarge;

  /// No description provided for @quranTextSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get quranTextSizeSmall;

  /// No description provided for @quranTranslationQuoted.
  ///
  /// In en, this message translates to:
  /// **'\"{translation}\"'**
  String quranTranslationQuoted(String translation);

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @reflectionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts about this verse...'**
  String get reflectionPlaceholder;

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

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get saveNote;

  /// No description provided for @saveParameters.
  ///
  /// In en, this message translates to:
  /// **'Save Parameters'**
  String get saveParameters;

  /// No description provided for @scheduleAlertEventAdhan.
  ///
  /// In en, this message translates to:
  /// **'{prayer} adhan'**
  String scheduleAlertEventAdhan(String prayer);

  /// No description provided for @scheduleAlertEventIqamah.
  ///
  /// In en, this message translates to:
  /// **'{prayer} iqamah'**
  String scheduleAlertEventIqamah(String prayer);

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @scheduleAlertEventSunnah.
  ///
  /// In en, this message translates to:
  /// **'{prayer}'**
  String scheduleAlertEventSunnah(String prayer);

  /// No description provided for @scheduleAlertIqamahSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get scheduleAlertIqamahSound;

  /// No description provided for @scheduleAlertIqamahSoundHint.
  ///
  /// In en, this message translates to:
  /// **'Play alert when the time arrives'**
  String get scheduleAlertIqamahSoundHint;

  /// No description provided for @scheduleAlertNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get scheduleAlertNotify;

  /// No description provided for @scheduleAlertNotifyHint.
  ///
  /// In en, this message translates to:
  /// **'Show a notification without sound'**
  String get scheduleAlertNotifyHint;

  /// No description provided for @scheduleAlertOff.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get scheduleAlertOff;

  /// No description provided for @scheduleAlertOffHint.
  ///
  /// In en, this message translates to:
  /// **'No alert for this time'**
  String get scheduleAlertOffHint;

  /// No description provided for @scheduleAlertPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert for {event}'**
  String scheduleAlertPickerTitle(String event);

  /// No description provided for @scheduleAlertSound.
  ///
  /// In en, this message translates to:
  /// **'Adhan'**
  String get scheduleAlertSound;

  /// No description provided for @scheduleAlertSoundHint.
  ///
  /// In en, this message translates to:
  /// **'Play adhan when the time arrives'**
  String get scheduleAlertSoundHint;

  /// No description provided for @scrollMoreHint.
  ///
  /// In en, this message translates to:
  /// **'More below'**
  String get scrollMoreHint;

  /// No description provided for @searchForMore.
  ///
  /// In en, this message translates to:
  /// **'Search for more options'**
  String get searchForMore;

  /// No description provided for @searchPlaceAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchPlaceAction;

  /// No description provided for @searchPlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get searchPlaceLabel;

  /// No description provided for @searchPlaceQueryHint.
  ///
  /// In en, this message translates to:
  /// **'City, region, or address'**
  String get searchPlaceQueryHint;

  /// No description provided for @searchPlaceSubmitHint.
  ///
  /// In en, this message translates to:
  /// **'Press Enter or tap search'**
  String get searchPlaceSubmitHint;

  /// No description provided for @searchingPlace.
  ///
  /// In en, this message translates to:
  /// **'Searching for a place'**
  String get searchingPlace;

  /// No description provided for @searchQuran.
  ///
  /// In en, this message translates to:
  /// **'Search Quran...'**
  String get searchQuran;

  /// No description provided for @selectAyahToSeeContent.
  ///
  /// In en, this message translates to:
  /// **'Select an ayah to see the content.'**
  String get selectAyahToSeeContent;

  /// No description provided for @selectVerseToAddReflection.
  ///
  /// In en, this message translates to:
  /// **'Please select a verse to add a reflection'**
  String get selectVerseToAddReflection;

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

  /// No description provided for @shareAppName.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get shareAppName;

  /// No description provided for @shareAttributionPrefix.
  ///
  /// In en, this message translates to:
  /// **'Using'**
  String get shareAttributionPrefix;

  /// No description provided for @shareBasmalah.
  ///
  /// In en, this message translates to:
  /// **'Basmalah'**
  String get shareBasmalah;

  /// No description provided for @shareByApp.
  ///
  /// In en, this message translates to:
  /// **'Using {appName}'**
  String shareByApp(String appName);

  /// No description provided for @shareClipboardInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Install wl-clipboard (Wayland) or xclip (X11) to copy images'**
  String get shareClipboardInstallHint;

  /// No description provided for @shareCopyImage.
  ///
  /// In en, this message translates to:
  /// **'Copy image'**
  String get shareCopyImage;

  /// No description provided for @shareCouldNotCreateImage.
  ///
  /// In en, this message translates to:
  /// **'Could not create image'**
  String get shareCouldNotCreateImage;

  /// No description provided for @shareExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String shareExportFailed(String error);

  /// No description provided for @shareFailedToLoadPage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load page: {error}'**
  String shareFailedToLoadPage(String error);

  /// No description provided for @shareImageCopied.
  ///
  /// In en, this message translates to:
  /// **'Image copied to clipboard'**
  String get shareImageCopied;

  /// No description provided for @shareImageCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy image: {error}'**
  String shareImageCopyFailed(String error);

  /// No description provided for @shareImageSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Image saved'**
  String get shareImageSavedTitle;

  /// No description provided for @shareIncludeInImage.
  ///
  /// In en, this message translates to:
  /// **'Include in image'**
  String get shareIncludeInImage;

  /// No description provided for @sharePreserveLineBreaks.
  ///
  /// In en, this message translates to:
  /// **'Mushaf line breaks'**
  String get sharePreserveLineBreaks;

  /// No description provided for @sharePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get sharePreview;

  /// No description provided for @shareRangeDescription.
  ///
  /// In en, this message translates to:
  /// **'{startReference} – {endReference} ({verseCount})'**
  String shareRangeDescription(
    String startReference,
    String endReference,
    String verseCount,
  );

  /// No description provided for @shareRangeOnPage.
  ///
  /// In en, this message translates to:
  /// **'Range on page {page}'**
  String shareRangeOnPage(int page);

  /// No description provided for @shareRangeSingleDescription.
  ///
  /// In en, this message translates to:
  /// **'{reference} ({verseCount})'**
  String shareRangeSingleDescription(String reference, String verseCount);

  /// No description provided for @shareSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get shareSaveImage;

  /// No description provided for @shareSurahHeader.
  ///
  /// In en, this message translates to:
  /// **'Surah header'**
  String get shareSurahHeader;

  /// No description provided for @shareVerseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 verse} other{{count} verses}}'**
  String shareVerseCount(int count);

  /// No description provided for @shareVerses.
  ///
  /// In en, this message translates to:
  /// **'Share verses'**
  String get shareVerses;

  /// No description provided for @shortcutCategoryFortress.
  ///
  /// In en, this message translates to:
  /// **'Muslim Fortress'**
  String get shortcutCategoryFortress;

  /// No description provided for @shortcutCategoryGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get shortcutCategoryGlobal;

  /// No description provided for @shortcutCategoryHadith.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get shortcutCategoryHadith;

  /// No description provided for @shortcutCategoryQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get shortcutCategoryQuran;

  /// No description provided for @shortcutFocusSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Open or focus the search field on Quran, Hadith, and Muslim Fortress.'**
  String get shortcutFocusSearchDescription;

  /// No description provided for @shortcutFocusSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus search'**
  String get shortcutFocusSearchLabel;

  /// No description provided for @shortcutFocusSearchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Search is not available on this screen.'**
  String get shortcutFocusSearchUnavailable;

  /// No description provided for @shortcutFortressCountDescription.
  ///
  /// In en, this message translates to:
  /// **'Decrement the repeat counter during focus reading.'**
  String get shortcutFortressCountDescription;

  /// No description provided for @shortcutFortressCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Count thikr'**
  String get shortcutFortressCountLabel;

  /// No description provided for @shortcutFortressThikrNextDescription.
  ///
  /// In en, this message translates to:
  /// **'Go to the next thikr during focus reading.'**
  String get shortcutFortressThikrNextDescription;

  /// No description provided for @shortcutFortressThikrNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next thikr'**
  String get shortcutFortressThikrNextLabel;

  /// No description provided for @shortcutFortressThikrPrevDescription.
  ///
  /// In en, this message translates to:
  /// **'Go to the previous thikr during focus reading.'**
  String get shortcutFortressThikrPrevDescription;

  /// No description provided for @shortcutFortressThikrPrevLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous thikr'**
  String get shortcutFortressThikrPrevLabel;

  /// No description provided for @shortcutHadithResultNextDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the next hadith in the results list.'**
  String get shortcutHadithResultNextDescription;

  /// No description provided for @shortcutHadithResultNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next hadith'**
  String get shortcutHadithResultNextLabel;

  /// No description provided for @shortcutHadithResultPrevDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the previous hadith in the results list.'**
  String get shortcutHadithResultPrevDescription;

  /// No description provided for @shortcutHadithResultPrevLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous hadith'**
  String get shortcutHadithResultPrevLabel;

  /// No description provided for @shortcutOpenSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Go to the settings screen.'**
  String get shortcutOpenSettingsDescription;

  /// No description provided for @shortcutOpenSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get shortcutOpenSettingsLabel;

  /// No description provided for @shortcutQuranAyahNextDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the next ayah in study mode.'**
  String get shortcutQuranAyahNextDescription;

  /// No description provided for @shortcutQuranAyahNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get shortcutQuranAyahNextLabel;

  /// No description provided for @shortcutQuranAyahPrevDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the previous ayah in study mode.'**
  String get shortcutQuranAyahPrevDescription;

  /// No description provided for @shortcutQuranAyahPrevLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous ayah'**
  String get shortcutQuranAyahPrevLabel;

  /// No description provided for @shortcutQuranPageNextDescription.
  ///
  /// In en, this message translates to:
  /// **'Go to the next mushaf page (RTL reading direction).'**
  String get shortcutQuranPageNextDescription;

  /// No description provided for @shortcutQuranPageNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get shortcutQuranPageNextLabel;

  /// No description provided for @shortcutQuranPageNextSpaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Advance to the next mushaf page.'**
  String get shortcutQuranPageNextSpaceDescription;

  /// No description provided for @shortcutQuranPageNextSpaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Next page (Space)'**
  String get shortcutQuranPageNextSpaceLabel;

  /// No description provided for @shortcutQuranPagePrevDescription.
  ///
  /// In en, this message translates to:
  /// **'Go to the previous mushaf page.'**
  String get shortcutQuranPagePrevDescription;

  /// No description provided for @shortcutQuranPagePrevLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get shortcutQuranPagePrevLabel;

  /// No description provided for @shortcutQuranZoomInDescription.
  ///
  /// In en, this message translates to:
  /// **'Zoom the mushaf page larger (Ctrl/⌘ + scroll also works). Vertical scroll only when needed.'**
  String get shortcutQuranZoomInDescription;

  /// No description provided for @shortcutQuranZoomInLabel.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get shortcutQuranZoomInLabel;

  /// No description provided for @shortcutQuranZoomOutDescription.
  ///
  /// In en, this message translates to:
  /// **'Zoom the mushaf page smaller.'**
  String get shortcutQuranZoomOutDescription;

  /// No description provided for @shortcutQuranZoomOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get shortcutQuranZoomOutLabel;

  /// No description provided for @shortcutQuranZoomResetDescription.
  ///
  /// In en, this message translates to:
  /// **'Reset mushaf zoom to the saved text-size preference.'**
  String get shortcutQuranZoomResetDescription;

  /// No description provided for @shortcutQuranZoomResetLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset zoom'**
  String get shortcutQuranZoomResetLabel;

  /// No description provided for @shortcutToggleLocaleDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch between English and Arabic.'**
  String get shortcutToggleLocaleDescription;

  /// No description provided for @shortcutToggleLocaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Toggle language'**
  String get shortcutToggleLocaleLabel;

  /// No description provided for @shortcutToggleThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark mode.'**
  String get shortcutToggleThemeDescription;

  /// No description provided for @shortcutToggleThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get shortcutToggleThemeLabel;

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

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source:'**
  String get sourceLabel;

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

  /// No description provided for @studyMode.
  ///
  /// In en, this message translates to:
  /// **'Study Mode'**
  String get studyMode;

  /// No description provided for @sunnahAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer}'**
  String sunnahAlertTitle(String prayer);

  /// No description provided for @sunnahOsNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Sunnah prayer time has arrived.'**
  String get sunnahOsNotificationBody;

  /// No description provided for @sunnahTimes.
  ///
  /// In en, this message translates to:
  /// **'Sunnah Times'**
  String get sunnahTimes;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @surahAyahInfo.
  ///
  /// In en, this message translates to:
  /// **'{surahName} • Ayah {ayahNumber}'**
  String surahAyahInfo(String surahName, int ayahNumber);

  /// No description provided for @surahNameDefault.
  ///
  /// In en, this message translates to:
  /// **'Surah {number}'**
  String surahNameDefault(int number);

  /// No description provided for @tafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsir;

  /// No description provided for @tafsirAlMuyassar.
  ///
  /// In en, this message translates to:
  /// **'Tafsir Al-Muyassar'**
  String get tafsirAlMuyassar;

  /// No description provided for @tafsirTextMayBeIncomplete.
  ///
  /// In en, this message translates to:
  /// **'This commentary may be cut off in the source text.'**
  String get tafsirTextMayBeIncomplete;

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
  /// **'Configure calculation method, time format, and Iqamah settings.'**
  String get timeSectionSubtitle;

  /// No description provided for @timeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get timeSectionTitle;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @todayAchievement.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Achievement'**
  String get todayAchievement;

  /// No description provided for @todaysSchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get todaysSchedule;

  /// No description provided for @toggleArabic.
  ///
  /// In en, this message translates to:
  /// **'Toggle Arabic'**
  String get toggleArabic;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @trayHideApp.
  ///
  /// In en, this message translates to:
  /// **'Hide Tawaq'**
  String get trayHideApp;

  /// No description provided for @trayNextPrayerStatus.
  ///
  /// In en, this message translates to:
  /// **'Next: {prayer} · {time} · in {remaining}'**
  String trayNextPrayerStatus(String prayer, String time, String remaining);

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// No description provided for @trayShowApp.
  ///
  /// In en, this message translates to:
  /// **'Show Tawaq'**
  String get trayShowApp;

  /// No description provided for @trayStopAdhan.
  ///
  /// In en, this message translates to:
  /// **'Stop adhan'**
  String get trayStopAdhan;

  /// No description provided for @tryDifferentSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// No description provided for @turkiye.
  ///
  /// In en, this message translates to:
  /// **'Turkey (Diyanet)'**
  String get turkiye;

  /// No description provided for @typographySectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust UI text size and Quran reading size separately.'**
  String get typographySectionSubtitle;

  /// No description provided for @typographySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Text & scaling'**
  String get typographySectionTitle;

  /// No description provided for @ummAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm Al-Qura University'**
  String get ummAlQura;

  /// No description provided for @unavailableShort.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get unavailableShort;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get unknownLocation;

  /// No description provided for @unlockToEditCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Unlock to edit coordinates'**
  String get unlockToEditCoordinates;

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
