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
  String get appearance => 'خصائص العرض';

  @override
  String get appearanceSubtitle => 'تخصيص مظهر التطبيق.';

  @override
  String get appName => 'حسانات';

  @override
  String get arabic => 'العربية';

  @override
  String get asr => 'العصر';

  @override
  String get autoSelectOrMap => 'تحديد تلقائي او بالخريطة';

  @override
  String get back => 'رجوع';

  @override
  String get basicParametersTitle => 'إعدادات أساسية';

  @override
  String get bestStreak => 'أفضل إنجاز';

  @override
  String get blue => 'أزرق';

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
  String get completed => 'مكتملة •';

  @override
  String get completionStatus => 'حالة الاكتمال';

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
  String get dragTheMapTip => 'اسحب الخريطة لتحديد موقع الدبوس';

  @override
  String get dubai => 'دبي';

  @override
  String get editsSavedDescription => 'تم حفظ تغييراتك بنجاح.';

  @override
  String get editsSavedTitle => 'تم حفظ التعديلات';

  @override
  String get egyptian => 'الهيئة العامة المصرية للمساحة';

  @override
  String get english => 'الإنجيليزية';

  @override
  String get errorNotFoundPage =>
      'لم نستطع الوصول لهذه الصفحة الرجاء التأكد من الرابط ثم إعادة المحاولة.';

  @override
  String errorOccurredWhile(String whileError) {
    return 'حدث خطأ أثناء $whileError';
  }

  @override
  String get errorUpdatingLocationDescription =>
      'تم تحديث الإحداثيات بنجاح، ولكن لم نتمكن من جلب اسم موقعك. لن يؤثر ذلك على عمل التطبيق.';

  @override
  String get errorUpdatingLocationTitle => 'حدث خطأ أثناء تحديث الموقع';

  @override
  String get fajr => 'الفجر';

  @override
  String get fajrAngleLabel => 'زاوية الفجر (°)';

  @override
  String get gettingLocation => 'الحصول على الموقع';

  @override
  String get green => 'أخضر';

  @override
  String get hadith => 'الحديث';

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
  String get iqamah => 'الإقامة';

  @override
  String get iqamahAdjustment => 'ضبط الإقامة';

  @override
  String get iqamahAfterAdhan => 'الإقامة (دقائق بعد الأذان)';

  @override
  String get iqamahSavedDescription => 'تم حفظ تعديلات الإقامة بنجاح.';

  @override
  String get iqamahSavedTitle => 'تم حفظ إعدادات الإقامة';

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
  String get jamaahRate => 'الصلاة جماعة';

  @override
  String get jumuah => 'الجمعة';

  @override
  String get karachi => 'جامعة العلوم الإسلامية، كراتشي';

  @override
  String get kuwait => 'الكويت';

  @override
  String get lastThirdOfTheNight => 'الثلث الأخير من الليل';

  @override
  String get late => 'متأخر';

  @override
  String get lateRate => 'الصلاة متأخرًا';

  @override
  String get latitude => 'خط العرض';

  @override
  String get light => 'فاتح';

  @override
  String get loadingLocationSettings => 'جاري تحميل إعدادات الموقع';

  @override
  String get locationSectionSubtitle =>
      'تحديد الموقع الجغرافي وطريقة حساب مواقيت الصلاة.';

  @override
  String get locationSectionTitle => 'الموقع والحساب';

  @override
  String get lockToPreventEdits => 'اقفل لمنع التعديل';

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
  String get missedRate => 'الصلاة الفائتة';

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
  String get noResults => 'لا يوجد نتائج.';

  @override
  String get northAmerica => 'أمريكا الشمالية (ISNA)';

  @override
  String get onTime => 'في وقتها';

  @override
  String get onTimePrayersLast30Days => 'الصلاة المنتظمة (ﻷخر 30 يوم)';

  @override
  String get onTimePrayersLast365Days => 'الصلاة المنتظمة (ﻷخر 365 يوم)';

  @override
  String get onTimePrayersLast7Days => 'الصلاة المنتظمة (ﻷخر 7 أيام)';

  @override
  String get onTimePrayersToday => 'On time prayers (today)';

  @override
  String get onTimeRate => 'الصلاة في وقتها';

  @override
  String get optionalHint => 'اختياري';

  @override
  String get orange => 'برتقالي';

  @override
  String get other => 'أخرى';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get pageNotFoundDescription =>
      'هذه الصفحة غير موجودة. يرجى العودة إلى الصفحة الرئيسية.';

  @override
  String get parametersSavedDescription => 'تم حفظ إعداداتك المخصصة بنجاح.';

  @override
  String get parametersSavedTitle => 'تم حفظ الإعدادات';

  @override
  String get placeholdersHint =>
      'يمكن ضبط المذهب والخيارات الأخرى لاحقًا. هذه المدخلات مؤقتة.';

  @override
  String get playerAnalytics => 'تحليل الصلاة';

  @override
  String get pleaseSelectMethod => 'يرجى اختيار طريقة الحساب.';

  @override
  String get prayer => 'الصلاة';

  @override
  String get prayerSettingsSubtitle =>
      'الإعدادات الخاصة بالصلاة ومواقيتها وتعقبها.';

  @override
  String get prayerSettingsTitle => 'اعدادات الصلاة';

  @override
  String get prayerTimeAdjustmentsTitle => 'تعديلات مواقيت الصلاة (بالدقائق)';

  @override
  String get prayerTimes => 'مواقيت الصلاة';

  @override
  String get prayerTrackerSubtitle =>
      'تتبع صلواتك وكن منتظمًا، انقر على صلاة لتحديدها كمكتملة.';

  @override
  String get prayerTrackerTitle => 'متعقب الصلاة';

  @override
  String get prepareForPrayer => 'تجهز للصلاة.';

  @override
  String get qatar => 'قطر';

  @override
  String get quran => 'القرآن الكريم';

  @override
  String get red => 'أحمر';

  @override
  String get remembrance => 'الأذكار';

  @override
  String get resetCompleteDescription =>
      'تمت إعادة الإعدادات إلى القيم الافتراضية.';

  @override
  String get resetCompleteTitle => 'تمت إعادة الضبط';

  @override
  String get resetToDefaults => 'إعادة الضبط للوضع الافتراضي';

  @override
  String get rose => 'وردي';

  @override
  String get save => 'حفظ';

  @override
  String get saveParameters => 'حفظ الإعدادات';

  @override
  String get searchForMore => 'ابحث للمزيد من الخيارات';

  @override
  String get searchPlaceLabel => 'البحث عن موقع';

  @override
  String get settings => 'الإعدادات';

  @override
  String get setupPrayerSettingsSubtitle =>
      'سنرشدك عبر خطوات سريعة. يمكنك تغيير هذه لاحقًا من الإعدادات.';

  @override
  String get setupPrayerSettingsTitle => 'لنقم بإعداد إعدادات الصلاة.';

  @override
  String get setupPreferences => 'لنقم بضبط تفضيلاتك.';

  @override
  String get signedExampleHint => '20 أو -10';

  @override
  String get singapore => 'سنغافورة';

  @override
  String get skip => 'تخطي';

  @override
  String get slate => 'رمادي';

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
  String get sunrise => 'الشروق';

  @override
  String get tehran => 'طهران';

  @override
  String get timeFormat => 'تنسيق الوقت';

  @override
  String get timeSectionSubtitle => 'تنسيق عرض الوقت وأوقات الإقامة لكل صلاة.';

  @override
  String get timeSectionTitle => 'عرض الأوقات والإقامة';

  @override
  String get timezone => 'المنطقة الزمنية';

  @override
  String get tipHoldCtrlToRotate =>
      'تلميح: اضغط على Ctrl واسحب لتدوير وإمالة الخريطة.';

  @override
  String get toggleArabic => 'حول اللغة';

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
  String get zinc => 'زنك';
}
