// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get a11yExpandSidebar => 'توسيع الشريط الجانبي';

  @override
  String get a11yNavigationUnavailable => 'غير متاح';

  @override
  String get a11yOpenLocationSettings => 'فتح إعدادات الموقع';

  @override
  String a11ySettingsDecreaseIqamah(String prayer) {
    return 'تقليل دقائق إقامة $prayer';
  }

  @override
  String a11ySettingsIncreaseIqamah(String prayer) {
    return 'زيادة دقائق إقامة $prayer';
  }

  @override
  String a11ySettingsResetIqamah(String prayer) {
    return 'إعادة إقامة $prayer إلى الافتراضي';
  }

  @override
  String get a11ySwitchToDarkTheme => 'التبديل إلى الوضع الداكن';

  @override
  String get a11ySwitchToLightTheme => 'التبديل إلى الوضع الفاتح';

  @override
  String get a11yWindowClose => 'إغلاق النافذة';

  @override
  String get a11yWindowMaximize => 'تكبير النافذة';

  @override
  String get a11yWindowMinimize => 'تصغير النافذة';

  @override
  String get a11yWindowRestore => 'استعادة النافذة';

  @override
  String get about => 'عن التطبيق';

  @override
  String get addReflection => 'أضف خاطرة...';

  @override
  String get adhan => 'الأذان';

  @override
  String get adhanAdjustments => 'تعديلات الأذان (بالدقائق)';

  @override
  String get adhanAlertPositionCenter => 'الوسط';

  @override
  String get adhanAlertPositionLabel => 'موضع التنبيه';

  @override
  String get adhanAlertPositionTopEnd => 'أعلى اليمين';

  @override
  String get adhanAlertPositionTopStart => 'أعلى اليسار';

  @override
  String adhanAlertTitle(String prayer) {
    return 'الأذان — $prayer';
  }

  @override
  String adhanHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'قبل $hours ساعة',
      many: 'قبل $hours ساعة',
      few: 'قبل $hours ساعات',
      two: 'قبل ساعتين',
      one: 'قبل ساعة',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String adhanHoursLeft(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'متبقي $hours ساعة',
      many: 'متبقي $hours ساعة',
      few: 'متبقي $hours ساعات',
      two: 'متبقي ساعتين',
      one: 'متبقي ساعة',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String adhanMinsAgo(int mins) {
    String _temp0 = intl.Intl.pluralLogic(
      mins,
      locale: localeName,
      other: 'قبل $mins دقيقة',
      many: 'قبل $mins دقيقة',
      few: 'قبل $mins دقائق',
      two: 'قبل دقيقتين',
      one: 'قبل دقيقة',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String adhanMinsLeft(int mins) {
    String _temp0 = intl.Intl.pluralLogic(
      mins,
      locale: localeName,
      other: 'متبقي $mins دقيقة',
      many: 'متبقي $mins دقيقة',
      few: 'متبقي $mins دقائق',
      two: 'متبقي دقيقتين',
      one: 'متبقي دقيقة',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String get adhanMuezzinAbedAlbasaei => 'عبد الباسط عبد الصمد';

  @override
  String get adhanMuezzinAhmadNufais => 'أحمد النفيس';

  @override
  String get adhanMuezzinGhaziAlSaadoni => 'غازي السعدوني';

  @override
  String get adhanMuezzinHamadDeghreri => 'حمد دغريري';

  @override
  String get adhanMuezzinHamdanAlMalki => 'حمدان المالكي';

  @override
  String get adhanMuezzinIbrahimAlArkani => 'إبراهيم الأركاني';

  @override
  String get adhanMuezzinMajedAlHamathani => 'ماجد الحماثني';

  @override
  String get adhanMuezzinMakkah => 'مكة المكرمة';

  @override
  String get adhanMuezzinMansoorAlZahrani => 'منصور الزهراني';

  @override
  String get adhanMuezzinMisharyAlafasi => 'مشاري العفاسي';

  @override
  String get adhanMuezzinMohammadAlMenshawy => 'محمد المنشاوي';

  @override
  String get adhanMuezzinMohammadRefat => 'محمد رفعت';

  @override
  String get adhanMuezzinNasserAlQatami => 'ناصر القطامي';

  @override
  String get adhanMuezzinSuhaibKhatba => 'صهيب خطاب';

  @override
  String get adhanOsNotificationBody => 'حان وقت الصلاة.';

  @override
  String adhanPlayingTitle(String prayer) {
    return 'الأذان — $prayer';
  }

  @override
  String get adhanSectionSubtitle =>
      'تنبيهات وأصوات الأذان على سطح المكتب. يجب أن يبقى التطبيق يعمل في شريط النظام لتشغيل الأذان.';

  @override
  String get adhanSectionTitle => 'الأذان';

  @override
  String get adhanShowAlertLabel => 'إظهار تنبيه الأذان';

  @override
  String get adhanShowOsNotificationLabel =>
      'إشعار النظام عند الإخفاء في الشريط';

  @override
  String get adhanSoundLabel => 'صوت الأذان';

  @override
  String get adhanStop => 'إيقاف';

  @override
  String get adhanVolumeLabel => 'مستوى صوت الأذان';

  @override
  String get advancedSettingsTitle => 'إعدادات متقدمة';

  @override
  String get appearance => 'المظهر';

  @override
  String get appearanceSubtitle => 'تخصيص سمة التطبيق وألوانه.';

  @override
  String get appName => 'تَوَّاق';

  @override
  String get appTextSize => 'حجم نص التطبيق';

  @override
  String get appTextSizeCompact => 'مضغوط';

  @override
  String get appTextSizeExtraLarge => 'كبير جداً';

  @override
  String get appTextSizeLarge => 'كبير';

  @override
  String get appTextSizeNormal => 'افتراضي';

  @override
  String get appTextSizeShortExtraLarge => 'أكبر';

  @override
  String get appTextSizeSubtitle => 'يتحكم في القوائم والعناوين ونص الواجهة.';

  @override
  String get arabic => 'العربية';

  @override
  String get asr => 'العصر';

  @override
  String get autoLocationDisabled => 'انقر لتفعيل الموقع التلقائي';

  @override
  String get autoLocationEnabled => 'يُحدَّث الموقع تلقائيًا';

  @override
  String get autoLocationMapOverlay =>
      'يُحدَّث الموقع تلقائيًا. أوقف المفتاح أعلاه لاختيار موقع على الخريطة.';

  @override
  String get autoSelectOrMap => 'تحديد تلقائي أو بالخريطة';

  @override
  String get ayahBookmark => 'إشارة مرجعية';

  @override
  String ayahCopied(String reference) {
    return 'تم نسخ $reference';
  }

  @override
  String get ayahCopy => 'نسخ';

  @override
  String get ayahLabel => 'الآية';

  @override
  String get ayahShare => 'مشاركة';

  @override
  String get back => 'رجوع';

  @override
  String get basicParametersTitle => 'إعدادات أساسية';

  @override
  String get bestStreak => 'أفضل إنجاز';

  @override
  String get blue => 'أزرق';

  @override
  String get bookmarks => 'المحفوظات';

  @override
  String get calculationMethod => 'طريقة الحساب';

  @override
  String get cancel => 'إلغاء';

  @override
  String get changingTimezone => 'تغيير المنطقة الزمنية';

  @override
  String get chooseCalculationMethod => 'اختر طريقة الحساب';

  @override
  String get chooseLocation => 'اختر الموقع';

  @override
  String get collapse => 'طي';

  @override
  String get collapsePanel => 'طي اللوحة';

  @override
  String get colorTheme => 'نمط الألوان';

  @override
  String get colorThemeSubtitle => 'اختر المخطوطة أو المحايد.';

  @override
  String get completed => 'مكتملة';

  @override
  String get completionStatus => 'حالة الإكمال';

  @override
  String get coordinates => 'الإحداثيات الجغرافية';

  @override
  String get currentPrayer => 'الصلاة الحالية';

  @override
  String get currentStreak => 'الإنجاز الحالي';

  @override
  String get customParametersCollapsedHint =>
      'انقر لتكوين إعدادات الحساب المخصصة';

  @override
  String get customParametersLabel => 'إعدادات مخصصة';

  @override
  String get customParametersTitle => 'إعدادات مخصصة';

  @override
  String get daily => 'يومي';

  @override
  String get dark => 'داكن';

  @override
  String get decimalPlaceholder => '٠٫٠';

  @override
  String get defaultLocation => 'الموقع الافتراضي';

  @override
  String get defaultSurahName => 'الفاتحة';

  @override
  String get deleteReflection => 'حذف الخاطرة';

  @override
  String get deleteReflectionConfirm =>
      'حذف هذه الخاطرة؟ لا يمكن التراجع عن ذلك.';

  @override
  String get desktopForceMacStyleWindowControls =>
      'استخدام أزرار نافذة بنمط macOS';

  @override
  String get desktopLaunchAtLogin => 'البدء عند تسجيل الدخول';

  @override
  String get desktopLaunchAtLoginHint =>
      'تم تفعيل البدء مخفياً في الشريط أيضاً حتى تعمل تنبيهات الأذان بعد تسجيل الدخول.';

  @override
  String get desktopLaunchToTray => 'البدء مخفياً في الشريط';

  @override
  String get desktopMinimizeToTray => 'الإخفاء في الشريط عند التصغير';

  @override
  String get desktopMinimizeToTrayOnClose =>
      'الإخفاء في الشريط عند إغلاق النافذة';

  @override
  String get desktopSectionSubtitle =>
      'شريط النظام وسلوك النافذة والبدء التلقائي على سطح المكتب.';

  @override
  String get desktopSectionTitle => 'سطح المكتب';

  @override
  String get detectTimezone => 'اكتشاف المنطقة الزمنية';

  @override
  String get detectTimezoneNotImplemented =>
      'اكتشاف المنطقة الزمنية غير متاح هنا.';

  @override
  String get deviceLocationNotImplemented =>
      'استخدام موقع الجهاز غير متاح هنا.';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get done => 'تم';

  @override
  String get dragTheMapTip => 'اسحب الخريطة لتحديد مؤشر الموقع';

  @override
  String get dubai => 'دبي';

  @override
  String get editsSavedDescription => 'حُفظت تغييراتك بنجاح.';

  @override
  String get editsSavedTitle => 'حُفظت التعديلات';

  @override
  String get egyptian => 'الهيئة العامة المصرية للمساحة';

  @override
  String get english => 'الإنجيليزية';

  @override
  String get englishLanguage => 'الإنجليزية';

  @override
  String get errorLoadingTafsir => 'تعذّر تحميل التفسير';

  @override
  String get errorLoadingTranslation => 'تعذّر تحميل الترجمة';

  @override
  String get errorNotFoundPage =>
      'لم نتمكن من الوصول إلى هذه الصفحة. تحقق من الرابط ثم أعد المحاولة.';

  @override
  String errorOccurredWhile(String whileError) {
    return 'حدث خطأ أثناء $whileError';
  }

  @override
  String get errorUpdatingLocationDescription =>
      'حُدثت الإحداثيات بنجاح، ولكن لم نتمكن من جلب اسم موقعك. لن يؤثر ذلك على عمل التطبيق.';

  @override
  String get errorUpdatingLocationTitle => 'حدث خطأ أثناء تحديث الموقع';

  @override
  String get expandPanel => 'توسيع اللوحة';

  @override
  String get fajr => 'الفجر';

  @override
  String get fajrAngleLabel => 'زاوية الفجر (°)';

  @override
  String get footnote => 'الحاشية';

  @override
  String get fortressAllChapters => 'كل الأذكار';

  @override
  String get fortressBenefit => 'الفائدة';

  @override
  String get fortressShare => 'مشاركة الدعاء';

  @override
  String get fortressRepetition => 'عدد التكرار';

  @override
  String get fortressBrowseWeakHadith => 'الأحاديث الضعيفة والموضوعة';

  @override
  String get fortressCompleted => 'انتهى';

  @override
  String get fortressDhikrCopied => 'تم نسخ الذكر';

  @override
  String get fortressEmptyFavoritesHint =>
      'اضغط على أيقونة الإشارة المرجعية بجانب أي قسم لإضافته هنا';

  @override
  String get fortressEmptyFavoritesTitle => 'لا توجد أقسام مفضلة بعد';

  @override
  String get fortressEmptySearchHint => 'جرّب كلمات بحث مختلفة';

  @override
  String get fortressEmptySearchTitle => 'لا توجد نتائج للبحث';

  @override
  String get fortressFakeHadithGuide => 'دليل الأحاديث الضعيفة والموضوعة';

  @override
  String get fortressFakeHadithIntro =>
      'قائمة مرجعية من تطبيق حصن المسلم للأحاديث التي يُحذّر منها العلماء.';

  @override
  String get fortressFavorites => 'المفضلة';

  @override
  String get fortressFilterAuthenticity => 'تصفية حسب الحكم';

  @override
  String get fortressFilterChaptersHint => 'تصفية الأبواب...';

  @override
  String get fortressFinish => 'إنهاء';

  @override
  String get fortressHideDetails => 'إخفاء التفاصيل';

  @override
  String get fortressLoadError => 'تعذّر تحميل الأذكار';

  @override
  String fortressMoreFavoriteChapters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إضافةً إلى $count أبواب أخرى…',
      one: 'إضافةً إلى باب آخر…',
    );
    return '$_temp0';
  }

  @override
  String get fortressNoAdhkarInChapter => 'لا توجد أذكار في هذا الباب';

  @override
  String get fortressNoFavoriteChapters =>
      'لا توجد أبواب مفضلة بعد — أضف إشارة مرجعية من القائمة الجانبية';

  @override
  String get fortressNoRecommendations => 'لا توجد توصيات متاحة حالياً';

  @override
  String get fortressNoSearchResults => 'لم يُعثر على نتائج';

  @override
  String get fortressPrevious => 'السابق';

  @override
  String get fortressReadingHint =>
      'انقر على الذكر للعد · اسحب أفقياً للتنقل · مسافة للعد';

  @override
  String get fortressReadLong => 'قراءة مطولة';

  @override
  String get fortressReadMedium => 'قراءة متوسط';

  @override
  String get fortressReadShort => 'قراءة قصيرة';

  @override
  String get fortressRecommendedNow => 'موصى به الآن';

  @override
  String get fortressRelatedHadith => 'حديث مرتبط';

  @override
  String fortressRemainingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متبقي: $count',
      many: 'متبقي: $count',
      few: 'متبقي: $count',
      two: 'متبقيان: 2',
      one: 'متبقي: 1',
      zero: 'لا يتبقى شيء',
    );
    return '$_temp0';
  }

  @override
  String get fortressRetry => 'إعادة المحاولة';

  @override
  String get fortressSearchContents => 'الأذكار';

  @override
  String get fortressSearchHint => 'ابحث في الأذكار والأبواب...';

  @override
  String get fortressSearchOpen => 'البحث في الأذكار';

  @override
  String get fortressSearchTitles => 'الأبواب';

  @override
  String get fortressSharh => 'الشرح';

  @override
  String get fortressShowDetails => 'عرض التفاصيل';

  @override
  String get fortressShowSharh => 'عرض الشرح';

  @override
  String get fortressShowSource => 'عرض المصدر';

  @override
  String get fortressSourceReference => 'المصدر';

  @override
  String get fortressStartReading => 'بدء القراءة';

  @override
  String fortressSupplicationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ذكر',
      many: '$count ذكراً',
      few: '$count أذكار',
      two: 'ذكران',
      one: 'ذكر واحد',
      zero: 'لا أذكار',
    );
    return '$_temp0';
  }

  @override
  String fortressSupplicationsInSection(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ذكر في هذا القسم',
      many: '$count ذكراً في هذا القسم',
      few: '$count أذكار في هذا القسم',
      two: 'ذكران في هذا القسم',
      one: 'ذكر واحد في هذا القسم',
      zero: 'لا أذكار في هذا القسم',
    );
    return '$_temp0';
  }

  @override
  String get fortressVirtue => 'الفضل';

  @override
  String get fortressWeakHadithWarning => 'تنبيه: هذا الذكر ضعيف أو موضوع';

  @override
  String get fortressWelcomeSubtitle =>
      'تصفّح الأبواب من القائمة، أو ابدأ من التوصيات حسب وقتك أو المفضلة.';

  @override
  String get fortressWelcomeTitle => 'اختر باباً وابدأ الذكر';

  @override
  String get gettingLocation => 'الحصول على الموقع';

  @override
  String get goToPrayerPage => 'انتقل إلى صفحة الصلاة';

  @override
  String get graphicalAnalysis => 'الرسوم البيانية';

  @override
  String get green => 'أخضر';

  @override
  String get hadith => 'الأحاديث';

  @override
  String get hadithActiveFilters => 'مرشّحات البحث النشطة';

  @override
  String get hadithAlternateHadithSahih => 'حديث صحيح بديل';

  @override
  String get hadithAlternativeAuthentic => 'روايات صحيحة بديلة';

  @override
  String get hadithBackToSearch => 'العودة للبحث';

  @override
  String get hadithBooks => 'الكتب';

  @override
  String get hadithClearAllFilters => 'مسح جميع المرشّحات';

  @override
  String get hadithClearAllRecents => 'مسح الكل';

  @override
  String get hadithCopied => 'تم نسخ الحديث';

  @override
  String get hadithDegreeAll => 'جميع الدرجات';

  @override
  String get hadithDegreeAuthenticChain =>
      'أحاديث حكم المحدثون على أسانيدها بالصحة، ونحو ذلك';

  @override
  String get hadithDegreeAuthenticHadith =>
      'أحاديث حكم المحدثون عليها بالصحة، ونحو ذلك';

  @override
  String get hadithDegrees => 'الدرجات';

  @override
  String get hadithDegreeWeakChain =>
      'أحاديث حكم المحدثون على أسانيدها بالضعف، ونحو ذلك';

  @override
  String get hadithDegreeWeakHadith =>
      'أحاديث حكم المحدثون عليها بالضعف، ونحو ذلك';

  @override
  String get hadithDetailsTab => 'التفاصيل';

  @override
  String hadithFieldLabel(String label) {
    return '$label:';
  }

  @override
  String get hadithFilterTab => 'التصفية';

  @override
  String get hadithFoundations => 'الأصول';

  @override
  String get hadithGradeExplanation => 'شرح الحكم';

  @override
  String get hadithLoadMore => 'تحميل المزيد';

  @override
  String get hadithLoadSharh => 'تحميل الشرح';

  @override
  String hadithLoadSharhFailed(String error) {
    return 'تعذّر تحميل الشرح: $error';
  }

  @override
  String get hadithMuhaddith => 'المحدث';

  @override
  String get hadithNarrator => 'الراوي';

  @override
  String get hadithNarrators => 'الرواة';

  @override
  String get hadithNoBookmarks => 'لا توجد أحاديث محفوظة';

  @override
  String get hadithNoDetailedData => 'لا توجد بيانات تفصيلية لهذا الحديث';

  @override
  String get hadithNoDetailsSelected => 'اختر حديثًا من النتائج لعرض التفاصيل';

  @override
  String get hadithNoMatchingResults => 'لا توجد نتائج مطابقة';

  @override
  String get hadithNoRecentSearches => 'لا توجد عمليات بحث حديثة';

  @override
  String get hadithOpenFilters => 'التصفية';

  @override
  String get hadithPageLoadFailed =>
      'تعذر تحميل هذه الصفحة. يتم عرض النتائج السابقة.';

  @override
  String get hadithRecentSearches => 'عمليات البحث الأخيرة';

  @override
  String get hadithRelatedLinks => 'روابط ذات صلة';

  @override
  String get hadithResetFilters => 'إعادة ضبط الفلاتر';

  @override
  String hadithResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتائج',
      many: '$count نتيجة',
      few: '$count نتائج',
      two: 'نتيجتان',
      one: 'نتيجة واحدة',
      zero: 'لا نتائج',
    );
    return '$_temp0';
  }

  @override
  String get hadithRetry => 'إعادة المحاولة';

  @override
  String get hadithScholars => 'المحدث';

  @override
  String get hadithScope => 'نطاق البحث';

  @override
  String get hadithSearchAction => 'بحث';

  @override
  String get hadithSearchHint => 'ابحث في الدرر السنية...';

  @override
  String get hadithSearchMethod => 'طريقة البحث';

  @override
  String get hadithSearchMethodAllWords => 'جميع الكلمات';

  @override
  String get hadithSearchMethodAnyWord => 'أي كلمة';

  @override
  String get hadithSearchMethodExactMatch => 'بحث مطابق';

  @override
  String get hadithSearchZoneAll => 'جميع الأحاديث';

  @override
  String get hadithSearchZoneMarfoo => 'الأحاديث المرفوعة';

  @override
  String get hadithSearchZoneQudsi => 'الأحاديث القدسية';

  @override
  String get hadithSearchZoneSahabaAthar => 'آثار الصحابة';

  @override
  String get hadithSearchZoneSharh => 'شروح الأحاديث';

  @override
  String get hadithSharh => 'الشرح';

  @override
  String get hadithShare => 'مشاركة الحديث';

  @override
  String get hadithNumberOrPage => 'الرقم أو الصفحة';

  @override
  String get hadithSimilar => 'أحاديث مشابهة';

  @override
  String get hadithSimilarHadith => 'أحاديث مشابهة';

  @override
  String get hadithSource => 'المصدر';

  @override
  String hadithSourceCitation(String book, String reference) {
    return '$book ($reference)';
  }

  @override
  String get hadithSpecialist => 'تخريج';

  @override
  String get hadithSpecialistHint =>
      'إرجاع الأحاديث التي تتضمّن التخريج في بياناتها فقط';

  @override
  String get hadithStartSearchPrompt => 'اضغط Enter أو بحث لعرض النتائج';

  @override
  String get hadithTakhrij => 'التخريج';

  @override
  String get hadithTypeToSearch => 'اكتب للبحث...';

  @override
  String get hadithUsulHadith => 'أصول الحديث';

  @override
  String get highLatitudeRule_middleOfTheNight => 'منتصف الليل';

  @override
  String get highLatitudeRule_seventhOfTheNight => 'سبع الليل';

  @override
  String get highLatitudeRule_twilightAngle => 'زاوية الشفق';

  @override
  String get highLatitudeRuleLabel => 'قاعدة خطوط العرض العالية';

  @override
  String hizbLabel(int number) {
    return 'الحزب $number';
  }

  @override
  String get integerPlaceholder => '٠';

  @override
  String get invalidCoordinatesDescription =>
      'يرجى إدخال قيم صحيحة لخط العرض وخط الطول.';

  @override
  String get invalidCoordinatesTitle => 'إحداثيات غير صالحة';

  @override
  String get invalidParametersDescription => 'يرجى التحقق من القيم المدخلة.';

  @override
  String get invalidParametersTitle => 'إعدادات غير صالحة';

  @override
  String invalidParametersWithError(String message, String error) {
    return '$message $error';
  }

  @override
  String get iqamah => 'الإقامة';

  @override
  String get iqamahAdjustment => 'ضبط الإقامة';

  @override
  String get iqamahAfterAdhan => 'الإقامة (دقائق بعد الأذان)';

  @override
  String iqamahAlertTitle(String prayer) {
    return 'الإقامة — $prayer';
  }

  @override
  String get iqamahMuezzinMadinah => 'المدينة المنورة';

  @override
  String get iqamahMuezzinYasserAlDossari => 'ياسر الدوسري';

  @override
  String get iqamahOsNotificationBody => 'حان وقت الإقامة.';

  @override
  String iqamahPlayingTitle(String prayer) {
    return 'الإقامة — $prayer';
  }

  @override
  String get iqamahSavedDescription => 'حُفظت تعديلات الإقامة بنجاح.';

  @override
  String iqamahSavedForPrayer(String prayer) {
    return 'حُفظ ضبط الإقامة لصلاة $prayer.';
  }

  @override
  String get iqamahSavedTitle => 'حُفظت إعدادات الإقامة';

  @override
  String get iqamahSoundLabel => 'نداء الإقامة';

  @override
  String iqamahSubtitleMessage(int iqamahMins) {
    String _temp0 = intl.Intl.pluralLogic(
      iqamahMins,
      locale: localeName,
      other: '+$iqamahMins دقيقة',
      many: '+$iqamahMins دقيقة',
      few: '+$iqamahMins دقائق',
      two: '+ دقيقتين',
      one: '+ دقيقة',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String get isha => 'العشاء';

  @override
  String get ishaAngleLabel => 'زاوية العشاء (°)';

  @override
  String get ishaIntervalLabel => 'فاصل العشاء (دقيقة)';

  @override
  String get islamicTheme => 'المخطوطة';

  @override
  String get jamaah => 'جماعة';

  @override
  String get jamaahRate => 'نسبة الجماعة';

  @override
  String get jumuah => 'الجمعة';

  @override
  String juzLabel(int number) {
    return 'الجزء $number';
  }

  @override
  String get karachi => 'جامعة العلوم الإسلامية، كراتشي';

  @override
  String get keyboardShortcutsCategorySubtitle =>
      'متاحة عند استخدام التطبيق على سطح المكتب.';

  @override
  String get keyboardShortcutsSectionSubtitle =>
      'قائمة مرجعية للاختصارات المتاحة على سطح المكتب. تعمل الاختصارات في كل الشاشات بما فيها هذه. لا يمكن تخصيصها.';

  @override
  String get keyboardShortcutsSectionTitle => 'اختصارات لوحة المفاتيح';

  @override
  String get keyboardShortcutsTabTitle => 'الإختصارات';

  @override
  String get kuwait => 'الكويت';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get lastThirdOfTheNight => 'الثلث الأخير من الليل';

  @override
  String get late => 'متأخر';

  @override
  String get lateRate => 'نسبة التأخير';

  @override
  String get latitude => 'خط العرض';

  @override
  String get light => 'فاتح';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get loadingAnalytics => 'جارٍ تحميل التحليلات';

  @override
  String get loadingLocationSettings => 'جارٍ تحميل إعدادات الموقع';

  @override
  String get loadingSchedule => 'جارٍ تحميل الجدول';

  @override
  String get locationCoordinatesLookupFailed =>
      'تعذّر تحديد المنطقة الزمنية من الإحداثيات.';

  @override
  String locationNoPlaceFound(String coordinates) {
    return 'لم يُعثر على مكان عند $coordinates.';
  }

  @override
  String get locationPermissionDenied => 'تم رفض إذن الموقع.';

  @override
  String get locationPermissionDeniedForever =>
      'إذن الموقع مرفوض بشكل دائم. فعّله من إعدادات النظام.';

  @override
  String get locationSectionSubtitle =>
      'حدد موقعك الجغرافي والمنطقة الزمنية لأوقات صلاة دقيقة.';

  @override
  String get locationSectionTitle => 'الموقع';

  @override
  String get locationServicesDisabled => 'خدمات الموقع معطّلة.';

  @override
  String get lockToPreventEdits => 'اقفل لمنع التعديل';

  @override
  String get logPrayerStatus => 'تسجيل حالة الصلاة';

  @override
  String get longitude => 'خط الطول';

  @override
  String get madhab_hanafi => 'حنفي';

  @override
  String get madhab_shafi => 'شافعي';

  @override
  String get madhabLabel => 'المذهب';

  @override
  String get maghrib => 'المغرب';

  @override
  String get maghribAngleLabel => 'زاوية المغرب (°)';

  @override
  String get mediaSessionAppName => 'تَوَّاق';

  @override
  String mediaSessionAudioBy(String source) {
    return 'صوت بواسطة $source';
  }

  @override
  String get menuAddBookmark => 'إضافة إشارة مرجعية';

  @override
  String get menuAddFavorite => 'إضافة إلى المفضلة';

  @override
  String get menuCopyText => 'نسخ النص';

  @override
  String get menuOpen => 'فتح';

  @override
  String get menuRemoveBookmark => 'إزالة الإشارة المرجعية';

  @override
  String get menuRemoveFavorite => 'إزالة من المفضلة';

  @override
  String get midnight => 'منتصف الليل';

  @override
  String get minute => 'دقيقة';

  @override
  String get missed => 'فائتة';

  @override
  String get missedRate => 'نسبة الفوائت';

  @override
  String get monthly => 'شهري';

  @override
  String get moonsightingCommittee => 'لجنة رؤية الهلال';

  @override
  String get morocco => 'المغرب';

  @override
  String get muslimFortress => 'حصن المسلم';

  @override
  String get muslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get neutral => 'محايد';

  @override
  String get next => 'التالي';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get noDataAvailable => 'لا توجد بيانات';

  @override
  String get noReflectionsMatchSearch => 'لا توجد خواطر تطابق بحثك';

  @override
  String get noReflectionsYet => 'لا خواطر بعد — اكتب خاطرة على آية لتظهر هنا';

  @override
  String get noResults => 'لا توجد نتائج.';

  @override
  String get noResultsFound => 'لا توجد نتائج';

  @override
  String get northAmerica => 'أمريكا الشمالية (ISNA)';

  @override
  String get noTafsirAvailable => 'لا يوجد تفسير متاح لهذه الآية';

  @override
  String noteTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوماً',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String noteTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count شهراً',
      few: 'منذ $count أشهر',
      two: 'منذ شهرين',
      one: 'الشهر الماضي',
    );
    return '$_temp0';
  }

  @override
  String get noteTimeToday => 'اليوم';

  @override
  String noteTimeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count أسبوعاً',
      few: 'منذ $count أسابيع',
      two: 'منذ أسبوعين',
      one: 'منذ أسبوع',
    );
    return '$_temp0';
  }

  @override
  String noteTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count عاماً',
      few: 'منذ $count أعوام',
      two: 'منذ عامين',
      one: 'العام الماضي',
    );
    return '$_temp0';
  }

  @override
  String get noteTimeYesterday => 'أمس';

  @override
  String get noTranslationAvailable => 'لا توجد ترجمة متاحة لهذه الآية';

  @override
  String get nowActive => 'نشط الآن';

  @override
  String get onboardingFinishAction => 'ابدأ';

  @override
  String get onboardingFinishPreviewUnavailable =>
      'حدّد موقعك لمعاينة مواقيت اليوم.';

  @override
  String get onboardingFinishSubtitle =>
      'مواقيت صلاتك جاهزة. يمكنك تعديل أي إعداد لاحقًا من الإعدادات.';

  @override
  String get onboardingFinishTitle => 'كل شيء جاهز';

  @override
  String get onboardingLanguageArabic => 'العربية';

  @override
  String get onboardingLanguageArabicSubtitle =>
      'واجهة عربية مع تخطيط من اليمين لليسار';

  @override
  String get onboardingLanguageEnglish => 'English';

  @override
  String get onboardingLanguageEnglishSubtitle =>
      'واجهة إنجليزية مع تخطيط من اليسار لليمين';

  @override
  String get onboardingLanguageStepHint =>
      'اختر اللغة التي تفضّلها للقوائم والعناوين.';

  @override
  String get onboardingLocationTipSubtitle =>
      'نستخدم مدينتك فقط لحساب مواقيت الصلاة بدقة. يُخزَّن موقعك على هذا الجهاز.';

  @override
  String get onboardingLocationTipTitle => 'لماذا نحتاج موقعك';

  @override
  String get onboardingOpenSetupAction => 'فتح الإعداد';

  @override
  String get onboardingRerunSubtitle =>
      'أعد خطوات اللغة والموقع ومواقيت الصلاة والتنبيهات.';

  @override
  String get onboardingRerunTitle => 'إعادة الإعداد';

  @override
  String get onboardingSetUpLater => 'الإعداد لاحقًا';

  @override
  String get onboardingStepFinish => 'جاهز للبدء';

  @override
  String onboardingStepFinishSubtitle(String appName) {
    return 'راجع جدول اليوم وابدأ استخدام $appName.';
  }

  @override
  String get onboardingStepIqamah => 'فواصل الإقامة';

  @override
  String get onboardingStepIqamahSubtitle =>
      'الدقائق بعد الأذان حتى الإقامة لكل صلاة.';

  @override
  String get onboardingStepLanguage => 'اللغة';

  @override
  String get onboardingStepLanguageSubtitle => 'اختر كيف تريد استخدام التطبيق.';

  @override
  String get onboardingStepLocation => 'موقعك';

  @override
  String get onboardingStepLocationSubtitle =>
      'حدّد مدينتك لتطابق مواقيت الصلاة مكانك.';

  @override
  String get onboardingStepNotifications => 'التنبيهات';

  @override
  String get onboardingStepNotificationsSubtitle =>
      'اختر صوت الأذان وكيفية ظهور التنبيهات.';

  @override
  String get onboardingStepPrayerTimes => 'مواقيت الصلاة';

  @override
  String get onboardingStepPrayerTimesSubtitle => 'طريقة الحساب وتنسيق الوقت.';

  @override
  String get onboardingStepTheme => 'المظهر';

  @override
  String get onboardingStepThemeSubtitle => 'لوحة الألوان وحجم نص الواجهة.';

  @override
  String get onboardingStepWelcome => 'مرحبًا';

  @override
  String onboardingStepWelcomeSubtitle(String appName) {
    return 'إعداد سريع لتخصيص $appName لك.';
  }

  @override
  String get onboardingWelcomeSubtitle =>
      'سنساعدك على ضبط مواقيت الصلاة والتنبيهات والمظهر في خطوات موجّهة.';

  @override
  String get onboardingWelcomeTipSubtitle =>
      'يمكنك مراجعة أي من هذه الخيارات لاحقًا من الإعدادات.';

  @override
  String get onboardingWelcomeTipTitle => 'خذ وقتك';

  @override
  String onboardingWelcomeTitle(String appName) {
    return 'مرحبًا بك في $appName';
  }

  @override
  String get onTime => 'في وقتها';

  @override
  String get onTimePrayersLast30Days => 'الصلاة المنتظمة (لآخر 30 يومًا)';

  @override
  String get onTimePrayersLast365Days => 'الصلاة المنتظمة (لآخر 365 يومًا)';

  @override
  String get onTimePrayersLast7Days => 'الصلاة المنتظمة (لآخر 7 أيام)';

  @override
  String get onTimePrayersToday => 'الصلاة المنتظمة (اليوم)';

  @override
  String get onTimeRate => 'نسبة الانتظام';

  @override
  String get openFolder => 'فتح المجلد';

  @override
  String get openFolderFailed => 'تعذر فتح المجلد';

  @override
  String get optionalHint => 'اختياري';

  @override
  String get or => 'أو';

  @override
  String get orange => 'برتقالي';

  @override
  String get other => 'أخرى';

  @override
  String pageJuzInfo(int page, int juz) {
    return 'صفحة $page • الجزء $juz';
  }

  @override
  String pageLabel(int page) {
    return 'صفحة $page';
  }

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get pageNotFoundDescription =>
      'هذه الصفحة غير موجودة. يرجى العودة إلى الصفحة الرئيسية.';

  @override
  String get parametersSavedDescription => 'حُفظت إعداداتك المخصصة بنجاح.';

  @override
  String get parametersSavedTitle => 'حُفظت الإعدادات';

  @override
  String get performanceIndicator => 'مؤشر الأداء';

  @override
  String get placeholdersHint =>
      'يمكن ضبط المذهب والخيارات الأخرى لاحقًا. هذه المدخلات مؤقتة.';

  @override
  String get playerAnalytics => 'إحصاءات الصلاة';

  @override
  String get pleaseSelectMethod => 'يرجى اختيار طريقة الحساب.';

  @override
  String get prayer => 'الصلاة';

  @override
  String get prayerAlertDismiss => 'إغلاق';

  @override
  String get prayerLocationRequiredAction => 'فتح إعدادات الموقع';

  @override
  String get prayerLocationRequiredSubtitle =>
      'تحتاج أوقات الصلاة إلى إحداثيات موقعك. افتح إعدادات الموقع لاختيار مدينة على الخريطة أو إدخال الإحداثيات يدويًا.';

  @override
  String get prayerLocationRequiredTitle => 'حدّد موقعك';

  @override
  String get prayerSettingsSubtitle => 'إعدادات الصلاة ومواقيتها ومتابعتها.';

  @override
  String get prayerSettingsTitle => 'إعدادات الصلاة';

  @override
  String get prayerTimeAdjustmentsTitle => 'تعديلات مواقيت الصلاة (بالدقائق)';

  @override
  String get prayerTimes => 'مواقيت الصلاة';

  @override
  String get prayerTrackerSubtitle =>
      'تتبع صلواتك وحافظ على انتظامك، انقر على صلاة لتسجيلها كمكتملة.';

  @override
  String get prayerTrackerTitle => 'متابعة الصلاة';

  @override
  String get prepareForPrayer => 'تجهز للصلاة.';

  @override
  String get qatar => 'قطر';

  @override
  String get quran => 'القرآن الكريم';

  @override
  String quranAyahSearchPreviewTruncated(String preview) {
    return '$preview...';
  }

  @override
  String get quranDoublePageWidthFallback =>
      'العرض غير كافٍ لصفحتين — يُعرض صفحة واحدة.';

  @override
  String get quranLayoutDoublePage => 'صفحتان';

  @override
  String get quranLayoutStudyMode => 'وضع الدراسة';

  @override
  String get quranNoMatchingReciters => 'لا يوجد قراء مطابقون';

  @override
  String get quranPlayAyah => 'تشغيل هذه الآية';

  @override
  String get quranPlayRange => 'تشغيل مقطع…';

  @override
  String get quranPlaySelection => 'تشغيل المحدد';

  @override
  String get quranPlaySurah => 'تشغيل هذه السورة';

  @override
  String get quranRangeChooseSyncedReciter => 'اختر قارئًا متزامنًا';

  @override
  String get quranRangeFirstAyah => 'الآية الأولى';

  @override
  String get quranRangeFrom => 'من — السورة والآية';

  @override
  String get quranRangeFromAyah => 'من — الآية';

  @override
  String get quranRangeFromShort => 'من';

  @override
  String get quranRangeFromSurah => 'من — السورة';

  @override
  String get quranRangeHizbBoundsNotFound => 'تعذّر تحميل حدود الحزب';

  @override
  String get quranRangeHizbNotFound => 'تعذّر تحديد الحزب لهذه الآية';

  @override
  String get quranRangeJuzBoundsNotFound => 'تعذّر تحميل حدود الجزء';

  @override
  String get quranRangeJuzNotFound => 'تعذّر تحديد الجزء لهذه الآية';

  @override
  String get quranRangeLastAyah => 'الآية الأخيرة';

  @override
  String get quranRangeModeLabel => 'نهاية التشغيل';

  @override
  String get quranRangePlay => 'تشغيل المقطع';

  @override
  String get quranRangePresetAyah => 'هذه الآية';

  @override
  String get quranRangePresetContinueFromHere => 'استمر من هنا';

  @override
  String get quranRangePresetCustom => 'مخصص';

  @override
  String get quranRangePresetFailed => 'تعذّر تطبيق هذا الاختيار للمدى';

  @override
  String get quranRangePresetHizb => 'هذا الحزب';

  @override
  String get quranRangePresetJuz => 'هذا الجزء';

  @override
  String get quranRangePresetSurah => 'هذه السورة';

  @override
  String quranRangeRepeatChip(int count) {
    return '×$count';
  }

  @override
  String get quranRangeRepeatEachAyah => 'كرّر كل آية';

  @override
  String get quranRangeRepeatOnce => 'مرة واحدة';

  @override
  String get quranRangeRepeatSelection => 'كرّر المدى';

  @override
  String quranRangeRepeatTimes(int count) {
    return '$count مرات';
  }

  @override
  String get quranRangeRepeatTwice => 'مرتان';

  @override
  String get quranRangeRequiresTimedReciter =>
      'اختر قارئًا متزامنًا لتشغيل مدى الآيات هذا';

  @override
  String get quranRangeSave => 'حفظ المدى';

  @override
  String get quranRangeScope => 'المدى';

  @override
  String get quranRangeTitle => 'المدى والتكرار للحفظ';

  @override
  String get quranRangeTo => 'إلى — السورة والآية';

  @override
  String get quranRangeToAyah => 'إلى — الآية';

  @override
  String get quranRangeToShort => 'إلى';

  @override
  String get quranRangeToSurah => 'إلى — السورة';

  @override
  String get quranRecitationApply => 'تطبيق';

  @override
  String get quranRecitationAutoScroll => 'متابعة التلاوة';

  @override
  String get quranRecitationAutoScrollDesc =>
      'يُحرّك صفحة المصحف تلقائيًا لتتبّع موضع التلاوة.';

  @override
  String get quranRecitationCancel => 'إلغاء';

  @override
  String get quranRecitationClosePlayer => 'إغلاق المشغّل';

  @override
  String get quranRecitationComingSoon => 'تشغيل التلاوة قريباً';

  @override
  String get quranRecitationDownloading => 'جارٍ التخزين…';

  @override
  String get quranRecitationInitializationFailed =>
      'تعذّر تحميل التلاوة المحفوظة';

  @override
  String get quranRecitationRetryInitialization => 'إعادة المحاولة';

  @override
  String get quranRecitationEnded => 'انتهى';

  @override
  String get quranRecitationGoToQuran => 'الانتقال إلى القرآن';

  @override
  String get quranRecitationHighlight => 'تظليل الآية';

  @override
  String get quranRecitationHighlightAutoDisabled =>
      'تم إيقاف التظليل والتمرير التلقائي لهذه الرواية';

  @override
  String get quranRecitationHighlightAutoEnabled =>
      'تم تفعيل التظليل والتمرير التلقائي لهذه الرواية';

  @override
  String get quranRecitationHighlightDesc =>
      'يُظلّل الآية الجاري تشغيلها في المصحف.';

  @override
  String get quranRecitationHighlightNonHafsWarning =>
      'قد لا يكون تظليل الآيات دقيقاً لهذه الرواية.';

  @override
  String get quranRecitationNext => 'التالي';

  @override
  String get quranRecitationNextAyah => 'الآية التالية';

  @override
  String get quranRecitationNextSurah => 'السورة التالية';

  @override
  String get quranRecitationNoTiming =>
      'تشغيل الآيات منفردة غير متاح لهذا القارئ';

  @override
  String get quranRecitationOfflineAutoSave => 'الحفظ أثناء الاستماع';

  @override
  String get quranRecitationOfflineAutoSaveOffHint =>
      'يمكنك الاستماع عبر الإنترنت. استخدم «حفظ دون اتصال» للسورة الحالية.';

  @override
  String get quranRecitationOfflineAutoSaveOnHint =>
      'تُحفظ التلاوات تلقائيًا أثناء الاستماع.';

  @override
  String get quranRecitationOfflineClearSelection => 'إلغاء التحديد';

  @override
  String get quranRecitationOfflineDelete => 'حذف التلاوات';

  @override
  String get quranRecitationOfflineDeleteAll => 'حذف جميع التلاوات';

  @override
  String quranRecitationOfflineDeleteConfirm(int count, String size) {
    return 'هل تريد حذف $count من التلاوات ($size)؟ لا يمكن التراجع عن ذلك.';
  }

  @override
  String quranRecitationOfflineDeleteFailed(int count) {
    return 'تعذر حذف $count من التلاوات. ستبقى محددة لإعادة المحاولة.';
  }

  @override
  String get quranRecitationOfflineDeleteSelected => 'حذف المحدد';

  @override
  String get quranRecitationOfflineDeleteTitle => 'حذف التلاوات؟';

  @override
  String get quranRecitationOfflineEmpty => 'لا توجد تلاوات محفوظة بعد.';

  @override
  String quranRecitationOfflineFileCount(int count) {
    return '$count ملفات';
  }

  @override
  String get quranRecitationOfflineFiles => 'التلاوات المحفوظة';

  @override
  String get quranRecitationOfflineInFolder => 'في هذا المجلد';

  @override
  String get quranRecitationOfflineOpenFolder => 'فتح المجلد';

  @override
  String get quranRecitationOfflinePlaybackStops =>
      'سيتوقف التشغيل قبل إزالة الملف.';

  @override
  String get quranRecitationOfflineReciter => 'القارئ';

  @override
  String get quranRecitationOfflineRiwayah => 'الرواية';

  @override
  String get quranRecitationOfflineSelectAll => 'تحديد الكل';

  @override
  String quranRecitationOfflineSelected(int count) {
    return '$count محدد';
  }

  @override
  String get quranRecitationOfflineSize => 'الحجم';

  @override
  String get quranRecitationOfflineStorageUsed => 'التخزين المستخدم';

  @override
  String get quranRecitationOfflineSurah => 'السورة';

  @override
  String get quranRecitationOfflineSubtitle => 'التلاوات المحفوظة';

  @override
  String get quranRecitationOpenPlayer => 'فتح المشغّل';

  @override
  String get quranRecitationPause => 'إيقاف مؤقت';

  @override
  String get quranRecitationPlay => 'تشغيل';

  @override
  String quranRecitationPlaybackFailed(String error) {
    return 'فشل التشغيل: $error';
  }

  @override
  String get quranRecitationPrevious => 'السابق';

  @override
  String get quranRecitationPreviousAyah => 'الآية السابقة';

  @override
  String get quranRecitationPreviousSurah => 'السورة السابقة';

  @override
  String get quranRecitationRangeRepeat => 'المدى والتكرار';

  @override
  String quranRecitationPlaysRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining تشغيلات متبقية',
      two: 'تشغيلان متبقيان',
      one: 'تشغيل واحد متبقٍ',
    );
    return '$_temp0';
  }

  @override
  String quranRecitationRepeatProgress(int current, int total) {
    return '$current من $total';
  }

  @override
  String get quranRecitationRepeatScopeEachAyah => 'تكرار كل آية';

  @override
  String get quranRecitationRepeatScopeSelection => 'تكرار المقطع';

  @override
  String get quranRecitationSeekBarLabel => 'موضع التلاوة';

  @override
  String get quranRecitationSavedOffline => 'محفوظ دون اتصال';

  @override
  String get quranRecitationSaveOffline => 'حفظ دون اتصال';

  @override
  String get quranRecitationSavingOffline => 'جارٍ الحفظ…';

  @override
  String quranRecitationSelectionLoopProgress(int current, int total) {
    return 'تكرار $current من $total';
  }

  @override
  String quranRecitationSleepAfter(String minutes) {
    return 'بعد $minutes دقيقة';
  }

  @override
  String get quranRecitationSleepEndOfAyah => 'نهاية الآية الحالية';

  @override
  String get quranRecitationSleepEndOfRange => 'نهاية المدى';

  @override
  String get quranRecitationSleepEndOfSurah => 'نهاية السورة';

  @override
  String get quranRecitationSleepOff => 'إيقاف';

  @override
  String get quranRecitationSleepTimer => 'مؤقّت النوم';

  @override
  String get quranRecitationStop => 'إيقاف';

  @override
  String get quranRecitationSwitchReciter => 'تبديل القارئ';

  @override
  String get quranRecitationUnavailable => 'لا يوجد قارئ متاح للتشغيل';

  @override
  String get quranRecitationVolume => 'مستوى الصوت';

  @override
  String get quranReciterFilterDownloaded => 'المحفوظة';

  @override
  String get quranReciterFilters => 'تصفية';

  @override
  String quranReciterRiwayahCount(int count) {
    return '$count روايات';
  }

  @override
  String get quranReciterRiwayahTitle => 'القارئ والرواية';

  @override
  String quranReciterRiwayahUpgraded(String riwayah) {
    return 'هذه الرواية لا تدعم تتبع الآيات. تم التبديل إلى $riwayah.';
  }

  @override
  String get quranReciterSearchHint => 'ابحث عن قارئ…';

  @override
  String get quranReciterStyleMujawwad => 'مجوّد';

  @override
  String get quranReciterStyleMurattal => 'مرتل';

  @override
  String get quranReciterSurahOnly => 'تشغيل السورة فقط';

  @override
  String get quranReciterTimed => 'متزامن';

  @override
  String get quranSelectReciter => 'اختر القارئ';

  @override
  String quranSurahLabel(String surah) {
    return 'سورة $surah';
  }

  @override
  String get quranTextSize => 'حجم نص القرآن';

  @override
  String get quranTextSizeIndependentNote =>
      'حجم قراءة القرآن مستقل عن تحجيم التطبيق والنظام.';

  @override
  String get quranTextSizePreview => 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  @override
  String get quranTextSizePreviewLabel => 'معاينة';

  @override
  String quranTranslationQuoted(String translation) {
    return '\"$translation\"';
  }

  @override
  String get quranZoomFillWidth => 'ملء';

  @override
  String get quranZoomFillWidthHint =>
      'بعد الملاءمة قد تحتاج الصفحة إلى التمرير عمودياً لتكبير أكبر.';

  @override
  String get quranZoomFitPage => 'ملاءمة';

  @override
  String quranZoomPercent(int percent) {
    return '$percent٪';
  }

  @override
  String get quranZoomReset => 'إعادة إلى الملاءمة';

  @override
  String get red => 'أحمر';

  @override
  String get reflectionPlaceholder => 'اكتب خاطرتك حول هذه الآية...';

  @override
  String reflectionsSummary(int noteCount, int surahCount) {
    String _temp0 = intl.Intl.pluralLogic(
      surahCount,
      locale: localeName,
      other: '$surahCount سورة',
      many: '$surahCount سورة',
      few: '$surahCount سور',
      two: 'سورتين',
      one: 'سورة واحدة',
    );
    String _temp1 = intl.Intl.pluralLogic(
      surahCount,
      locale: localeName,
      other: '$surahCount سورة',
      many: '$surahCount سورة',
      few: '$surahCount سور',
      two: 'سورتين',
      one: 'سورة واحدة',
    );
    String _temp2 = intl.Intl.pluralLogic(
      surahCount,
      locale: localeName,
      other: '$surahCount سورة',
      many: '$surahCount سورة',
      few: '$surahCount سور',
      two: 'سورتين',
      one: 'سورة واحدة',
    );
    String _temp3 = intl.Intl.pluralLogic(
      surahCount,
      locale: localeName,
      other: '$surahCount سورة',
      many: '$surahCount سورة',
      few: '$surahCount سور',
      two: 'سورتين',
      one: 'سورة واحدة',
    );
    String _temp4 = intl.Intl.pluralLogic(
      surahCount,
      locale: localeName,
      other: '$surahCount سورة',
      many: '$surahCount سورة',
      few: '$surahCount سور',
      two: 'سورتين',
      one: 'سورة واحدة',
    );
    String _temp5 = intl.Intl.pluralLogic(
      noteCount,
      locale: localeName,
      other: '$noteCount خاطرة في $_temp0',
      many: '$noteCount خاطرة في $_temp1',
      few: '$noteCount خواطر في $_temp2',
      two: 'خاطرتان في $_temp3',
      one: 'خاطرة واحدة في $_temp4',
      zero: 'لا خواطر',
    );
    return '$_temp5';
  }

  @override
  String get remembrance => 'الأذكار';

  @override
  String get resetCompleteDescription =>
      'أُعيدت الإعدادات إلى القيم الافتراضية.';

  @override
  String get resetCompleteTitle => 'أُعيد ضبط الإعدادات';

  @override
  String get resetToDefaults => 'إعادة الضبط للوضع الافتراضي';

  @override
  String get rose => 'وردي';

  @override
  String get save => 'حفظ';

  @override
  String get saveParameters => 'حفظ الإعدادات';

  @override
  String scheduleAlertEventAdhan(String prayer) {
    return 'أذان $prayer';
  }

  @override
  String scheduleAlertEventIqamah(String prayer) {
    return 'إقامة $prayer';
  }

  @override
  String scheduleAlertEventSunnah(String prayer) {
    return '$prayer';
  }

  @override
  String get scheduleAlertIqamahSound => 'صوت';

  @override
  String get scheduleAlertIqamahSoundHint => 'تشغيل التنبيه عند حلول الوقت';

  @override
  String get scheduleAlertNotify => 'تنبيه';

  @override
  String get scheduleAlertNotifyHint => 'إشعار بدون صوت';

  @override
  String get scheduleAlertOff => 'صامت';

  @override
  String get scheduleAlertOffHint => 'بدون تنبيه لهذا الوقت';

  @override
  String scheduleAlertPickerTitle(String event) {
    return 'تنبيه $event';
  }

  @override
  String get scheduleAlertSound => 'أذان';

  @override
  String get scheduleAlertSoundHint => 'تشغيل الأذان عند حلول الوقت';

  @override
  String get scrollMoreHint => 'المزيد بالأسفل';

  @override
  String get searchForMore => 'ابحث للمزيد من الخيارات';

  @override
  String get searchingPlace => 'البحث عن موقع';

  @override
  String get searchPlaceAction => 'بحث';

  @override
  String get searchPlaceLabel => 'البحث عن موقع';

  @override
  String get searchPlaceQueryHint => 'مدينة أو منطقة أو عنوان';

  @override
  String get searchPlaceSubmitHint => 'اضغط Enter أو زر البحث';

  @override
  String get searchQuran => 'ابحث في القرآن...';

  @override
  String get searchYourReflections => 'ابحث في خواطرك';

  @override
  String get selectAyahToSeeContent => 'اختر آية لعرض المحتوى.';

  @override
  String get selectVerseToAddReflection => 'يرجى اختيار آية لإضافة خاطرة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get setupPrayerSettingsSubtitle =>
      'سنرشدك عبر خطوات سريعة. يمكنك تغيير هذه لاحقًا من الإعدادات.';

  @override
  String get setupPrayerSettingsTitle => 'لنضبط إعدادات الصلاة';

  @override
  String get setupPreferences => 'لنقم بضبط تفضيلاتك.';

  @override
  String get shareAppName => 'اسم التطبيق';

  @override
  String get shareAttributionPrefix => 'بإستخدام';

  @override
  String get shareBasmalah => 'البسملة';

  @override
  String shareByApp(String appName) {
    return 'بإستخدام $appName';
  }

  @override
  String get shareClipboardInstallHint =>
      'ثبّت wl-clipboard (Wayland) أو xclip (X11) لنسخ الصور';

  @override
  String get shareCopyImage => 'نسخ الصورة';

  @override
  String get shareCouldNotCreateImage => 'تعذر إنشاء الصورة';

  @override
  String shareExportFailed(String error) {
    return 'فشل التصدير: $error';
  }

  @override
  String shareFailedToLoadPage(String error) {
    return 'فشل تحميل الصفحة: $error';
  }

  @override
  String get shareImageCopied => 'تم نسخ الصورة إلى الحافظة';

  @override
  String shareImageCopyFailed(String error) {
    return 'تعذر نسخ الصورة: $error';
  }

  @override
  String get shareImageSavedTitle => 'تم حفظ الصورة';

  @override
  String get shareIncludeInImage => 'تضمين في الصورة';

  @override
  String get sharePreserveLineBreaks => 'فواصل أسطر المصحف';

  @override
  String get sharePreview => 'معاينة';

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
    return 'النطاق في الصفحة $page';
  }

  @override
  String shareRangeSingleDescription(String reference, String verseCount) {
    return '$reference ($verseCount)';
  }

  @override
  String get shareSaveImage => 'حفظ الصورة';

  @override
  String get shareSurahHeader => 'رأس السورة';

  @override
  String shareVerseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count آية',
      many: '$count آية',
      few: '$count آيات',
      two: 'آيتان',
      one: 'آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String get shareVerses => 'مشاركة الآيات';

  @override
  String get shortcutCategoryFortress => 'حصن المسلم';

  @override
  String get shortcutCategoryGlobal => 'عام';

  @override
  String get shortcutCategoryHadith => 'الأحاديث';

  @override
  String get shortcutCategoryQuran => 'القرآن';

  @override
  String get shortcutFocusSearchDescription =>
      'فتح أو التركيز على حقل البحث في القرآن والحديث وحصن المسلم.';

  @override
  String get shortcutFocusSearchLabel => 'التركيز على البحث';

  @override
  String get shortcutFocusSearchUnavailable => 'البحث غير متاح في هذه الشاشة.';

  @override
  String get shortcutFortressCountDescription =>
      'تقليل عداد التكرار أثناء القراءة المركّزة.';

  @override
  String get shortcutFortressCountLabel => 'عدّ الذكر';

  @override
  String get shortcutFortressThikrNextDescription =>
      'الانتقال إلى الذكر التالي أثناء القراءة المركّزة.';

  @override
  String get shortcutFortressThikrNextLabel => 'الذكر التالي';

  @override
  String get shortcutFortressThikrPrevDescription =>
      'العودة إلى الذكر السابق أثناء القراءة المركّزة.';

  @override
  String get shortcutFortressThikrPrevLabel => 'الذكر السابق';

  @override
  String get shortcutHadithResultNextDescription =>
      'اختيار الحديث التالي في قائمة النتائج.';

  @override
  String get shortcutHadithResultNextLabel => 'الحديث التالي';

  @override
  String get shortcutHadithResultPrevDescription =>
      'اختيار الحديث السابق في قائمة النتائج.';

  @override
  String get shortcutHadithResultPrevLabel => 'الحديث السابق';

  @override
  String get shortcutOpenSettingsDescription => 'الانتقال إلى شاشة الإعدادات.';

  @override
  String get shortcutOpenSettingsLabel => 'فتح الإعدادات';

  @override
  String get shortcutQuranAyahNextDescription =>
      'اختيار الآية التالية في وضع الدراسة.';

  @override
  String get shortcutQuranAyahNextLabel => 'الآية التالية';

  @override
  String get shortcutQuranAyahPrevDescription =>
      'اختيار الآية السابقة في وضع الدراسة.';

  @override
  String get shortcutQuranAyahPrevLabel => 'الآية السابقة';

  @override
  String get shortcutQuranPageNextDescription =>
      'الانتقال إلى صفحة المصحف التالية (اتجاه القراءة).';

  @override
  String get shortcutQuranPageNextLabel => 'الصفحة التالية';

  @override
  String get shortcutQuranPageNextSpaceDescription =>
      'الانتقال إلى صفحة المصحف التالية.';

  @override
  String get shortcutQuranPageNextSpaceLabel => 'الصفحة التالية (مسافة)';

  @override
  String get shortcutQuranPagePrevDescription =>
      'العودة إلى صفحة المصحف السابقة.';

  @override
  String get shortcutQuranPagePrevLabel => 'الصفحة السابقة';

  @override
  String get shortcutQuranZoomInDescription =>
      'تكبير صفحة المصحف (يعمل أيضاً Ctrl/⌘ مع التمرير). التمرير العمودي فقط عند الحاجة.';

  @override
  String get shortcutQuranZoomInLabel => 'تكبير';

  @override
  String get shortcutQuranZoomOutDescription => 'تصغير صفحة المصحف.';

  @override
  String get shortcutQuranZoomOutLabel => 'تصغير';

  @override
  String get shortcutQuranZoomResetDescription =>
      'إعادة تكبير المصحف إلى حجم النص المحفوظ.';

  @override
  String get shortcutQuranZoomResetLabel => 'إعادة التكبير';

  @override
  String get shortcutToggleLocaleDescription =>
      'التبديل بين الإنجليزية والعربية.';

  @override
  String get shortcutToggleLocaleLabel => 'تبديل اللغة';

  @override
  String get shortcutToggleThemeDescription =>
      'التبديل بين الوضع الفاتح والداكن.';

  @override
  String get shortcutToggleThemeLabel => 'تبديل المظهر';

  @override
  String get signedExampleHint => '20 أو -10';

  @override
  String get singapore => 'سنغافورة';

  @override
  String get skip => 'تخطي';

  @override
  String get slate => 'رمادي';

  @override
  String get sourceLabel => 'المصدر:';

  @override
  String get status => 'الحالة';

  @override
  String get stone => 'حجر';

  @override
  String streakInDays(int streak) {
    String _temp0 = intl.Intl.pluralLogic(
      streak,
      locale: localeName,
      other: '$streak يومًا',
      many: '$streak يومًا',
      few: '$streak أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '0',
    );
    return '$_temp0';
  }

  @override
  String get studyMode => 'وضع الدراسة';

  @override
  String get studyTabCurrentAyah => 'الآية الحالية';

  @override
  String get studyTabMyReflections => 'خواطري';

  @override
  String sunnahAlertTitle(String prayer) {
    return '$prayer';
  }

  @override
  String get sunnahOsNotificationBody => 'حان وقت صلاة السنة.';

  @override
  String get sunnahTimes => 'أوقات السنن';

  @override
  String get sunrise => 'الشروق';

  @override
  String surahAyahInfo(String surahName, int ayahNumber) {
    return '$surahName • الآية $ayahNumber';
  }

  @override
  String surahNameDefault(int number) {
    return 'سورة $number';
  }

  @override
  String get tafsir => 'التفسير';

  @override
  String get tafsirAlMuyassar => 'التفسير الميسر';

  @override
  String get tafsirTextMayBeIncomplete =>
      'قد يكون هذا التفسير مقطوعًا في النص المصدر.';

  @override
  String get tehran => 'طهران';

  @override
  String get timeFormat => 'تنسيق الوقت';

  @override
  String get timeSectionSubtitle => 'إعداد طريقة الحساب وتنسيق الوقت والإقامة.';

  @override
  String get timeSectionTitle => 'مواقيت الصلاة';

  @override
  String get timezone => 'المنطقة الزمنية';

  @override
  String get todayAchievement => 'إنجاز اليوم';

  @override
  String get todaysSchedule => 'جدول اليوم';

  @override
  String get toggleArabic => 'بدّل اللغة';

  @override
  String get total => 'الإجمالي';

  @override
  String get translation => 'الترجمة';

  @override
  String get trayHideApp => 'إخفاء تَوَّاق';

  @override
  String trayNextPrayerStatus(String prayer, String time, String remaining) {
    return 'التالي: $prayer · $time · بعد $remaining';
  }

  @override
  String get trayQuit => 'إنهاء';

  @override
  String get trayShowApp => 'إظهار تَوَّاق';

  @override
  String get trayStopAdhan => 'إيقاف الأذان';

  @override
  String get tryDifferentSearchTerm => 'جرب مصطلح بحث مختلف';

  @override
  String get turkiye => 'تركيا (ديانت)';

  @override
  String get typographySectionSubtitle =>
      'اضبط حجم نص الواجهة وحجم قراءة القرآن بشكل منفصل.';

  @override
  String get typographySectionTitle => 'النص والتحجيم';

  @override
  String get ummAlQura => 'جامعة أم القرى';

  @override
  String get unavailableShort => '—';

  @override
  String get unknownLocation => 'موقع غير معروف';

  @override
  String get unlockToEditCoordinates => 'افتح القفل لتعديل الإحداثيات';

  @override
  String get use24HourFormat => 'استخدام نظام 24 ساعة';

  @override
  String get useDeviceLocation => 'استخدام موقع الجهاز';

  @override
  String get useMyLocation => 'استخدم موقعي الحالي';

  @override
  String get useSystemTimezone => 'استخدام المنطقة الزمنية للنظام';

  @override
  String get violet => 'بنفسجي';

  @override
  String get weekly => 'أسبوعي';

  @override
  String get welcomeToApp => 'مرحبًا بك في التطبيق!';

  @override
  String get yearly => 'سنوي';

  @override
  String get yellow => 'أصفر';

  @override
  String get zinc => 'الخارصين';
}
