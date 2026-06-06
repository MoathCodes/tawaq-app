import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Scales a ScreenUtil `.sp` value by the app-wide text scale factor.
double scaledSp(num value, double appScale) => value.sp * appScale;
