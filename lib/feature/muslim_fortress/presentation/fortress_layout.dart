import 'package:tawaq/theme/spacing.dart';

/// Maximum readable width for fortress thikr, virtue, and list content.
const kFortressReadingMaxWidth = 720.0;

/// Horizontal padding for focus-reading viewport by container width.
double fortressFocusHorizontalPadding(double maxWidth) {
  if (maxWidth < 480) return AppSpacing.lg;
  if (maxWidth < 640) return AppSpacing.xl;
  return AppSpacing.xxl;
}
