/// Qawl / divine-speech lead patterns for Arabic commentary prose.
abstract final class QawlPatterns {
  /// Arabic prefix particles that may precede qawl leads (ل، و، ب، ف، ك).
  static const arabicPrefixParticles = '[لوبفك]';

  static const _prefixClause = r'(?:[لوبفك]\s+|[لوبفك])?';
  static const _qawlPhrase =
      r'(?:قال\s+الله\s+تعالى|قول(?:ه|ها|هم)?(?:\s+تعالى)?):';

  /// Matches qawl-lead phrases at string start (for detection).
  static final qawlLeadPrefix = RegExp('^$_prefixClause$_qawlPhrase');

  /// Matches qawl-lead phrases after whitespace or at line start (for styling).
  static final qawlLeadInline = RegExp(
    '(?<=^|\\s)$_prefixClause$_qawlPhrase\\s*',
  );
}
