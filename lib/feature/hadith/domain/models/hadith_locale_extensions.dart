import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Localized labels for [SearchMethod] values.
extension SearchMethodLocale on SearchMethod {
  /// Returns the localized name for this search method.
  String getLocaleName(AppLocalizations l10n) {
    return switch (this) {
      SearchMethod.allWords => l10n.hadithSearchMethodAllWords,
      SearchMethod.anyWord => l10n.hadithSearchMethodAnyWord,
      SearchMethod.exactMatch => l10n.hadithSearchMethodExactMatch,
    };
  }
}

/// Localized record scopes, distinct from explanation prose search.
extension HadithTypeLocale on HadithTypeFilter {
  String getLocaleName(AppLocalizations l10n) => switch (this) {
    HadithTypeFilter.marfoo => l10n.hadithTypeMarfoo,
    HadithTypeFilter.qudsi => l10n.hadithTypeQudsi,
    HadithTypeFilter.companionAthar => l10n.hadithTypeCompanionAthar,
    HadithTypeFilter.withExplanation => l10n.hadithTypeWithExplanation,
  };
}

/// Localized labels for [HadithDegree] values.
extension HadithDegreeLocale on HadithDegree {
  /// Returns the localized name for this hadith degree filter.
  String getLocaleName(AppLocalizations l10n) {
    return switch (this) {
      HadithDegree.all => l10n.hadithDegreeAll,
      HadithDegree.authenticHadith => l10n.hadithDegreeAuthenticHadith,
      HadithDegree.authenticChain => l10n.hadithDegreeAuthenticChain,
      HadithDegree.weakHadith => l10n.hadithDegreeWeakHadith,
      HadithDegree.weakChain => l10n.hadithDegreeWeakChain,
    };
  }
}
