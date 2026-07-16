// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get a11yExpandSidebar => 'Expand sidebar';

  @override
  String get a11yNavigationUnavailable => 'Unavailable';

  @override
  String get a11yOpenLocationSettings => 'Open location settings';

  @override
  String a11ySettingsDecreaseIqamah(String prayer) {
    return 'Decrease $prayer iqamah minutes';
  }

  @override
  String a11ySettingsIncreaseIqamah(String prayer) {
    return 'Increase $prayer iqamah minutes';
  }

  @override
  String a11ySettingsResetIqamah(String prayer) {
    return 'Reset $prayer iqamah to default';
  }

  @override
  String get a11ySwitchToDarkTheme => 'Switch to dark theme';

  @override
  String get a11ySwitchToLightTheme => 'Switch to light theme';

  @override
  String get a11yWindowClose => 'Close window';

  @override
  String get a11yWindowMaximize => 'Maximize window';

  @override
  String get a11yWindowMinimize => 'Minimize window';

  @override
  String get a11yWindowRestore => 'Restore window';

  @override
  String get about => 'About';

  @override
  String get addReflection => 'Add a reflection...';

  @override
  String get adhan => 'Adhan';

  @override
  String get adhanAdjustments => 'Adhan adjustments (minutes)';

  @override
  String get adhanAlertPositionCenter => 'Center';

  @override
  String get adhanAlertPositionLabel => 'Alert position';

  @override
  String get adhanAlertPositionTopEnd => 'Top right';

  @override
  String get adhanAlertPositionTopStart => 'Top left';

  @override
  String adhanAlertTitle(String prayer) {
    return 'Adhan — $prayer';
  }

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
  String get adhanMuezzinAbedAlbasaei => 'Abed Al-Basaei';

  @override
  String get adhanMuezzinAhmadNufais => 'Ahmad Nufais';

  @override
  String get adhanMuezzinGhaziAlSaadoni => 'Ghazi Al-Saadoni';

  @override
  String get adhanMuezzinHamadDeghreri => 'Hamad Deghreri';

  @override
  String get adhanMuezzinHamdanAlMalki => 'Hamdan Al-Malki';

  @override
  String get adhanMuezzinIbrahimAlArkani => 'Ibrahim Al-Arkani';

  @override
  String get adhanMuezzinMajedAlHamathani => 'Majed Al-Hamathani';

  @override
  String get adhanMuezzinMakkah => 'Makkah';

  @override
  String get adhanMuezzinMansoorAlZahrani => 'Mansoor Az-Zahrani';

  @override
  String get adhanMuezzinMisharyAlafasi => 'Mishary Alafasi';

  @override
  String get adhanMuezzinMohammadAlMenshawy => 'Mohammad Al-Menshawy';

  @override
  String get adhanMuezzinMohammadRefat => 'Mohammad Refat';

  @override
  String get adhanMuezzinNasserAlQatami => 'Nasser Al-Qatami';

  @override
  String get adhanMuezzinSuhaibKhatba => 'Suhaib Khatba';

  @override
  String get adhanOsNotificationBody => 'Adhan is playing — tap to focus';

  @override
  String adhanPlayingTitle(String prayer) {
    return 'Adhan — $prayer';
  }

  @override
  String get adhanSectionSubtitle =>
      'Desktop adhan alerts and sounds. The app must stay running in the system tray for adhan to play.';

  @override
  String get adhanSectionTitle => 'Adhan';

  @override
  String get adhanShowAlertLabel => 'Show adhan alert';

  @override
  String get adhanShowOsNotificationLabel =>
      'OS notification when hidden in tray';

  @override
  String get adhanSoundLabel => 'Adhan sound';

  @override
  String get adhanStop => 'Stop';

  @override
  String get adhanVolumeLabel => 'Adhan volume';

  @override
  String get advancedSettingsTitle => 'Advanced Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSubtitle => 'Customize the app\'s theme and colors.';

  @override
  String get appName => 'Tawaq';

  @override
  String get appTextSize => 'App text size';

  @override
  String get appTextSizeCompact => 'Compact';

  @override
  String get appTextSizeExtraLarge => 'Extra large';

  @override
  String get appTextSizeLarge => 'Large';

  @override
  String get appTextSizeNormal => 'Default';

  @override
  String get appTextSizeShortExtraLarge => 'XL';

  @override
  String get appTextSizeSubtitle =>
      'Controls menus, labels, and other interface text.';

  @override
  String get arabic => 'Arabic';

  @override
  String get asr => 'Asr';

  @override
  String get autoLocationDisabled => 'Tap to enable automatic location';

  @override
  String get autoLocationEnabled => 'Location updates automatically';

  @override
  String get autoLocationMapOverlay =>
      'Location is updated automatically. Turn off the switch above to pick a location on the map.';

  @override
  String get autoSelectOrMap => 'Auto Select or Map';

  @override
  String get ayahBookmark => 'Bookmark';

  @override
  String ayahCopied(String reference) {
    return 'Copied $reference';
  }

  @override
  String get ayahCopy => 'Copy';

  @override
  String get ayahLabel => 'Ayah';

  @override
  String get ayahShare => 'Share';

  @override
  String get back => 'Back';

  @override
  String get basicParametersTitle => 'Basic Parameters';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String get blue => 'Blue';

  @override
  String get bookmarks => 'bookmarks';

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
  String get collapse => 'Collapse';

  @override
  String get collapsePanel => 'Collapse panel';

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
  String get daily => 'Daily';

  @override
  String get dark => 'Dark';

  @override
  String get decimalPlaceholder => '0.0';

  @override
  String get defaultLocation => 'Default location';

  @override
  String get defaultSurahName => 'Al-Fatihah';

  @override
  String get desktopForceMacStyleWindowControls =>
      'Use macOS-style window controls';

  @override
  String get desktopLaunchAtLogin => 'Start at login';

  @override
  String get desktopLaunchAtLoginHint =>
      'Start hidden in tray was also enabled so adhan alerts work after login.';

  @override
  String get desktopLaunchToTray => 'Start hidden in tray';

  @override
  String get desktopMinimizeToTray => 'Hide to tray when minimizing';

  @override
  String get desktopMinimizeToTrayOnClose =>
      'Hide to tray when closing the window';

  @override
  String get desktopSectionSubtitle =>
      'System tray, window behaviour, and startup on desktop.';

  @override
  String get desktopSectionTitle => 'Desktop';

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
  String get englishLanguage => 'English';

  @override
  String get errorLoadingTafsir => 'Error loading tafsir';

  @override
  String get errorLoadingTranslation => 'Error loading translation';

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
  String get expandPanel => 'Expand panel';

  @override
  String get fajr => 'Fajir';

  @override
  String get fajrAngleLabel => 'Fajr Angle (°)';

  @override
  String get footnote => 'Footnote';

  @override
  String get fortressAllChapters => 'All adhkar';

  @override
  String get fortressBenefit => 'Benefit';

  @override
  String get fortressBrowseWeakHadith => 'Weak & fabricated hadiths';

  @override
  String get fortressCompleted => 'Completed';

  @override
  String get fortressDhikrCopied => 'Dhikr copied';

  @override
  String get fortressEmptyFavoritesHint =>
      'Tap the bookmark icon next to any section to add it here';

  @override
  String get fortressEmptyFavoritesTitle => 'No favorite sections yet';

  @override
  String get fortressEmptySearchHint => 'Try different search terms';

  @override
  String get fortressEmptySearchTitle => 'No search results';

  @override
  String get fortressFakeHadithGuide => 'Weak & fabricated hadith guide';

  @override
  String get fortressFakeHadithIntro =>
      'Reference list from Hisn al-Muslim of hadiths scholars warn against.';

  @override
  String get fortressFavorites => 'Favorites';

  @override
  String get fortressFilterAuthenticity => 'Filter by grading';

  @override
  String get fortressFinish => 'Finish';

  @override
  String get fortressHideDetails => 'Hide details';

  @override
  String get fortressLoadError => 'Failed to load adhkar';

  @override
  String fortressMoreFavoriteChapters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Plus $count more chapters…',
      one: 'Plus 1 more chapter…',
    );
    return '$_temp0';
  }

  @override
  String get fortressNoAdhkarInChapter => 'No adhkar in this chapter';

  @override
  String get fortressNoFavoriteChapters =>
      'No favorite chapters yet — bookmark one from the sidebar';

  @override
  String get fortressNoRecommendations =>
      'No recommendations available right now';

  @override
  String get fortressNoSearchResults => 'No results found';

  @override
  String get fortressPrevious => 'Previous';

  @override
  String get fortressReadingHint =>
      'Tap the dhikr to count · Swipe horizontally to navigate · Space to count';

  @override
  String get fortressReadLong => 'Long reading';

  @override
  String get fortressReadMedium => 'Medium reading';

  @override
  String get fortressReadShort => 'Short reading';

  @override
  String get fortressRecommendedNow => 'Recommended now';

  @override
  String get fortressRelatedHadith => 'Related hadith';

  @override
  String fortressRemainingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count remaining',
      one: '1 remaining',
      zero: 'None remaining',
    );
    return '$_temp0';
  }

  @override
  String get fortressRetry => 'Retry';

  @override
  String get fortressSearchContents => 'Adhkar';

  @override
  String get fortressSearchHint => 'Search chapters and adhkar...';

  @override
  String get fortressSearchTitles => 'Chapters';

  @override
  String get fortressSharh => 'Explanation';

  @override
  String get fortressShowDetails => 'Show details';

  @override
  String get fortressShowSharh => 'Show explanation';

  @override
  String get fortressShowSource => 'Show source';

  @override
  String get fortressSourceReference => 'Source';

  @override
  String get fortressStartReading => 'Start reading';

  @override
  String fortressSupplicationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adhkar',
      one: '1 dhikr',
    );
    return '$_temp0';
  }

  @override
  String fortressSupplicationsInSection(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adhkar in this section',
      one: '1 dhikr in this section',
    );
    return '$_temp0';
  }

  @override
  String get fortressVirtue => 'Virtue';

  @override
  String get fortressWeakHadithWarning =>
      'Warning: this dhikr is weak or fabricated';

  @override
  String get fortressWelcomeSubtitle =>
      'Browse chapters from the list, or start from recommendations for your time or favorites.';

  @override
  String get fortressWelcomeTitle => 'Choose a chapter and begin dhikr';

  @override
  String get gettingLocation => 'Getting Location';

  @override
  String get goToPrayerPage => 'Go to Prayer Page';

  @override
  String get graphicalAnalysis => 'Graphical Analysis';

  @override
  String get green => 'Green';

  @override
  String get hadith => 'Hadith';

  @override
  String get hadithActiveFilters => 'Active Filters';

  @override
  String get hadithAlternateHadithSahih => 'Alternate Authentic Hadith';

  @override
  String get hadithAlternativeAuthentic => 'Alternative Authentic Narrations';

  @override
  String get hadithBackToSearch => 'Back to search';

  @override
  String get hadithBooks => 'Books';

  @override
  String get hadithClearAllFilters => 'Clear all filters';

  @override
  String get hadithClearAllRecents => 'Clear all';

  @override
  String get hadithCopied => 'Hadith copied';

  @override
  String get hadithDegreeAll => 'All degrees';

  @override
  String get hadithDegreeAuthenticChain => 'Chains scholars ruled authentic';

  @override
  String get hadithDegreeAuthenticHadith => 'Hadiths scholars ruled authentic';

  @override
  String get hadithDegrees => 'Degrees';

  @override
  String get hadithDegreeWeakChain => 'Chains scholars ruled weak';

  @override
  String get hadithDegreeWeakHadith => 'Hadiths scholars ruled weak';

  @override
  String get hadithDetailsTab => 'Details';

  @override
  String hadithFieldLabel(String label) {
    return '$label:';
  }

  @override
  String get hadithFilterTab => 'Filters';

  @override
  String get hadithFoundations => 'Foundations';

  @override
  String get hadithGradeExplanation => 'Grade Explanation';

  @override
  String get hadithLoadMore => 'Load more';

  @override
  String get hadithLoadSharh => 'Load Explanation';

  @override
  String hadithLoadSharhFailed(String error) {
    return 'Failed to load sharh: $error';
  }

  @override
  String get hadithMuhaddith => 'Muhaddith';

  @override
  String get hadithNarrator => 'Narrator';

  @override
  String get hadithNarrators => 'Narrators';

  @override
  String get hadithNoBookmarks => 'No saved hadiths yet';

  @override
  String get hadithNoDetailedData => 'No detailed data found for this hadith';

  @override
  String get hadithNoDetailsSelected =>
      'Select a hadith from results to view details';

  @override
  String get hadithNoMatchingResults => 'No matching results found';

  @override
  String get hadithNoRecentSearches => 'No recent searches yet';

  @override
  String get hadithOpenFilters => 'Filters';

  @override
  String get hadithRecentSearches => 'Recent Searches';

  @override
  String get hadithRelatedLinks => 'Related Links';

  @override
  String get hadithResetFilters => 'Reset filters';

  @override
  String hadithResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get hadithRetry => 'Retry';

  @override
  String get hadithScholars => 'Scholars';

  @override
  String get hadithScope => 'Scope';

  @override
  String get hadithSearchHint => 'Search hadith...';

  @override
  String get hadithSearchMethod => 'Search method';

  @override
  String get hadithSearchMethodAllWords => 'All words';

  @override
  String get hadithSearchMethodAnyWord => 'Any word';

  @override
  String get hadithSearchMethodExactMatch => 'Exact match';

  @override
  String get hadithSearchZoneAll => 'All hadiths';

  @override
  String get hadithSearchZoneMarfoo => 'Marfoo hadiths';

  @override
  String get hadithSearchZoneQudsi => 'Qudsi hadiths';

  @override
  String get hadithSearchZoneSahabaAthar => 'Companion narrations';

  @override
  String get hadithSearchZoneSharh => 'Hadith commentaries';

  @override
  String get hadithSharh => 'Explanation';

  @override
  String get hadithSimilar => 'Similar Hadiths';

  @override
  String get hadithSimilarHadith => 'Similar Hadith';

  @override
  String get hadithSource => 'Source';

  @override
  String hadithSourceCitation(String book, String reference) {
    return '$book ($reference)';
  }

  @override
  String get hadithSpecialist => 'Takhrij';

  @override
  String get hadithSpecialistHint =>
      'Only return hadiths that include takhrij in their metadata';

  @override
  String get hadithStartSearchPrompt => 'Start searching to see results';

  @override
  String get hadithTakhrij => 'Takhrij';

  @override
  String get hadithTypeToSearch => 'Type to search...';

  @override
  String get hadithUsulHadith => 'Usul al-Hadith';

  @override
  String get highLatitudeRule_middleOfTheNight => 'Middle of the Night';

  @override
  String get highLatitudeRule_seventhOfTheNight => 'Seventh of the Night';

  @override
  String get highLatitudeRule_twilightAngle => 'Twilight Angle';

  @override
  String get highLatitudeRuleLabel => 'High Latitude Rule';

  @override
  String hizbLabel(int number) {
    return 'Hizb $number';
  }

  @override
  String get integerPlaceholder => '0';

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
  String invalidParametersWithError(String message, String error) {
    return '$message $error';
  }

  @override
  String get iqamah => 'Iqamah';

  @override
  String get iqamahAdjustment => 'Iqamah Adjustment';

  @override
  String get iqamahAfterAdhan => 'Iqamah (minutes after adhan)';

  @override
  String iqamahAlertTitle(String prayer) {
    return 'Iqamah — $prayer';
  }

  @override
  String get iqamahMuezzinMadinah => 'Madinah';

  @override
  String get iqamahMuezzinYasserAlDossari => 'Yasser Al-Dossari';

  @override
  String get iqamahOsNotificationBody => 'Iqamah time — tap to focus';

  @override
  String iqamahPlayingTitle(String prayer) {
    return 'Iqamah — $prayer';
  }

  @override
  String get iqamahSavedDescription =>
      'Your iqamah adjustments have been saved successfully.';

  @override
  String iqamahSavedForPrayer(String prayer) {
    return 'Saved iqamah adjustment for $prayer.';
  }

  @override
  String get iqamahSavedTitle => 'Iqamah adjustments saved';

  @override
  String get iqamahSoundLabel => 'Iqamah call';

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
  String juzLabel(int number) {
    return 'Juz $number';
  }

  @override
  String get karachi => 'University of Islamic Sciences, Karachi';

  @override
  String get keyboardShortcutsCategorySubtitle =>
      'Available when using the app on desktop.';

  @override
  String get keyboardShortcutsSectionSubtitle =>
      'Reference list of keyboard shortcuts available on desktop. Shortcuts work app-wide from any screen, including this one. They cannot be customized.';

  @override
  String get keyboardShortcutsSectionTitle => 'Keyboard shortcuts';

  @override
  String get keyboardShortcutsTabTitle => 'Keyboard shortcuts';

  @override
  String get kuwait => 'Kuwait';

  @override
  String get languageLabel => 'Language';

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
  String get loading => 'Loading...';

  @override
  String get loadingAnalytics => 'Loading Analytics';

  @override
  String get loadingLocationSettings => 'Loading Location Settings';

  @override
  String get loadingSchedule => 'Loading schedule';

  @override
  String get locationCoordinatesLookupFailed =>
      'Could not determine timezone from coordinates.';

  @override
  String locationNoPlaceFound(String coordinates) {
    return 'No place found at $coordinates.';
  }

  @override
  String get locationPermissionDenied => 'Location permission was denied.';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission is permanently denied. Enable it in system settings.';

  @override
  String get locationSectionSubtitle =>
      'Set your geographical location and timezone for accurate prayer times.';

  @override
  String get locationSectionTitle => 'Location';

  @override
  String get locationServicesDisabled => 'Location services are disabled.';

  @override
  String get lockToPreventEdits => 'Lock to prevent edits';

  @override
  String get logPrayerStatus => 'Prayer Status';

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
  String get menuAddBookmark => 'Add bookmark';

  @override
  String get menuAddFavorite => 'Add to favorites';

  @override
  String get menuCopyText => 'Copy text';

  @override
  String get menuOpen => 'Open';

  @override
  String get menuRemoveBookmark => 'Remove bookmark';

  @override
  String get menuRemoveFavorite => 'Remove from favorites';

  @override
  String get midnight => 'Midnight';

  @override
  String get mediaSessionAppName => 'Tawaq';

  @override
  String mediaSessionAudioBy(String source) {
    return 'Audio by $source';
  }

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
  String get noDataAvailable => 'No data available';

  @override
  String get noResults => 'No results found.';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get northAmerica => 'North America (ISNA)';

  @override
  String get noTafsirAvailable => 'No tafsir available for this ayah';

  @override
  String get noTranslationAvailable => 'No translation available for this ayah';

  @override
  String get nowActive => 'Now Active';

  @override
  String get onboardingFinishAction => 'Get started';

  @override
  String get onboardingFinishPreviewUnavailable =>
      'Set your location to preview today\'s prayer times.';

  @override
  String get onboardingFinishSubtitle =>
      'Your prayer times are ready. You can adjust any setting later from Settings.';

  @override
  String get onboardingFinishTitle => 'You\'re all set';

  @override
  String get onboardingLanguageArabic => 'العربية';

  @override
  String get onboardingLanguageArabicSubtitle =>
      'Right-to-left layout with Arabic interface';

  @override
  String get onboardingLanguageEnglish => 'English';

  @override
  String get onboardingLanguageEnglishSubtitle =>
      'Left-to-right layout with English interface';

  @override
  String get onboardingLanguageStepHint =>
      'Choose the language you prefer for menus and labels.';

  @override
  String get onboardingLocationTipSubtitle =>
      'We use your city only to calculate accurate prayer times. Your location is stored on this device.';

  @override
  String get onboardingLocationTipTitle => 'Why we need your location';

  @override
  String get onboardingOpenSetupAction => 'Open setup';

  @override
  String get onboardingRerunSubtitle =>
      'Walk through language, location, prayer times, and notifications again.';

  @override
  String get onboardingRerunTitle => 'Run setup again';

  @override
  String get onboardingSetUpLater => 'Set up later';

  @override
  String get onboardingStepFinish => 'Ready to go';

  @override
  String onboardingStepFinishSubtitle(String appName) {
    return 'Review today\'s schedule and start using $appName.';
  }

  @override
  String get onboardingStepIqamah => 'Iqamah offsets';

  @override
  String get onboardingStepIqamahSubtitle =>
      'Minutes after adhan until iqamah for each prayer.';

  @override
  String get onboardingStepLanguage => 'Language';

  @override
  String get onboardingStepLanguageSubtitle =>
      'Pick how you\'d like to use the app.';

  @override
  String get onboardingStepLocation => 'Your location';

  @override
  String get onboardingStepLocationSubtitle =>
      'Set your city so prayer times match where you are.';

  @override
  String get onboardingStepNotifications => 'Notifications';

  @override
  String get onboardingStepNotificationsSubtitle =>
      'Choose adhan sounds and how alerts appear.';

  @override
  String get onboardingStepPrayerTimes => 'Prayer times';

  @override
  String get onboardingStepPrayerTimesSubtitle =>
      'Calculation method and time format.';

  @override
  String get onboardingStepTheme => 'Appearance';

  @override
  String get onboardingStepThemeSubtitle =>
      'Theme palette and interface text size.';

  @override
  String get onboardingStepWelcome => 'Welcome';

  @override
  String onboardingStepWelcomeSubtitle(String appName) {
    return 'A quick setup to personalize $appName for you.';
  }

  @override
  String get onboardingWelcomeSubtitle =>
      'We\'ll help you set up prayer times, notifications, and appearance in a few guided steps.';

  @override
  String get onboardingWelcomeTipSubtitle =>
      'You can revisit any of these choices later in Settings.';

  @override
  String get onboardingWelcomeTipTitle => 'Take your time';

  @override
  String onboardingWelcomeTitle(String appName) {
    return 'Welcome to $appName';
  }

  @override
  String get onTime => 'On Time';

  @override
  String get onTimePrayersLast30Days => 'On time prayers (last 30 days)';

  @override
  String get onTimePrayersLast365Days => 'On time prayers (last 365 days)';

  @override
  String get onTimePrayersLast7Days => 'On time prayers (last 7 days)';

  @override
  String get onTimePrayersToday => 'On time prayers (today)';

  @override
  String get onTimeRate => 'On Time Rate';

  @override
  String get openFolder => 'Open folder';

  @override
  String get openFolderFailed => 'Could not open folder';

  @override
  String get optionalHint => 'Optional';

  @override
  String get orange => 'Orange';

  @override
  String get other => 'Other';

  @override
  String pageJuzInfo(int page, int juz) {
    return 'Page $page • Juz $juz';
  }

  @override
  String pageLabel(int page) {
    return 'Page $page';
  }

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
  String get performanceIndicator => 'Performance Indicator';

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
  String get prayerAlertDismiss => 'Dismiss';

  @override
  String get prayerLocationRequiredAction => 'Open location settings';

  @override
  String get prayerLocationRequiredSubtitle =>
      'Prayer times need your coordinates. Open location settings to pick a city on the map or enter them manually.';

  @override
  String get prayerLocationRequiredTitle => 'Set your location';

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
  String quranAyahSearchPreviewTruncated(String preview) {
    return '$preview...';
  }

  @override
  String get quranDoublePageWidthFallback =>
      'Not enough width for a two-page spread — showing one page.';

  @override
  String get quranLayoutDoublePage => 'Double Page';

  @override
  String get quranLayoutStudyMode => 'Study Mode';

  @override
  String get quranNoMatchingReciters => 'No matching reciters';

  @override
  String get quranPlayAyah => 'Play this ayah';

  @override
  String get quranPlayRange => 'Play a range…';

  @override
  String get quranPlaySelection => 'Play selection';

  @override
  String get quranPlaySurah => 'Play this surah';

  @override
  String get quranRangeChooseSyncedReciter => 'Choose synced reciter';

  @override
  String get quranRangeFrom => 'From — surah & ayah';

  @override
  String get quranRangeFromAyah => 'From — ayah';

  @override
  String get quranRangeFromShort => 'From';

  @override
  String get quranRangeFromSurah => 'From — surah';

  @override
  String get quranRangeHizbBoundsNotFound => 'Could not load hizb boundaries';

  @override
  String get quranRangeHizbNotFound => 'Could not find the hizb for this ayah';

  @override
  String get quranRangeJuzBoundsNotFound => 'Could not load juz boundaries';

  @override
  String get quranRangeJuzNotFound => 'Could not find the juz for this ayah';

  @override
  String get quranRangeModeLabel => 'End behavior';

  @override
  String get quranRangePlay => 'Play selection';

  @override
  String get quranRangePresetAyah => 'This ayah';

  @override
  String get quranRangePresetContinueFromHere => 'Continue from here';

  @override
  String get quranRangePresetCustom => 'Custom';

  @override
  String get quranRangePresetFailed => 'Could not apply this range preset';

  @override
  String get quranRangePresetHizb => 'This hizb';

  @override
  String get quranRangePresetJuz => 'This juz';

  @override
  String get quranRangePresetSurah => 'This surah';

  @override
  String quranRangeRepeatChip(int count) {
    return '×$count';
  }

  @override
  String get quranRangeRepeatEachAyah => 'Repeat each ayah';

  @override
  String get quranRangeRepeatOnce => 'Once';

  @override
  String get quranRangeRepeatSelection => 'Repeat range';

  @override
  String quranRangeRepeatTimes(int count) {
    return '$count times';
  }

  @override
  String get quranRangeRepeatTwice => 'Twice';

  @override
  String get quranRangeRequiresTimedReciter =>
      'Select a synced reciter to play this ayah range';

  @override
  String get quranRangeSave => 'Save range';

  @override
  String get quranRangeScope => 'Range';

  @override
  String get quranRangeTitle => 'Range & repeat for memorization';

  @override
  String get quranRangeTo => 'To — surah & ayah';

  @override
  String get quranRangeToAyah => 'To — ayah';

  @override
  String get quranRangeToShort => 'To';

  @override
  String get quranRangeToSurah => 'To — surah';

  @override
  String get quranRecitationApply => 'Apply';

  @override
  String get quranRecitationAutoScroll => 'Auto-scroll';

  @override
  String get quranRecitationAutoScrollDesc =>
      'Automatically scroll the mushaf page to follow the recitation position.';

  @override
  String get quranRecitationCancel => 'Cancel';

  @override
  String get quranRecitationClosePlayer => 'Close player';

  @override
  String get quranRecitationComingSoon => 'Recitation playback coming soon';

  @override
  String get quranRecitationDownloading => 'Caching…';

  @override
  String get quranRecitationEnded => 'Ended';

  @override
  String get quranRecitationGoToQuran => 'Go to Quran';

  @override
  String get quranRecitationHighlight => 'Highlight ayah';

  @override
  String get quranRecitationHighlightAutoDisabled =>
      'Highlight and auto-scroll disabled for this riwayah';

  @override
  String get quranRecitationHighlightAutoEnabled =>
      'Highlight and auto-scroll enabled for this riwayah';

  @override
  String get quranRecitationHighlightDesc =>
      'Highlight the currently playing ayah in the mushaf.';

  @override
  String get quranRecitationHighlightNonHafsWarning =>
      'Ayah highlighting may be inaccurate for this riwayah.';

  @override
  String get quranRecitationNext => 'Next';

  @override
  String get quranRecitationNextAyah => 'Next ayah';

  @override
  String get quranRecitationNextSurah => 'Next surah';

  @override
  String get quranRecitationNoTiming =>
      'Per-ayah playback isn\'t available for this reciter';

  @override
  String get quranRecitationOfflineAutoSave =>
      'Recitations are saved automatically while you listen.';

  @override
  String get quranRecitationOfflineEmpty => 'No recitations saved yet.';

  @override
  String quranRecitationOfflineFileCount(int count) {
    return '$count files';
  }

  @override
  String get quranRecitationOfflineFiles => 'Offline files';

  @override
  String get quranRecitationOfflineInFolder => 'In this folder';

  @override
  String get quranRecitationOfflineOpenFolder => 'Open folder';

  @override
  String get quranRecitationOfflineStorageUsed => 'Storage used';

  @override
  String get quranRecitationOfflineSubtitle => 'Saved recitations';

  @override
  String get quranRecitationOpenPlayer => 'Open player';

  @override
  String get quranRecitationPause => 'Pause';

  @override
  String get quranRecitationPlay => 'Play';

  @override
  String quranRecitationPlaybackFailed(String error) {
    return 'Playback failed: $error';
  }

  @override
  String get quranRecitationPrevious => 'Previous';

  @override
  String get quranRecitationPreviousAyah => 'Previous ayah';

  @override
  String get quranRecitationPreviousSurah => 'Previous surah';

  @override
  String get quranRecitationRangeRepeat => 'Range & repeat';

  @override
  String quranRecitationRepeatProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get quranRecitationRepeatScopeEachAyah => 'Repeat each ayah';

  @override
  String get quranRecitationRepeatScopeSelection => 'Repeat selection';

  @override
  String quranRecitationSelectionLoopProgress(int current, int total) {
    return 'Loop $current of $total';
  }

  @override
  String quranRecitationSleepAfter(String minutes) {
    return 'After $minutes minutes';
  }

  @override
  String get quranRecitationSleepEndOfAyah => 'End of current ayah';

  @override
  String get quranRecitationSleepEndOfRange => 'End of range';

  @override
  String get quranRecitationSleepEndOfSurah => 'End of surah';

  @override
  String get quranRecitationSleepOff => 'Off';

  @override
  String get quranRecitationSleepTimer => 'Sleep timer';

  @override
  String get quranRecitationStop => 'Stop';

  @override
  String get quranRecitationSwitchReciter => 'Switch reciter';

  @override
  String get quranRecitationUnavailable =>
      'No reciter is available for playback';

  @override
  String get quranRecitationVolume => 'Volume';

  @override
  String get quranReciterFilterDownloaded => 'Downloaded';

  @override
  String get quranReciterFilters => 'Filters';

  @override
  String quranReciterRiwayahCount(int count) {
    return '$count riwayat';
  }

  @override
  String get quranReciterRiwayahTitle => 'Reciter & riwayah';

  @override
  String quranReciterRiwayahUpgraded(String riwayah) {
    return 'This riwayah doesn\'t support ayah sync. Switched to $riwayah.';
  }

  @override
  String get quranReciterSearchHint => 'Search for a reciter…';

  @override
  String get quranReciterStyleMujawwad => 'Mujawwad';

  @override
  String get quranReciterStyleMurattal => 'Murattal';

  @override
  String get quranReciterSurahOnly => 'Surah playback only';

  @override
  String get quranReciterTimed => 'Synced';

  @override
  String get quranSelectReciter => 'Select reciter';

  @override
  String quranSurahLabel(String surah) {
    return 'Surah $surah';
  }

  @override
  String get quranTextSize => 'Quran text size';

  @override
  String get quranTextSizeExtraLarge => 'Extra large';

  @override
  String get quranTextSizeIndependentNote =>
      'Quran reading size is independent of app and system text scaling.';

  @override
  String get quranTextSizeLarge => 'Large';

  @override
  String get quranTextSizeMedium => 'Medium';

  @override
  String get quranTextSizePreview => 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  @override
  String get quranTextSizePreviewLabel => 'Preview';

  @override
  String get quranTextSizeShortExtraLarge => 'XL';

  @override
  String get quranTextSizeSmall => 'Small';

  @override
  String quranTranslationQuoted(String translation) {
    return '\"$translation\"';
  }

  @override
  String get red => 'Red';

  @override
  String get reflectionPlaceholder => 'Write your thoughts about this verse...';

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
  String get saveNote => 'Save Note';

  @override
  String get saveParameters => 'Save Parameters';

  @override
  String scheduleAlertEventAdhan(String prayer) {
    return '$prayer adhan';
  }

  @override
  String scheduleAlertEventIqamah(String prayer) {
    return '$prayer iqamah';
  }

  @override
  String get or => 'or';

  @override
  String scheduleAlertEventSunnah(String prayer) {
    return '$prayer';
  }

  @override
  String get scheduleAlertIqamahSound => 'Sound';

  @override
  String get scheduleAlertIqamahSoundHint => 'Play alert when the time arrives';

  @override
  String get scheduleAlertNotify => 'Notify';

  @override
  String get scheduleAlertNotifyHint => 'Show a notification without sound';

  @override
  String get scheduleAlertOff => 'Silent';

  @override
  String get scheduleAlertOffHint => 'No alert for this time';

  @override
  String scheduleAlertPickerTitle(String event) {
    return 'Alert for $event';
  }

  @override
  String get scheduleAlertSound => 'Adhan';

  @override
  String get scheduleAlertSoundHint => 'Play adhan when the time arrives';

  @override
  String get scrollMoreHint => 'More below';

  @override
  String get searchForMore => 'Search for more options';

  @override
  String get searchPlaceLabel => 'Search for a place';

  @override
  String get searchQuran => 'Search Quran...';

  @override
  String get selectAyahToSeeContent => 'Select an ayah to see the content.';

  @override
  String get selectVerseToAddReflection =>
      'Please select a verse to add a reflection';

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
  String get shareAppName => 'App name';

  @override
  String get shareAttributionPrefix => 'Using';

  @override
  String get shareBasmalah => 'Basmalah';

  @override
  String shareByApp(String appName) {
    return 'Using $appName';
  }

  @override
  String get shareClipboardInstallHint =>
      'Install wl-clipboard (Wayland) or xclip (X11) to copy images';

  @override
  String get shareCopyImage => 'Copy image';

  @override
  String get shareCouldNotCreateImage => 'Could not create image';

  @override
  String shareExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String shareFailedToLoadPage(String error) {
    return 'Failed to load page: $error';
  }

  @override
  String get shareImageCopied => 'Image copied to clipboard';

  @override
  String shareImageCopyFailed(String error) {
    return 'Could not copy image: $error';
  }

  @override
  String get shareImageSavedTitle => 'Image saved';

  @override
  String get shareIncludeInImage => 'Include in image';

  @override
  String get sharePreserveLineBreaks => 'Mushaf line breaks';

  @override
  String get sharePreview => 'Preview';

  @override
  String shareRangeDescription(
    String startReference,
    String endReference,
    String verseCount,
  ) {
    return '$startReference – $endReference ($verseCount)';
  }

  @override
  String shareRangeOnPage(int page) {
    return 'Range on page $page';
  }

  @override
  String shareRangeSingleDescription(String reference, String verseCount) {
    return '$reference ($verseCount)';
  }

  @override
  String get shareSaveImage => 'Save image';

  @override
  String get shareSurahHeader => 'Surah header';

  @override
  String shareVerseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verses',
      one: '1 verse',
    );
    return '$_temp0';
  }

  @override
  String get shareVerses => 'Share verses';

  @override
  String get shortcutCategoryFortress => 'Muslim Fortress';

  @override
  String get shortcutCategoryGlobal => 'Global';

  @override
  String get shortcutCategoryHadith => 'Hadith';

  @override
  String get shortcutCategoryQuran => 'Quran';

  @override
  String get shortcutFocusSearchDescription =>
      'Open or focus the search field on Quran, Hadith, and Muslim Fortress.';

  @override
  String get shortcutFocusSearchLabel => 'Focus search';

  @override
  String get shortcutFocusSearchUnavailable =>
      'Search is not available on this screen.';

  @override
  String get shortcutFortressCountDescription =>
      'Decrement the repeat counter during focus reading.';

  @override
  String get shortcutFortressCountLabel => 'Count thikr';

  @override
  String get shortcutFortressThikrNextDescription =>
      'Go to the next thikr during focus reading.';

  @override
  String get shortcutFortressThikrNextLabel => 'Next thikr';

  @override
  String get shortcutFortressThikrPrevDescription =>
      'Go to the previous thikr during focus reading.';

  @override
  String get shortcutFortressThikrPrevLabel => 'Previous thikr';

  @override
  String get shortcutHadithResultNextDescription =>
      'Select the next hadith in the results list.';

  @override
  String get shortcutHadithResultNextLabel => 'Next hadith';

  @override
  String get shortcutHadithResultPrevDescription =>
      'Select the previous hadith in the results list.';

  @override
  String get shortcutHadithResultPrevLabel => 'Previous hadith';

  @override
  String get shortcutOpenSettingsDescription => 'Go to the settings screen.';

  @override
  String get shortcutOpenSettingsLabel => 'Open settings';

  @override
  String get shortcutQuranAyahNextDescription =>
      'Select the next ayah in study mode.';

  @override
  String get shortcutQuranAyahNextLabel => 'Next ayah';

  @override
  String get shortcutQuranAyahPrevDescription =>
      'Select the previous ayah in study mode.';

  @override
  String get shortcutQuranAyahPrevLabel => 'Previous ayah';

  @override
  String get shortcutQuranPageNextDescription =>
      'Go to the next mushaf page (RTL reading direction).';

  @override
  String get shortcutQuranPageNextLabel => 'Next page';

  @override
  String get shortcutQuranPageNextSpaceDescription =>
      'Advance to the next mushaf page.';

  @override
  String get shortcutQuranPageNextSpaceLabel => 'Next page (Space)';

  @override
  String get shortcutQuranPagePrevDescription =>
      'Go to the previous mushaf page.';

  @override
  String get shortcutQuranPagePrevLabel => 'Previous page';

  @override
  String get shortcutToggleLocaleDescription =>
      'Switch between English and Arabic.';

  @override
  String get shortcutToggleLocaleLabel => 'Toggle language';

  @override
  String get shortcutToggleThemeDescription =>
      'Switch between light and dark mode.';

  @override
  String get shortcutToggleThemeLabel => 'Toggle theme';

  @override
  String get signedExampleHint => '20 or -10';

  @override
  String get singapore => 'Singapore';

  @override
  String get skip => 'Skip';

  @override
  String get slate => 'Slate';

  @override
  String get sourceLabel => 'Source:';

  @override
  String get status => 'Status';

  @override
  String get stone => 'Stone';

  @override
  String streakInDays(int streak) {
    return '$streak days';
  }

  @override
  String get studyMode => 'Study Mode';

  @override
  String sunnahAlertTitle(String prayer) {
    return '$prayer';
  }

  @override
  String get sunnahOsNotificationBody => 'Sunnah time — tap to focus';

  @override
  String get sunnahTimes => 'Sunnah Times';

  @override
  String get sunrise => 'Sunrise';

  @override
  String surahAyahInfo(String surahName, int ayahNumber) {
    return '$surahName • Ayah $ayahNumber';
  }

  @override
  String surahNameDefault(int number) {
    return 'Surah $number';
  }

  @override
  String get tafsir => 'Tafsir';

  @override
  String get tafsirAlMuyassar => 'Tafsir Al-Muyassar';

  @override
  String get tafsirTextMayBeIncomplete =>
      'This commentary may be cut off in the source text.';

  @override
  String get tehran => 'Tehran';

  @override
  String get timeFormat => 'Time Format';

  @override
  String get timeSectionSubtitle =>
      'Configure calculation method, time format, and Iqamah settings.';

  @override
  String get timeSectionTitle => 'Prayer Times';

  @override
  String get timezone => 'Timezone';

  @override
  String get todayAchievement => 'Today\'s Achievement';

  @override
  String get todaysSchedule => 'Today\'s Schedule';

  @override
  String get toggleArabic => 'Toggle Arabic';

  @override
  String get total => 'Total';

  @override
  String get translation => 'Translation';

  @override
  String get trayHideApp => 'Hide Tawaq';

  @override
  String get trayMuteAdhan => 'Mute adhan';

  @override
  String trayNextPrayer(String prayer) {
    return 'Next: $prayer';
  }

  @override
  String get trayQuit => 'Quit';

  @override
  String get trayShowApp => 'Show Tawaq';

  @override
  String get tryDifferentSearchTerm => 'Try a different search term';

  @override
  String get turkiye => 'Turkey (Diyanet)';

  @override
  String get typographySectionSubtitle =>
      'Adjust UI text size and Quran reading size separately.';

  @override
  String get typographySectionTitle => 'Text & scaling';

  @override
  String get ummAlQura => 'Umm Al-Qura University';

  @override
  String get unavailableShort => '—';

  @override
  String get unknownLocation => 'Unknown location';

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
  String get yearly => 'Yearly';

  @override
  String get yellow => 'Yellow';

  @override
  String get zinc => 'Zinc';
}
