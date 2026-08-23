import 'package:flutter/widgets.dart';

/// A piece of text that carries an English and an Arabic variant.
///
/// Call [resolve] with a [BuildContext] to obtain the variant that matches the
/// currently active locale.
@immutable
class AboutText {
  /// Creates a localized text from explicit [en] and [ar] variants.
  const new({required this.en, required this.ar});

  /// Creates a localized text that is identical in both locales.
  const new shared(String value)
      : en = value,
        ar = value;

  /// The English variant.
  final String en;

  /// The Arabic variant.
  final String ar;

  /// Returns the variant matching the active locale of [context].
  String resolve(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
}

/// A single quick fact shown in the about header strip, e.g.
/// `Version → 1.0.0`.
@immutable
class AboutFact {
  /// Creates an about fact.
  const new({
    required this.icon,
    required this.label,
    required this.value,
  });

  /// The leading icon.
  final IconData icon;

  /// The localized field label.
  final AboutText label;

  /// The localized field value.
  final AboutText value;
}

/// A link rendered as a tappable row in the about dialog.
@immutable
class AboutLink {
  /// Creates an about link.
  const new({
    required this.icon,
    required this.label,
    required this.url,
    this.description,
  });

  /// The leading icon.
  final IconData icon;

  /// The localized link label.
  final AboutText label;

  /// The destination opened when the row is activated.
  final String url;

  /// Optional localized helper text shown beneath the label.
  final AboutText? description;
}

/// A person or organisation credited in the about dialog.
@immutable
class AboutCredit {
  /// Creates an about credit.
  const new({
    required this.icon,
    required this.name,
    this.role,
    this.url,
  });

  /// The leading icon.
  final IconData icon;

  /// The localized name.
  final AboutText name;

  /// Optional localized role or contribution.
  final AboutText? role;

  /// Optional link opened when the credit is activated.
  final String? url;
}

/// A third-party library, data source or asset the app builds on.
@immutable
class AboutAcknowledgement {
  /// Creates an about acknowledgement.
  const new({
    required this.name,
    this.description,
    this.url,
  });

  /// The name of the dependency or source.
  final String name;

  /// Optional localized description of what it provides.
  final AboutText? description;

  /// Optional link to the project or source.
  final String? url;
}

/// The full, declarative content rendered by the about dialog.
///
/// This is a plain data holder by design: edit the single const instance in
/// `lib/feature/about/data/about_info.dart` to change what the dialog shows.
/// Any list left empty hides its corresponding section.
@immutable
class AboutContent {
  /// Creates the about content.
  const new({
    required this.appName,
    required this.latinName,
    required this.version,
    required this.tagline,
    required this.description,
    this.facts = const [],
    this.links = const [],
    this.credits = const [],
    this.acknowledgements = const [],
    this.legal,
  });

  /// The app's display name (Arabic).
  final String appName;

  /// The app's Latin/transliterated name, shown beneath [appName].
  final String latinName;

  /// The version string shown in the header badge, e.g. `v1.0.0`.
  final String version;

  /// A short localized tagline shown beneath the name.
  final AboutText tagline;

  /// A localized paragraph describing the app.
  final AboutText description;

  /// Quick facts (version, release date, platform …).
  final List<AboutFact> facts;

  /// External links (website, source, contact …).
  final List<AboutLink> links;

  /// People and organisations to credit.
  final List<AboutCredit> credits;

  /// Libraries, data sources and assets to acknowledge.
  final List<AboutAcknowledgement> acknowledgements;

  /// Optional localized legal/copyright footer.
  final AboutText? legal;
}
