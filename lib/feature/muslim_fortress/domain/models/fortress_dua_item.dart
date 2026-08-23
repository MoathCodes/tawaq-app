import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// A single dhikr/supplication loaded from Hisn content.
class FortressDuaItem {
  /// Creates a dhikr item.
  const new({
    required this.contentId,
    required this.category,
    required this.text,
    required this.targetCount,
    required this.lines,
    this.source,
    this.virtue,
    this.commentary,
    this.commentaryFlags,
    this.audioUrl,
  });

  /// Hisn content id.
  final int contentId;

  /// Parent chapter title for display.
  final String category;

  /// Plain-text dhikr body.
  final String text;

  /// Repeat target (from Hisn, minimum 1).
  final int targetCount;

  /// Structured lines (prose, Quran ranges, mushaf pages).
  final List<HisnContentLine> lines;

  /// Takhreej / source reference.
  final String? source;

  /// Fadl / virtue text when present.
  final String? virtue;

  /// Loaded sharh commentary when present.
  final HisnCommentary? commentary;

  /// Lightweight flags for study affordances without loading commentary bodies.
  final HisnCommentaryFlags? commentaryFlags;

  /// Remote audio URL when present.
  final String? audioUrl;

  /// Takhreej / source reference (alias: [source]).
  String? get reference => source;

  /// Whether this thikr contains Quranic passages.
  bool get isQuranicPassage =>
      lines.any((line) => line is HisnQuranLine);

  /// Whether loaded commentary has any sharh/hadith/benefit text.
  bool get hasCommentary =>
      commentary?.isNotEmpty ?? commentaryFlags?.isNotEmpty ?? false;

  /// Whether [commentary] includes non-empty sharh.
  bool get hasSharh {
    final text = commentary?.sharh;
    if (text != null && text.trim().isNotEmpty) return true;
    return commentaryFlags?.hasSharh ?? false;
  }

  /// Whether [virtue] is present.
  bool get hasVirtue => virtue != null && virtue!.trim().isNotEmpty;

  /// Whether [commentary] includes non-empty related hadith.
  bool get hasHadith {
    final text = commentary?.hadith;
    if (text != null && text.trim().isNotEmpty) return true;
    return commentaryFlags?.hasHadith ?? false;
  }

  /// Whether [commentary] includes non-empty benefit.
  bool get hasBenefit {
    final text = commentary?.benefit;
    if (text != null && text.trim().isNotEmpty) return true;
    return commentaryFlags?.hasBenefit ?? false;
  }

  /// Sharh, hadith, benefit, or مصدر (not including الفضل).
  bool get hasStudyContent =>
      hasSharh || hasHadith || hasBenefit || hasSource;

  /// Study affordance in focus nav (sharh / hadith / benefit — not مصدر alone).
  bool get hasFocusStudyAction => hasSharh || hasHadith || hasBenefit;

  /// Labels for sections available inside on-demand study (for nav hint).
  List<String> studySectionLabels(AppLocalizations l10n) => [
    if (hasSharh) l10n.fortressSharh,
    if (hasHadith) l10n.fortressRelatedHadith,
    if (hasBenefit) l10n.fortressBenefit,
    if (hasSource) l10n.fortressSourceReference,
  ];

  /// Whether a takhreej line exists.
  bool get hasSource => reference != null && reference!.trim().isNotEmpty;

  /// Virtue, on-demand study, or both.
  bool get hasInsights => hasVirtue || hasStudyContent;

  /// First Quranic range, if any (legacy helper for simple layouts).
  HisnVerseRange? get primaryQuranRange {
    for (final line in lines) {
      if (line is HisnQuranLine && line.ranges.isNotEmpty) {
        return line.ranges.first;
      }
    }
    return null;
  }
}
