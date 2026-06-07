/// Shared Dorar API text artifact cleanup (pipe and slash separators).
abstract final class DorarTextCleaner {
  static final _pipeRuns = RegExp(r'\s*\|\s*');
  static final _slashRuns = RegExp('/{2,}');
  static final _loneSlashPadding = RegExp(r'\s+/\s+');
  static final _leadingPipe = RegExp(r'^\s*\|\s*');
  static final _whitespaceRuns = RegExp(r'\s+');
  static final _spaceBeforeNewline = RegExp(r'[ \t]+\n');
  static final _multiNewline = RegExp(r'\n{3,}');

  /// Replaces pipe runs with a single space.
  static String stripPipeRuns(String input) =>
      input.replaceAll(_pipeRuns, ' ');

  /// Replaces consecutive slashes with a single space.
  static String stripSlashRuns(String input) =>
      input.replaceAll(_slashRuns, ' ');

  /// Replaces padded lone slashes with a single space.
  static String stripLoneSlashPadding(String input) =>
      input.replaceAll(_loneSlashPadding, ' ');

  /// Strips a leading pipe artifact.
  static String stripLeadingPipe(String input) =>
      input.replaceAll(_leadingPipe, '');

  /// Applies standard Dorar pipe + slash cleanup in canonical order.
  static String cleanPipesAndSlashes(String input) {
    return stripLoneSlashPadding(
      stripSlashRuns(
        stripPipeRuns(input),
      ),
    );
  }

  /// Alias for [cleanPipesAndSlashes].
  static String stripArtifacts(String input) => cleanPipesAndSlashes(input);

  /// Collapses horizontal whitespace runs.
  static String collapseWhitespace(String input) {
    return input.replaceAll(_whitespaceRuns, ' ').trim();
  }

  /// Normalizes trailing spaces before newlines and caps blank-line runs.
  static String normalizeLineBreaks(String input) {
    return input
        .replaceAll(_spaceBeforeNewline, '\n')
        .replaceAll(_multiNewline, '\n\n')
        .trim();
  }

  /// Cleans metadata zone text while preserving paragraph breaks.
  static String cleanMetadataZone(String input) {
    return normalizeLineBreaks(stripArtifacts(input));
  }

  /// Cleans commentary zone text while preserving paragraph breaks.
  static String cleanCommentaryZone(String input) {
    return normalizeLineBreaks(
      stripLeadingPipe(stripArtifacts(input)),
    );
  }

  /// Collapses metadata header text to a single line for label parsing.
  static String collapseMetadataForParsing(String input) {
    return collapseWhitespace(
      stripArtifacts(input.replaceAll('\r\n', '\n').replaceAll('\n', ' ')),
    );
  }
}
