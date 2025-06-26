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
  String get bestStreak => 'أفضل إنجاز';

  @override
  String get blue => 'أزرق';

  @override
  String get colorTheme => 'نمط الألوان';

  @override
  String get colorThemeSubtitle => 'تغيير نمط الألوان في التطبيق.';

  @override
  String get completed => 'مكتملة •';

  @override
  String get completionStatus => 'حالة الاكتمال';

  @override
  String get currentPrayer => 'الصلاة الحالية';

  @override
  String get currentStreak => 'الإنجاز الحالي';

  @override
  String get dark => 'داكن';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get english => 'الإنجيليزية';

  @override
  String get errorNotFoundPage =>
      'لم نستطع الوصول لهذه الصفحة الرجاء التأكد من الرابط ثم إعادة المحاولة.';

  @override
  String get fajr => 'الفجر';

  @override
  String get green => 'أخضر';

  @override
  String get hadith => 'الحديث';

  @override
  String get iqamah => 'الإقامة';

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
  String get islamicTheme => 'المخطوطة';

  @override
  String get jamaah => 'جماعة';

  @override
  String get jamaahRate => 'الصلاة جماعة';

  @override
  String get lastThirdOfTheNight => 'الثلث الأخير من الليل';

  @override
  String get late => 'متأخر';

  @override
  String get lateRate => 'الصلاة متأخرًا';

  @override
  String get light => 'فاتح';

  @override
  String get maghrib => 'المغرب';

  @override
  String get midnight => 'منتصف الليل';

  @override
  String get missed => 'فائتة';

  @override
  String get missedRate => 'الصلاة الفائتة';

  @override
  String get monthly => 'شهري';

  @override
  String get muslimFortress => 'حصن المسلم';

  @override
  String get neutral => 'محايد';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get onTime => 'في وقتها';

  @override
  String get onTimePrayersLast30Days => 'الصلاة المنتظمة (ﻷخر 30 يوم)';

  @override
  String get onTimePrayersLast365Days => 'الصلاة المنتظمة (ﻷخر 365 يوم)';

  @override
  String get onTimePrayersLast7Days => 'الصلاة المنتظمة (ﻷخر 7 أيام)';

  @override
  String get onTimeRate => 'الصلاة في وقتها';

  @override
  String get orange => 'برتقالي';

  @override
  String get playerAnalytics => 'تحليل الصلاة';

  @override
  String get prayer => 'الصلاة';

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
  String get quran => 'القرآن الكريم';

  @override
  String get red => 'أحمر';

  @override
  String get remembrance => 'الأذكار';

  @override
  String get rose => 'وردي';

  @override
  String get settings => 'الإعدادات';

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
  String get toggleArabic => 'حول اللغة';

  @override
  String get violet => 'بنفسجي';

  @override
  String get weekly => 'أسبوعي';

  @override
  String get yearly => 'سنوي';

  @override
  String get yellow => 'أصفر';

  @override
  String get zinc => 'زنك';
}
