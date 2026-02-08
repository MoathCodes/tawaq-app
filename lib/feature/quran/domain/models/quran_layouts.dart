import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/l10n/app_localizations.dart';

/// Layout modes for reading Quran.
enum QuranReadingLayout {
  /// Single page view.
  // singlePage,

  /// Double page view.
  doublePage,

  /// Study mode with translation/tafsir.
  studyMode
  ;

  /// Returns the icon associated with this layout.
  IconData get icon {
    return switch (this) {
      // .singlePage => FIcons.book,
      .doublePage => FIcons.columns2,
      .studyMode => FIcons.panelRight,
    };
  }

  /// Returns a localized name for this layout.
  String getLocaleName(AppLocalizations locale) {
    return switch (this) {
      // .singlePage => locale.quranLayoutSinglePage,
      .doublePage => locale.quranLayoutDoublePage,
      .studyMode => locale.quranLayoutStudyMode,
    };
  }
}
