// import 'package:shadcn_flutter/shadcn_flutter.dart';

// class ArabicShadcnLocale implements ShadcnLocalizations {
//   static const ShadcnLocalizations instance = ArabicShadcnLocale();

//   @override
//   final Map<String, String> localizedMimeTypes = const {
//     'audio/aac': 'صوت AAC',
//     'application/x-abiword': 'مستند AbiWord',
//     'image/apng': 'صورة PNG متحركة',
//     'application/x-freearc': 'مستند أرشيف',
//     'image/avif': 'صورة AVIF',
//     'video/x-msvideo': 'AVI: صوت وفيديو متداخل',
//     'application/vnd.amazon.ebook': 'تنسيق كتاب Kindle الإلكتروني',
//     'application/octet-stream': 'بيانات ثنائية',
//     'image/bmp': 'رسومات بت ماب Windows OS/2',
//     'application/x-bzip': 'أرشيف BZip',
//     'application/x-bzip2': 'أرشيف BZip2',
//     'application/x-cdf': 'صوت CD',
//     'application/x-csh': 'نص برمجي C-Shell',
//     'text/css': 'أوراق الأنماط المتتالية (CSS)',
//     'text/csv': 'قيم مفصولة بفواصل (CSV)',
//     'application/msword': 'مايكروسوفت وورد',
//     'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
//         'مايكروسوفت وورد (OpenXML)',
//     'application/vnd.ms-fontobject': 'خطوط MS المضمنة OpenType',
//     'application/epub+zip': 'منشور إلكتروني (EPUB)',
//     'application/gzip': 'أرشيف مضغوط GZip',
//     'image/gif': 'تنسيق تبادل الرسومات (GIF)',
//     'text/html': 'لغة ترميز النص التشعبي (HTML)',
//     'image/vnd.microsoft.icon': 'تنسيق الأيقونة',
//     'text/calendar': 'تنسيق التقويم',
//     'application/java-archive': 'أرشيف جافا (JAR)',
//     'image/jpeg': 'صور JPEG',
//     'text/javascript': 'جافا سكريبت',
//     'application/json': 'تنسيق JSON',
//     'application/ld+json': 'تنسيق JSON-LD',
//     'audio/midi': 'واجهة الآلات الموسيقية الرقمية (MIDI)',
//     'audio/x-midi': 'واجهة الآلات الموسيقية الرقمية (MIDI)',
//     'audio/mpeg': 'صوت MP3',
//     'video/mp4': 'فيديو MP4',
//     'video/mpeg': 'فيديو MPEG',
//     'application/vnd.apple.installer+xml': 'حزمة تثبيت أبل',
//     'application/vnd.oasis.opendocument.presentation':
//         'مستند عرض تقديمي OpenDocument',
//     'application/vnd.oasis.opendocument.spreadsheet':
//         'مستند جدول بيانات OpenDocument',
//     'application/vnd.oasis.opendocument.text': 'مستند نصي OpenDocument',
//     'audio/ogg': 'صوت Ogg',
//     'video/ogg': 'فيديو Ogg',
//     'application/ogg': 'Ogg',
//     'font/otf': 'خط OpenType',
//     'image/png': 'رسومات الشبكة المحمولة',
//     'application/pdf': 'تنسيق المستندات المحمولة من أدوبي (PDF)',
//     'application/x-httpd-php': 'معالج النصوص التشعبية (PHP)',
//     'application/vnd.ms-powerpoint': 'مايكروسوفت باوربوينت',
//     'application/vnd.openxmlformats-officedocument.presentationml.presentation':
//         'مايكروسوفت باوربوينت (OpenXML)',
//     'application/vnd.rar': 'أرشيف RAR',
//     'application/rtf': 'تنسيق النص المنسق (RTF)',
//     'application/x-sh': 'نص برمجي شل بورن',
//     'image/svg+xml': 'رسومات متجهة قابلة للتطوير (SVG)',
//     'application/x-tar': 'أرشيف شريطي (TAR)',
//     'image/tiff': 'تنسيق ملف الصور المعلم (TIFF)',
//     'video/mp2t': 'دفق نقل MPEG',
//     'font/ttf': 'خط TrueType',
//     'text/plain': 'نص عادي',
//     'application/vnd.visio': 'مايكروسوفت فيزيو',
//     'audio/wav': 'تنسيق الصوت Waveform',
//     'audio/webm': 'صوت WEBM',
//     'video/webm': 'فيديو WEBM',
//     'image/webp': 'صورة WEBP',
//     'font/woff': 'تنسيق خط الويب المفتوح (WOFF)',
//     'font/woff2': 'تنسيق خط الويب المفتوح (WOFF)',
//     'application/xhtml+xml': 'XHTML',
//     'application/vnd.ms-excel': 'مايكروسوفت إكسل',
//     'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
//         'مايكروسوفت إكسل (OpenXML)',
//     'application/xml': 'XML',
//     'application/vnd.mozilla.xul+xml': 'XUL',
//     'application/zip': 'أرشيف ZIP',
//     'video/3gpp': 'حاوية صوت/فيديو 3GPP',
//     'audio/3gpp': 'حاوية صوت/فيديو 3GPP',
//     'video/3gpp2': 'حاوية صوت/فيديو 3GPP2',
//     'audio/3gpp2': 'حاوية صوت/فيديو 3GPP2',
//     'application/x-7z-compressed': 'أرشيف 7-Zip',
//   };

//   const ArabicShadcnLocale();

//   @override
//   String get abbreviatedApril => 'أبر';

//   @override
//   String get abbreviatedAugust => 'أغس';

//   @override
//   String get abbreviatedDecember => 'ديس';

//   @override
//   String get abbreviatedFebruary => 'فبر';

//   @override
//   String get abbreviatedFriday => 'ج';

//   @override
//   String get abbreviatedJanuary => 'ينا';

//   @override
//   String get abbreviatedJuly => 'يول';

//   @override
//   String get abbreviatedJune => 'يون';

//   @override
//   String get abbreviatedMarch => 'مار';

//   @override
//   String get abbreviatedMay => 'ماي';

//   @override
//   String get abbreviatedMonday => 'ن';

//   @override
//   String get abbreviatedNovember => 'نوف';

//   @override
//   String get abbreviatedOctober => 'أكت';

//   @override
//   String get abbreviatedSaturday => 'س';

//   @override
//   String get abbreviatedSeptember => 'سبت';

//   @override
//   String get abbreviatedSunday => 'ح';

//   @override
//   String get abbreviatedThursday => 'خ';

//   @override
//   String get abbreviatedTuesday => 'ث';

//   @override
//   String get abbreviatedWednesday => 'ر';

//   @override
//   String get buttonCancel => 'إلغاء';

//   @override
//   String get buttonClose => 'إغلاق';

//   @override
//   String get buttonNext => 'التالي';

//   @override
//   String get buttonOk => 'موافق';

//   @override
//   String get buttonPrevious => 'السابق';

//   @override
//   String get buttonReset => 'إعادة تعيين';

//   @override
//   String get buttonSave => 'حفظ';

//   @override
//   String get colorAlpha => 'شفافية';

//   @override
//   String get colorBlue => 'أزرق';

//   @override
//   String get colorGreen => 'أخضر';

//   @override
//   String get colorHue => 'تدرج';

//   @override
//   String get colorLightness => 'إضاءة';

//   @override
//   String get colorPickerTabHSL => 'HSL';

//   @override
//   String get colorPickerTabHSV => 'HSV';

//   @override
//   String get colorPickerTabRecent => 'الأخيرة';

//   @override
//   String get colorPickerTabRGB => 'RGB';

//   @override
//   String get colorRed => 'أحمر';

//   @override
//   String get colorSaturation => 'تشبع';

//   @override
//   String get colorValue => 'قيمة';

//   @override
//   String get commandEmpty => 'لم يتم العثور على نتائج.';

//   @override
//   String get commandSearch => 'اكتب أمراً أو ابحث...';

//   @override
//   String get dataTableColumns => 'الأعمدة';

//   @override
//   String get dataTableNext => 'التالي';

//   @override
//   String get dataTablePrevious => 'السابق';

//   @override
//   String get dateDayAbbreviation => 'ي ي';

//   @override
//   String get dateMonthAbbreviation => 'ش ش';

//   @override
//   List<DatePart> get datePartsOrder => const [
//         // DD/MM/YYYY
//         DatePart.day,
//         DatePart.month,
//         DatePart.year,
//       ];

//   @override
//   String get datePickerSelectYear => 'اختر سنة';

//   @override
//   String get dateYearAbbreviation => 'س س س س';

//   @override
//   String get durationDay => 'يوم';

//   @override
//   String get durationHour => 'ساعة';

//   @override
//   String get durationMinute => 'دقيقة';

//   @override
//   String get durationSecond => 'ثانية';

//   @override
//   String get emptyCountryList => 'لم يتم العثور على دول';

//   @override
//   String get formNotEmpty => 'لا يمكن ترك هذا الحقل فارغاً';

//   @override
//   String get formPasswordDigits => 'يجب أن يحتوي على رقم واحد على الأقل';

//   @override
//   String get formPasswordLowercase =>
//       'يجب أن يحتوي على حرف صغير واحد على الأقل';

//   @override
//   String get formPasswordSpecial => 'يجب أن يحتوي على رمز خاص واحد على الأقل';

//   @override
//   String get formPasswordUppercase =>
//       'يجب أن يحتوي على حرف كبير واحد على الأقل';

//   @override
//   String get invalidEmail => 'بريد إلكتروني غير صالح';

//   @override
//   String get invalidURL => 'رابط غير صالح';

//   @override
//   String get invalidValue => 'قيمة غير صالحة';

//   @override
//   String get menuCopy => 'نسخ';

//   @override
//   String get menuCut => 'قص';

//   @override
//   String get menuDelete => 'حذف';

//   @override
//   String get menuLiveTextInput => 'إدخال النص المباشر';

//   @override
//   String get menuPaste => 'لصق';

//   @override
//   String get menuRedo => 'إعادة';

//   @override
//   String get menuSearchWeb => 'بحث في الويب';

//   @override
//   String get menuSelectAll => 'تحديد الكل';

//   @override
//   String get menuShare => 'مشاركة';

//   @override
//   String get menuUndo => 'تراجع';

//   @override
//   String get monthApril => 'أبريل';

//   @override
//   String get monthAugust => 'أغسطس';

//   @override
//   String get monthDecember => 'ديسمبر';

//   @override
//   String get monthFebruary => 'فبراير';

//   @override
//   String get monthJanuary => 'يناير';

//   @override
//   String get monthJuly => 'يوليو';

//   @override
//   String get monthJune => 'يونيو';

//   @override
//   String get monthMarch => 'مارس';

//   @override
//   String get monthMay => 'مايو';

//   @override
//   String get monthNovember => 'نوفمبر';

//   @override
//   String get monthOctober => 'أكتوبر';

//   @override
//   String get monthSeptember => 'سبتمبر';

//   @override
//   String get placeholderColorPicker => 'اختر لوناً';

//   @override
//   String get placeholderDatePicker => 'اختر تاريخاً';

//   @override
//   String get placeholderDurationPicker => 'اختر مدة';

//   @override
//   String get placeholderTimePicker => 'اختر وقتاً';

//   @override
//   String get refreshTriggerComplete => 'اكتمل التحديث';

//   @override
//   String get refreshTriggerPull => 'اسحب للتحديث';

//   @override
//   String get refreshTriggerRefreshing => 'جاري التحديث...';

//   @override
//   String get refreshTriggerRelease => 'حرر للتحديث';

//   @override
//   String get searchPlaceholderCountry => 'ابحث عن دولة...';

//   @override
//   String get timeAM => 'ص';

//   @override
//   String get timeDaysAbbreviation => 'ي ي';

//   @override
//   String get timeHour => 'ساعة';

//   @override
//   String get timeHoursAbbreviation => 'س س';

//   @override
//   String get timeMinute => 'دقيقة';

//   @override
//   String get timeMinutesAbbreviation => 'د د';

//   @override
//   String get timePM => 'م';

//   @override
//   String get timeSecond => 'ثانية';

//   @override
//   String get timeSecondsAbbreviation => 'ث ث';

//   @override
//   String get toastSnippetCopied => 'تم النسخ إلى الحافظة';

//   @override
//   String dataTableSelectedRows(int count, int total) {
//     return 'تم تحديد $count من أصل $total صف.';
//   }

//   // @override
//   // String datePartPlaceholder(DatePart part) {
//   //   switch (part) {
//   //     case DatePart.year:
//   //       return 'YYYY';
//   //     case DatePart.month:
//   //       return 'MM';
//   //     case DatePart.day:
//   //       return 'DD';
//   //   }
//   // }

//   @override
//   String formatDateTime(DateTime dateTime,
//       {bool showDate = true,
//       bool showTime = true,
//       bool showSeconds = false,
//       bool use24HourFormat = true}) {
//     String result = '';
//     if (showDate) {
//       result += '${getMonth(dateTime.month)} ${dateTime.day}، ${dateTime.year}';
//     }
//     if (showTime) {
//       if (use24HourFormat) {
//         if (result.isNotEmpty) {
//           result += ' ';
//         }
//         result += '${dateTime.hour}:${dateTime.minute}';
//         if (showSeconds) {
//           result += ':${dateTime.second}';
//         }
//       } else {
//         if (result.isNotEmpty) {
//           result += ' ';
//         }
//         int hour = dateTime.hour;
//         if (hour > 12) {
//           hour -= 12;
//           result += '$hour:${dateTime.minute} م';
//         } else {
//           result += '$hour:${dateTime.minute} ص';
//         }
//       }
//     }
//     return result;
//   }

//   @override
//   String formatDuration(Duration duration,
//       {bool showDays = true,
//       bool showHours = true,
//       bool showMinutes = true,
//       bool showSeconds = true}) {
//     final days = duration.inDays;
//     final hours = duration.inHours % Duration.hoursPerDay;
//     final minutes = duration.inMinutes % Duration.minutesPerHour;
//     final seconds = duration.inSeconds % Duration.secondsPerMinute;
//     final parts = <String>[];
//     if (showDays && days > 0) {
//       parts.add('$daysي');
//     }
//     if (showHours && hours > 0) {
//       parts.add('$hoursس');
//     }
//     if (showMinutes && minutes > 0) {
//       parts.add('$minutesد');
//     }
//     if (showSeconds && seconds > 0) {
//       parts.add('$secondsث');
//     }
//     return parts.join(' ');
//   }

//   @override
//   String formatNumber(double value) {
//     // إذا كانت القيمة عدداً صحيحاً، أرجع القيمة كعدد صحيح
//     if (value == value.toInt()) {
//       return value.toInt().toString();
//     }
//     return value.toString();
//   }

//   @override
//   String formatTimeOfDay(TimeOfDay time,
//       {bool use24HourFormat = true, bool showSeconds = false}) {
//     String result = '';
//     if (use24HourFormat) {
//       result +=
//           '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
//       if (showSeconds) {
//         result += ':${time.second.toString().padLeft(2, '0')}';
//       }
//     } else {
//       int hour = time.hour;
//       if (hour > 12) {
//         hour -= 12;
//         if (showSeconds) {
//           result +=
//               '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')} م';
//         } else {
//           result +=
//               '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} م';
//         }
//       } else {
//         if (showSeconds) {
//           result +=
//               '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')} ص';
//         } else {
//           result +=
//               '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ص';
//         }
//       }
//     }
//     return result;
//   }

//   @override
//   String formBetweenExclusively(double min, double max) =>
//       'يجب أن تكون القيمة بين ${formatNumber(min)} و ${formatNumber(max)} (غير شامل)';

//   @override
//   String formBetweenInclusively(double min, double max) =>
//       'يجب أن تكون القيمة بين ${formatNumber(min)} و ${formatNumber(max)} (شامل)';

//   @override
//   String formGreaterThan(double value) =>
//       'يجب أن تكون القيمة أكبر من ${formatNumber(value)}';

//   @override
//   String formGreaterThanOrEqualTo(double value) =>
//       'يجب أن تكون القيمة أكبر من أو تساوي ${formatNumber(value)}';

//   @override
//   String formLengthGreaterThan(int value) => 'يجب ألا يتجاوز عدد الأحرف $value';

//   @override
//   String formLengthLessThan(int value) =>
//       'يجب أن يكون عدد الأحرف على الأقل $value';

//   @override
//   String formLessThan(double value) =>
//       'يجب أن تكون القيمة أقل من ${formatNumber(value)}';

//   @override
//   String formLessThanOrEqualTo(double value) =>
//       'يجب أن تكون القيمة أقل من أو تساوي ${formatNumber(value)}';

//   @override
//   String getAbbreviatedMonth(int month) {
//     switch (month) {
//       case DateTime.january:
//         return abbreviatedJanuary;
//       case DateTime.february:
//         return abbreviatedFebruary;
//       case DateTime.march:
//         return abbreviatedMarch;
//       case DateTime.april:
//         return abbreviatedApril;
//       case DateTime.may:
//         return abbreviatedMay;
//       case DateTime.june:
//         return abbreviatedJune;
//       case DateTime.july:
//         return abbreviatedJuly;
//       case DateTime.august:
//         return abbreviatedAugust;
//       case DateTime.september:
//         return abbreviatedSeptember;
//       case DateTime.october:
//         return abbreviatedOctober;
//       case DateTime.november:
//         return abbreviatedNovember;
//       case DateTime.december:
//         return abbreviatedDecember;
//       default:
//         throw ArgumentError.value(month, 'month');
//     }
//   }

//   @override
//   String getAbbreviatedWeekday(int weekday) {
//     switch (weekday) {
//       case DateTime.monday:
//         return abbreviatedMonday;
//       case DateTime.tuesday:
//         return abbreviatedTuesday;
//       case DateTime.wednesday:
//         return abbreviatedWednesday;
//       case DateTime.thursday:
//         return abbreviatedThursday;
//       case DateTime.friday:
//         return abbreviatedFriday;
//       case DateTime.saturday:
//         return abbreviatedSaturday;
//       case DateTime.sunday:
//         return abbreviatedSunday;
//       default:
//         throw ArgumentError.value(weekday, 'weekday');
//     }
//   }

//   @override
//   String getColorPickerMode(ColorPickerMode mode) {
//     switch (mode) {
//       case ColorPickerMode.rgb:
//         return colorPickerTabRGB;
//       case ColorPickerMode.hsv:
//         return colorPickerTabHSV;
//       case ColorPickerMode.hsl:
//         return colorPickerTabHSL;
//     }
//   }

//   @override
//   String getDatePartAbbreviation(DatePart part) {
//     switch (part) {
//       case DatePart.year:
//         return dateYearAbbreviation;
//       case DatePart.month:
//         return dateMonthAbbreviation;
//       case DatePart.day:
//         return dateDayAbbreviation;
//     }
//   }

//   @override
//   String getDurationPartAbbreviation(DurationPart part) {
//     switch (part) {
//       case DurationPart.day:
//         return timeDaysAbbreviation;
//       case DurationPart.hour:
//         return timeHoursAbbreviation;
//       case DurationPart.minute:
//         return timeMinutesAbbreviation;
//       case DurationPart.second:
//         return timeSecondsAbbreviation;
//     }
//   }

//   @override
//   String getMonth(int month) {
//     switch (month) {
//       case DateTime.january:
//         return monthJanuary;
//       case DateTime.february:
//         return monthFebruary;
//       case DateTime.march:
//         return monthMarch;
//       case DateTime.april:
//         return monthApril;
//       case DateTime.may:
//         return monthMay;
//       case DateTime.june:
//         return monthJune;
//       case DateTime.july:
//         return monthJuly;
//       case DateTime.august:
//         return monthAugust;
//       case DateTime.september:
//         return monthSeptember;
//       case DateTime.october:
//         return monthOctober;
//       case DateTime.november:
//         return monthNovember;
//       case DateTime.december:
//         return monthDecember;
//       default:
//         throw ArgumentError.value(month, 'month');
//     }
//   }

//   @override
//   String getTimePartAbbreviation(TimePart part) {
//     switch (part) {
//       case TimePart.hour:
//         return timeHoursAbbreviation;
//       case TimePart.minute:
//         return timeMinutesAbbreviation;
//       case TimePart.second:
//         return timeSecondsAbbreviation;
//     }
//   }
// }
