// import 'package:hijri_date_time/hijri_date_time.dart';

// String _convertToHinduArabic(int number) {
//   return number
//       .toString()
//       .replaceAll('0', '٠')
//       .replaceAll('1', '١')
//       .replaceAll('2', '٢')
//       .replaceAll('3', '٣')
//       .replaceAll('4', '٤')
//       .replaceAll('5', '٥')
//       .replaceAll('6', '٦')
//       .replaceAll('7', '٧')
//       .replaceAll('8', '٨')
//       .replaceAll('9', '٩');
// }

// extension HijriDateTimeFormatting on HijriDateTime {
//   String format(bool? isArabic) {
//     final String day = isArabic == true
//         ? _convertToHinduArabic(this.day)
//         : this.day.toString();
//     final String month = isArabic == true
//         ? _convertToHinduArabic(this.month)
//         : this.month.toString();
//     final String year = isArabic == true
//         ? _convertToHinduArabic(this.year)
//         : this.year.toString();
//     return '$year/$month/$day';
//   }
// }
