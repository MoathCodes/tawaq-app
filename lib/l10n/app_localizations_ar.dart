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
    final intl.NumberFormat hoursNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String hoursString = hoursNumberFormat.format(hours);

    return '$hoursString ساعة مضت';
  }

  @override
  String adhanHoursLeft(int hours) {
    final intl.NumberFormat hoursNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String hoursString = hoursNumberFormat.format(hours);

    return '$hoursString ساعة متبقية';
  }

  @override
  String adhanMinsAgo(int mins) {
    final intl.NumberFormat minsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String minsString = minsNumberFormat.format(mins);

    return '$minsString دقيقة مضت';
  }

  @override
  String adhanMinsLeft(int mins) {
    final intl.NumberFormat minsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String minsString = minsNumberFormat.format(mins);

    return '$minsString دقيقة متبقية';
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
    final intl.NumberFormat iqamahMinsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String iqamahMinsString = iqamahMinsNumberFormat.format(iqamahMins);

    return '+$iqamahMinsString دقيقة';
  }

  @override
  String get isha => 'العشاء';

  @override
  String get islamicTheme => 'المخطوطة';

  @override
  String get jamaah => 'جماعة';

  @override
  String get lastThirdOfTheNight => 'الثلث الأخير من الليل';

  @override
  String get late => 'متأخر';

  @override
  String get light => 'فاتح';

  @override
  String get maghrib => 'المغرب';

  @override
  String get midnight => 'منتصف الليل';

  @override
  String get missed => 'فائتة';

  @override
  String get muslimFortress => 'حصن المسلم';

  @override
  String get neutral => 'محايد';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get onTime => 'في وقتها';

  @override
  String get orange => 'برتقالي';

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
  String get sunrise => 'الشروق';

  @override
  String get toggleArabic => 'حول اللغة';

  @override
  String get violet => 'بنفسجي';

  @override
  String get yellow => 'أصفر';

  @override
  String get zinc => 'زنك';
}
