import 'package:tawaq/feature/about/domain/models/about_content.dart';

/// Localized labels for the about dialog's own chrome.
///
/// These live in-feature (rather than in the app-wide ARB files) so the whole
/// About feature stays self-contained and trivial to edit alongside its
/// content in `about_info.dart`.
abstract final class AboutStrings {
  /// Dialog and section title.
  static const title = AboutText(en: 'About', ar: 'عن التطبيق');

  /// Heading above the links section.
  static const links = AboutText(en: 'Links', ar: 'روابط');

  /// Heading above the credits section.
  static const credits = AboutText(en: 'Credits', ar: 'فريق العمل');

  /// Heading above the acknowledgements section.
  static const acknowledgements =
      AboutText(en: 'Acknowledgements', ar: 'شكر وتقدير');

  /// Accessibility/tooltip label for the close button.
  static const close = AboutText(en: 'Close', ar: 'إغلاق');

  /// Toast shown after a link is copied to the clipboard.
  static const linkCopied =
      AboutText(en: 'Link copied to clipboard', ar: 'تم نسخ الرابط');
}
