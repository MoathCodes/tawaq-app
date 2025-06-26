import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';

// class RTLSwapper<T> {
//   final T ltr;
//   final T rtl;
//   final WidgetRef ref;
//   const RTLSwapper(this.ref, this.ltr, this.rtl);
//   T call() {
//     final isArabic =
//         ref.watch(localeNotifierProvider).value?.countryCode == 'ar';
//     return isArabic ? rtl : ltr;
//   }
// }

extension RTLSwapperExtension on WidgetRef {
  T rtlSwap<T>(T ltr, rtl) {
    final locale = watch(localeNotifierProvider);
    final isArabic = locale.value?.languageCode == 'ar';
    return isArabic ? rtl : ltr;
  }
}
