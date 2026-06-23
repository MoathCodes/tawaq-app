// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get about => 'عن التطبيق';

  @override
  String get addReflection => 'أضف تأملاً...';

  @override
  String get adhan => 'الأذان';

  @override
  String get adhanAdjustments => 'تعديلات الأذان (بالدقائق)';

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
  String get advancedSettingsTitle => 'إعدادات متقدمة';

  @override
  String get appearance => 'المظهر';

  @override
  String get appearanceSubtitle => 'تخصيص سمة التطبيق وألوانه.';

  @override
  String get appName => 'توّاق';

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
  String get ayahLabel => 'الآية';

  @override
  String get ayahBookmark => 'إشارة مرجعية';

  @override
  String ayahCopied(String reference) {
    return 'تم نسخ $reference';
  }

  @override
  String get ayahCopy => 'نسخ';

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
  String get colorTheme => 'نمط الألوان';

  @override
  String get colorThemeSubtitle => 'تغيير نمط الألوان في التطبيق.';

  @override
  String get typographySectionTitle => 'النص والتحجيم';

  @override
  String get typographySectionSubtitle =>
      'اضبط حجم نص الواجهة وحجم قراءة القرآن بشكل منفصل.';

  @override
  String get appTextSize => 'حجم نص التطبيق';

  @override
  String get appTextSizeCompact => 'مضغوط';

  @override
  String get appTextSizeNormal => 'افتراضي';

  @override
  String get appTextSizeLarge => 'كبير';

  @override
  String get appTextSizeExtraLarge => 'كبير جداً';

  @override
  String get quranTextSize => 'حجم نص القرآن';

  @override
  String get quranTextSizeSmall => 'صغير';

  @override
  String get quranTextSizeMedium => 'متوسط';

  @override
  String get quranTextSizeLarge => 'كبير';

  @override
  String get quranTextSizeExtraLarge => 'كبير جداً';

  @override
  String get quranTextSizeShortExtraLarge => 'أكبر';

  @override
  String get appTextSizeShortExtraLarge => 'أكبر';

  @override
  String get quranTextSizePreviewLabel => 'معاينة';

  @override
  String get quranTextSizeIndependentNote =>
      'حجم قراءة القرآن مستقل عن تحجيم التطبيق والنظام.';

  @override
  String get quranTextSizePreview => 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  @override
  String quranAyahSearchPreviewTruncated(String preview) {
    return '$preview...';
  }

  @override
  String quranTranslationQuoted(String translation) {
    return '\"$translation\"';
  }

  @override
  String get completed => 'مكتملة •';

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
  String get defaultLocation => 'الموقع الافتراضي';

  @override
  String get defaultSurahName => 'الفاتحة';

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
  String get tafsirTextMayBeIncomplete =>
      'قد يكون هذا التفسير مقطوعًا في النص المصدر.';

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
  String get fajr => 'الفجر';

  @override
  String get fajrAngleLabel => 'زاوية الفجر (°)';

  @override
  String get footnote => 'الحاشية';

  @override
  String get gettingLocation => 'الحصول على الموقع';

  @override
  String get graphicalAnalysis => 'الرسوم البيانية';

  @override
  String get green => 'أخضر';

  @override
  String get hadith => 'الأحاديث';

  @override
  String get hadithActiveFilters => 'مرشّحات البحث النشطة';

  @override
  String get hadithAlternativeAuthentic => 'روايات صحيحة بديلة';

  @override
  String get hadithBooks => 'الكتب';

  @override
  String get hadithClearAllFilters => 'مسح جميع المرشّحات';

  @override
  String get hadithClearAllRecents => 'مسح الكل';

  @override
  String get hadithDegrees => 'الدرجات';

  @override
  String get hadithDetailsTab => 'التفاصيل';

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
  String get hadithNoDetailedData => 'لا توجد بيانات تفصيلية لهذا الحديث';

  @override
  String get hadithNoDetailsSelected => 'اختر حديثًا من النتائج لعرض التفاصيل';

  @override
  String get hadithBackToSearch => 'العودة للبحث';

  @override
  String get hadithNoBookmarks => 'لا توجد أحاديث محفوظة';

  @override
  String get hadithNoMatchingResults => 'لا توجد نتائج مطابقة';

  @override
  String get hadithNoRecentSearches => 'لا توجد عمليات بحث حديثة';

  @override
  String get hadithOpenFilters => 'التصفية';

  @override
  String get hadithRecentSearches => 'عمليات البحث الأخيرة';

  @override
  String get hadithRelatedLinks => 'روابط ذات صلة';

  @override
  String get hadithSimilarHadith => 'أحاديث مشابهة';

  @override
  String get hadithAlternateHadithSahih => 'حديث صحيح بديل';

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
  String get hadithDegreeAll => 'جميع الدرجات';

  @override
  String get hadithDegreeAuthenticHadith =>
      'أحاديث حكم المحدثون عليها بالصحة، ونحو ذلك';

  @override
  String get hadithDegreeAuthenticChain =>
      'أحاديث حكم المحدثون على أسانيدها بالصحة، ونحو ذلك';

  @override
  String get hadithDegreeWeakHadith =>
      'أحاديث حكم المحدثون عليها بالضعف، ونحو ذلك';

  @override
  String get hadithDegreeWeakChain =>
      'أحاديث حكم المحدثون على أسانيدها بالضعف، ونحو ذلك';

  @override
  String hadithFieldLabel(String label) {
    return '$label:';
  }

  @override
  String hadithSourceCitation(String book, String reference) {
    return '$book ($reference)';
  }

  @override
  String get hadithSharh => 'الشرح';

  @override
  String get hadithSimilar => 'أحاديث مشابهة';

  @override
  String get hadithSource => 'المصدر';

  @override
  String get hadithSpecialist => 'تخريج';

  @override
  String get hadithSpecialistHint =>
      'إرجاع الأحاديث التي تتضمّن التخريج في بياناتها فقط';

  @override
  String get hadithStartSearchPrompt => 'ابدأ البحث لعرض النتائج';

  @override
  String get hadithTakhrij => 'التخريج';

  @override
  String get hadithUsulHadith => 'أصول الحديث';

  @override
  String get hadithTypeToSearch => 'اكتب للبحث...';

  @override
  String get highLatitudeRule_middleOfTheNight => 'منتصف الليل';

  @override
  String get highLatitudeRule_seventhOfTheNight => 'سبع الليل';

  @override
  String get highLatitudeRule_twilightAngle => 'زاوية الشفق';

  @override
  String get highLatitudeRuleLabel => 'قاعدة خطوط العرض العالية';

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
  String get iqamahSavedDescription => 'حُفظت تعديلات الإقامة بنجاح.';

  @override
  String iqamahSavedForPrayer(String prayer) {
    return 'حُفظ ضبط الإقامة لصلاة $prayer.';
  }

  @override
  String get iqamahSavedTitle => 'حُفظت إعدادات الإقامة';

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
  String get loadingSchedule => 'جارٍ تحميل الجدول';

  @override
  String get loadingLocationSettings => 'جارٍ تحميل إعدادات الموقع';

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
  String get fortressCompleted => 'انتهى';

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
  String get fortressSharh => 'الشرح';

  @override
  String get fortressVirtue => 'الفضل';

  @override
  String get fortressBenefit => 'الفائدة';

  @override
  String get fortressRelatedHadith => 'حديث مرتبط';

  @override
  String get fortressSourceReference => 'المصدر';

  @override
  String get fortressWeakHadithWarning => 'تنبيه: هذا الذكر ضعيف أو موضوع';

  @override
  String get fortressFakeHadithGuide => 'دليل الأحاديث الضعيفة والموضوعة';

  @override
  String get fortressFakeHadithIntro =>
      'قائمة مرجعية من تطبيق حصن المسلم للأحاديث التي يُحذّر منها العلماء.';

  @override
  String get fortressBrowseWeakHadith => 'الأحاديث الضعيفة والموضوعة';

  @override
  String get fortressSearchHint => 'ابحث في الأذكار والأبواب...';

  @override
  String get fortressSearchTitles => 'الأبواب';

  @override
  String get fortressSearchContents => 'الأذكار';

  @override
  String get fortressNoSearchResults => 'لم يُعثر على نتائج';

  @override
  String get fortressFilterAuthenticity => 'تصفية حسب الحكم';

  @override
  String get fortressShowDetails => 'عرض التفاصيل';

  @override
  String get fortressShowSharh => 'عرض الشرح';

  @override
  String get fortressShowSource => 'عرض المصدر';

  @override
  String get fortressHideDetails => 'إخفاء التفاصيل';

  @override
  String get fortressLoadError => 'تعذّر تحميل الأذكار';

  @override
  String get fortressRetry => 'إعادة المحاولة';

  @override
  String get fortressAllChapters => 'كل الأذكار';

  @override
  String get fortressFavorites => 'المفضلة';

  @override
  String get fortressEmptyFavoritesTitle => 'لا توجد أقسام مفضلة بعد';

  @override
  String get fortressEmptySearchTitle => 'لا توجد نتائج للبحث';

  @override
  String get fortressEmptyFavoritesHint =>
      'اضغط على أيقونة الإشارة المرجعية بجانب أي قسم لإضافته هنا';

  @override
  String get fortressEmptySearchHint => 'جرّب كلمات بحث مختلفة';

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
  String get fortressStartReading => 'بدء القراءة';

  @override
  String get fortressNoAdhkarInChapter => 'لا توجد أذكار في هذا الباب';

  @override
  String get fortressFinish => 'إنهاء';

  @override
  String get fortressReadingHint =>
      'انقر على الذكر للعد · اسحب أفقياً للتنقل · مسافة للعد';

  @override
  String get fortressPrevious => 'السابق';

  @override
  String get fortressWelcomeTitle => 'اختر باباً وابدأ الذكر';

  @override
  String get fortressWelcomeSubtitle =>
      'تصفّح الأبواب من القائمة، أو ابدأ من التوصيات حسب وقتك أو المفضلة.';

  @override
  String get fortressRecommendedNow => 'موصى به الآن';

  @override
  String get fortressNoRecommendations => 'لا توجد توصيات متاحة حالياً';

  @override
  String get fortressNoFavoriteChapters =>
      'لا توجد أبواب مفضلة بعد — أضف إشارة مرجعية من القائمة الجانبية';

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
  String get fortressReadShort => 'قراءة قصيرة';

  @override
  String get fortressReadMedium => 'قراءة متوسط';

  @override
  String get fortressReadLong => 'قراءة مطولة';

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
  String get noResults => 'لا توجد نتائج.';

  @override
  String get noResultsFound => 'لا توجد نتائج';

  @override
  String get northAmerica => 'أمريكا الشمالية (ISNA)';

  @override
  String get noTafsirAvailable => 'لا يوجد تفسير متاح لهذه الآية';

  @override
  String get noTranslationAvailable => 'لا توجد ترجمة متاحة لهذه الآية';

  @override
  String get nowActive => 'نشط الآن';

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
  String get optionalHint => 'اختياري';

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
  String get selectVerseToAddReflection => 'يرجى اختيار آية لإضافة تأمل';

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
  String get quranLayoutDoublePage => 'صفحتان';

  @override
  String get quranLayoutStudyMode => 'وضع الدراسة';

  @override
  String get red => 'أحمر';

  @override
  String get reflectionPlaceholder => 'اكتب أفكارك حول هذه الآية...';

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
  String get saveNote => 'حفظ الملاحظة';

  @override
  String get saveParameters => 'حفظ الإعدادات';

  @override
  String get searchForMore => 'ابحث للمزيد من الخيارات';

  @override
  String get searchPlaceLabel => 'البحث عن موقع';

  @override
  String get searchQuran => 'ابحث في القرآن...';

  @override
  String get selectAyahToSeeContent => 'اختر آية لعرض المحتوى.';

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
  String get goToPrayerPage => 'انتقل إلى صفحة الصلاة';

  @override
  String get decimalPlaceholder => '٠٫٠';

  @override
  String get integerPlaceholder => '٠';

  @override
  String get signedExampleHint => '20 أو -10';

  @override
  String get singapore => 'سنغافورة';

  @override
  String get skip => 'تخطي';

  @override
  String get shareAppName => 'اسم التطبيق';

  @override
  String get shareBasmalah => 'البسملة';

  @override
  String get shareAttributionPrefix => 'بإستخدام';

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
  String shareImageSaved(String path) {
    return 'تم الحفظ في $path';
  }

  @override
  String get shareIncludeInImage => 'تضمين في الصورة';

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
  String shareRangeSingleDescription(String reference, String verseCount) {
    return '$reference ($verseCount)';
  }

  @override
  String shareRangeOnPage(int page) {
    return 'النطاق في الصفحة $page';
  }

  @override
  String get shareSaveImage => 'حفظ الصورة';

  @override
  String get sharePreserveLineBreaks => 'فواصل أسطر المصحف';

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
  String get tryDifferentSearchTerm => 'جرب مصطلح بحث مختلف';

  @override
  String get turkiye => 'تركيا (ديانت)';

  @override
  String get ummAlQura => 'جامعة أم القرى';

  @override
  String get unlockToEditCoordinates => 'افتح القفل لتعديل الإحداثيات';

  @override
  String get use24HourFormat => 'استخدام نظام 24 ساعة';

  @override
  String get useDeviceLocation => 'استخدام موقع الجهاز';

  @override
  String get useMyLocation => 'استخدم موقعي الحالي';

  @override
  String get unavailableShort => '—';

  @override
  String get unknownLocation => 'موقع غير معروف';

  @override
  String get useSystemTimezone => 'استخدام المنطقة الزمنية للنظام';

  @override
  String get violet => 'بنفسجي';

  @override
  String get weekly => 'أسبوعي';

  @override
  String get welcomeToApp => 'مرحبًا بك في التطبيق!';

  @override
  String get wizardStep_calculationMethod => 'طريقة الحساب';

  @override
  String get wizardStep_getStarted => 'ابدأ';

  @override
  String get wizardStep_iqamahAdjustments => 'الإقامة والتعديلات';

  @override
  String get wizardStep_location => 'الموقع';

  @override
  String get wizardStep_timeFormat => 'تنسيق الوقت';

  @override
  String get wizardStep_welcome => 'مرحبًا';

  @override
  String get yearly => 'سنوي';

  @override
  String get yellow => 'أصفر';

  @override
  String get zinc => 'الخارصين';

  @override
  String get a11ySwitchToLightTheme => 'التبديل إلى الوضع الفاتح';

  @override
  String get a11ySwitchToDarkTheme => 'التبديل إلى الوضع الداكن';

  @override
  String get a11yNavigationUnavailable => 'غير متاح';

  @override
  String get a11yExpandSidebar => 'توسيع الشريط الجانبي';

  @override
  String get a11yWindowMinimize => 'تصغير النافذة';

  @override
  String get a11yWindowMaximize => 'تكبير النافذة';

  @override
  String get a11yWindowRestore => 'استعادة النافذة';

  @override
  String get a11yWindowClose => 'إغلاق النافذة';

  @override
  String get a11yOpenSetupWizard => 'فتح معالج الإعداد';

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
  String get scheduleAlertOff => 'صامت';

  @override
  String get scheduleAlertSound => 'أذان';

  @override
  String get scheduleAlertIqamahSound => 'صوت';

  @override
  String get scheduleAlertNotify => 'تنبيه';

  @override
  String get scheduleAlertOffHint => 'بدون تنبيه لهذا الوقت';

  @override
  String get scheduleAlertSoundHint => 'تشغيل الأذان عند حلول الوقت';

  @override
  String get scheduleAlertIqamahSoundHint => 'تشغيل التنبيه عند حلول الوقت';

  @override
  String get scheduleAlertNotifyHint => 'إشعار بدون صوت';

  @override
  String scheduleAlertPickerTitle(String event) {
    return 'تنبيه $event';
  }

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
  String get keyboardShortcutsTabTitle => 'الإختصارات';

  @override
  String get keyboardShortcutsSectionTitle => 'اختصارات لوحة المفاتيح';

  @override
  String get keyboardShortcutsSectionSubtitle =>
      'قائمة مرجعية للاختصارات المتاحة على سطح المكتب. تعمل الاختصارات في كل الشاشات بما فيها هذه. لا يمكن تخصيصها.';

  @override
  String get keyboardShortcutsCategorySubtitle =>
      'متاحة عند استخدام التطبيق على سطح المكتب.';

  @override
  String get shortcutCategoryGlobal => 'عام';

  @override
  String get shortcutCategoryQuran => 'القرآن';

  @override
  String get shortcutCategoryFortress => 'حصن المسلم';

  @override
  String get shortcutToggleThemeLabel => 'تبديل المظهر';

  @override
  String get shortcutToggleThemeDescription =>
      'التبديل بين الوضع الفاتح والداكن.';

  @override
  String get shortcutToggleLocaleLabel => 'تبديل اللغة';

  @override
  String get shortcutToggleLocaleDescription =>
      'التبديل بين الإنجليزية والعربية.';

  @override
  String get shortcutOpenSettingsLabel => 'فتح الإعدادات';

  @override
  String get shortcutOpenSettingsDescription => 'الانتقال إلى شاشة الإعدادات.';

  @override
  String get shortcutFocusSearchLabel => 'التركيز على البحث';

  @override
  String get shortcutFocusSearchDescription =>
      'فتح أو التركيز على حقل البحث في القرآن والحديث وحصن المسلم.';

  @override
  String get shortcutFocusSearchUnavailable => 'البحث غير متاح في هذه الشاشة.';

  @override
  String get shortcutQuranPageNextLabel => 'الصفحة التالية';

  @override
  String get shortcutQuranPageNextDescription =>
      'الانتقال إلى صفحة المصحف التالية (اتجاه القراءة).';

  @override
  String get shortcutQuranPagePrevLabel => 'الصفحة السابقة';

  @override
  String get shortcutQuranPagePrevDescription =>
      'العودة إلى صفحة المصحف السابقة.';

  @override
  String get shortcutQuranPageNextSpaceLabel => 'الصفحة التالية (مسافة)';

  @override
  String get shortcutQuranPageNextSpaceDescription =>
      'الانتقال إلى صفحة المصحف التالية.';

  @override
  String get shortcutQuranAyahNextLabel => 'الآية التالية';

  @override
  String get shortcutQuranAyahNextDescription =>
      'اختيار الآية التالية في وضع الدراسة.';

  @override
  String get shortcutQuranAyahPrevLabel => 'الآية السابقة';

  @override
  String get shortcutQuranAyahPrevDescription =>
      'اختيار الآية السابقة في وضع الدراسة.';

  @override
  String get shortcutFortressCountLabel => 'عدّ الذكر';

  @override
  String get shortcutFortressCountDescription =>
      'تقليل عداد التكرار أثناء القراءة المركّزة.';

  @override
  String get shortcutFortressThikrNextLabel => 'الذكر التالي';

  @override
  String get shortcutFortressThikrNextDescription =>
      'الانتقال إلى الذكر التالي أثناء القراءة المركّزة.';

  @override
  String get shortcutFortressThikrPrevLabel => 'الذكر السابق';

  @override
  String get shortcutFortressThikrPrevDescription =>
      'العودة إلى الذكر السابق أثناء القراءة المركّزة.';

  @override
  String get adhanSectionTitle => 'الأذان';

  @override
  String get adhanSectionSubtitle =>
      'تنبيهات وأصوات الأذان على سطح المكتب. يجب أن يبقى التطبيق يعمل في شريط النظام لتشغيل الأذان.';

  @override
  String get adhanSoundLabel => 'صوت الأذان';

  @override
  String get adhanMuezzinMisharyAlafasi => 'مشاري العفاسي';

  @override
  String get adhanMuezzinMakkah => 'مكة المكرمة';

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
  String get adhanMuezzinMansoorAlZahrani => 'منصور الزهراني';

  @override
  String get adhanMuezzinMohammadAlMenshawy => 'محمد المنشاوي';

  @override
  String get adhanMuezzinMohammadRefat => 'محمد رفعت';

  @override
  String get adhanMuezzinNasserAlQatami => 'ناصر القطامي';

  @override
  String get adhanMuezzinSuhaibKhatba => 'صهيب خطاب';

  @override
  String get adhanVolumeLabel => 'مستوى صوت الأذان';

  @override
  String get adhanShowAlertLabel => 'إظهار تنبيه الأذان';

  @override
  String get adhanShowOsNotificationLabel =>
      'إشعار النظام عند الإخفاء في الشريط';

  @override
  String get adhanAlertPositionLabel => 'موضع التنبيه';

  @override
  String get adhanAlertPositionTopEnd => 'أعلى اليمين';

  @override
  String get adhanAlertPositionTopStart => 'أعلى اليسار';

  @override
  String get adhanAlertPositionCenter => 'الوسط';

  @override
  String get adhanStop => 'إيقاف الأذان';

  @override
  String adhanAlertTitle(String prayer) {
    return 'الأذان — $prayer';
  }

  @override
  String adhanPlayingTitle(String prayer) {
    return 'الأذان — $prayer';
  }

  @override
  String get adhanOsNotificationBody => 'الأذان يعمل ';

  @override
  String iqamahAlertTitle(String prayer) {
    return 'الإقامة — $prayer';
  }

  @override
  String iqamahPlayingTitle(String prayer) {
    return 'الإقامة — $prayer';
  }

  @override
  String get iqamahOsNotificationBody => 'وقت الإقامة ';

  @override
  String sunnahAlertTitle(String prayer) {
    return '$prayer';
  }

  @override
  String get sunnahOsNotificationBody => 'وقت السنة ';

  @override
  String get prayerAlertDismiss => 'إغلاق';

  @override
  String get iqamahSoundLabel => 'نداء الإقامة';

  @override
  String get iqamahMuezzinYasserAlDossari => 'ياسر الدوسري';

  @override
  String get iqamahMuezzinMadinah => 'المدينة المنورة';

  @override
  String get desktopSectionTitle => 'سطح المكتب';

  @override
  String get desktopSectionSubtitle =>
      'شريط النظام وسلوك النافذة والبدء التلقائي على سطح المكتب.';

  @override
  String get desktopLaunchAtLogin => 'البدء عند تسجيل الدخول';

  @override
  String get desktopLaunchAtLoginHint =>
      'تم تفعيل البدء مخفياً في الشريط أيضاً حتى تعمل تنبيهات الأذان بعد تسجيل الدخول.';

  @override
  String get desktopMinimizeToTrayOnClose =>
      'الإخفاء في الشريط عند إغلاق النافذة';

  @override
  String get desktopMinimizeToTray => 'الإخفاء في الشريط عند التصغير';

  @override
  String get desktopLaunchToTray => 'البدء مخفياً في الشريط';

  @override
  String get trayShowApp => 'إظهار تواق';

  @override
  String get trayHideApp => 'إخفاء تواق';

  @override
  String get trayMuteAdhan => 'كتم الأذان';

  @override
  String get trayQuit => 'إنهاء';

  @override
  String trayNextPrayer(String prayer) {
    return 'التالي: $prayer';
  }

  @override
  String get quranRecitationComingSoon => 'تشغيل التلاوة قريباً';

  @override
  String get quranPlayAyah => 'تشغيل الآية';
}
