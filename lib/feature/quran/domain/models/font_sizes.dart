import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

enum FontSizes {
  large,
  medium,
  small,
  ;

  double get size => switch (this) {
    .small => 24.sp,
    .medium => 28.sp,
    .large => 30.sp,
  };
}
