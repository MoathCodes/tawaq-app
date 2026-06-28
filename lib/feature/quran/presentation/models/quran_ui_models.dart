import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/quran/domain/models/quran_ui_models.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Export width for verse share images.
const double kAyahShareCardWidth = 480;

/// Presentation helpers for [QuranReadingLayout].
extension QuranReadingLayoutUi on QuranReadingLayout {
  /// Returns the icon associated with this layout.
  IconData get icon {
    return switch (this) {
      QuranReadingLayout.doublePage => FLucideIcons.columns2,
      QuranReadingLayout.studyMode => FLucideIcons.panelRight,
    };
  }

  /// Returns a localized name for this layout.
  String getLocaleName(AppLocalizations locale) {
    return switch (this) {
      QuranReadingLayout.doublePage => locale.quranLayoutDoublePage,
      QuranReadingLayout.studyMode => locale.quranLayoutStudyMode,
    };
  }
}
