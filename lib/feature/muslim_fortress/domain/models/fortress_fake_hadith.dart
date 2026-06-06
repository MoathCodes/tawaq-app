/// A known weak or fabricated hadith warning from the Hisn database.
class FortressFakeHadith {
  /// Creates a fake-hadith entry.
  const FortressFakeHadith({
    required this.id,
    required this.text,
    required this.darga,
    required this.source,
  });

  /// Hisn fake-hadith row id.
  final int id;

  /// Warning text.
  final String text;

  /// Grade label from Hisn (Arabic).
  final String darga;

  /// Source citation when present.
  final String source;
}
