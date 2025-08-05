// import 'package:flutter/foundation.dart';
// import 'package:hasanat/core/locale/arabic_shadcn_locale.dart';
// import 'package:shadcn_flutter/shadcn_flutter.dart';

// class ArabicShadcnDelegate implements ShadcnLocalizationsDelegate {
//   static const ShadcnLocalizationsDelegate delegate = ArabicShadcnDelegate();
//   const ArabicShadcnDelegate();
//   @override
//   Type get type => ShadcnLocalizations;

//   @override
//   bool isSupported(Locale locale) =>
//       locale.languageCode == 'en' || locale.languageCode == 'ar';

//   @override
//   Future<ShadcnLocalizations> load(Locale locale) {
//     if (locale.languageCode == 'en') {
//       return SynchronousFuture<ShadcnLocalizations>(
//           DefaultShadcnLocalizations.instance);
//     } else {
//       return SynchronousFuture<ShadcnLocalizations>(
//           ArabicShadcnLocale.instance);
//     }
//   }

//   @override
//   bool shouldReload(covariant ShadcnLocalizationsDelegate old) => false;
// }
