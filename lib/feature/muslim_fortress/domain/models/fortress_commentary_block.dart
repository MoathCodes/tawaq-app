/// Parsed commentary segment (intro prose or a numbered list item).
class FortressCommentaryBlock {
  /// Creates a commentary block.
  const FortressCommentaryBlock({
    required this.body,
    this.listNumber,
    this.citations = const [],
  });

  /// Optional list marker (`7` in `7- قوله: …`).
  final int? listNumber;

  /// Main prose with `/55` citation markers removed.
  final String body;

  /// Source lines extracted from `/55 … /55` pairs.
  final List<String> citations;
}
