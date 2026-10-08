import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:characters/characters.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_commentary_parser.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/models/fortress_share_include.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_text_spans.dart';
import 'package:tawaq/l10n/app_localizations.dart';

class FortressBookletDetailFailure implements Exception {
  const FortressBookletDetailFailure(this.itemNumber, this.field);
  final int itemNumber;
  final FortressShareInclude field;
}

/// An immutable selected source block before pagination.
class FortressBookletBlock {
  const FortressBookletBlock({
    required this.id,
    required this.itemId,
    required this.itemNumber,
    required this.target,
    required this.heading,
    required this.text,
    this.quran = false,
    this.dhikr = false,
    this.source = false,
    this.virtue = false,
  });
  final String id;
  final int itemId;
  final int itemNumber;
  final int target;
  final String heading;
  final String text;
  final bool quran;
  final bool dhikr;
  final bool source;
  final bool virtue;
}

class FortressBookletSlice {
  const FortressBookletSlice({
    required this.block,
    required this.start,
    required this.end,
    required this.y,
    required this.heading,
    required this.style,
    required this.headingStyle,
    required this.height,
    this.sectionGap = 0,
  });
  final FortressBookletBlock block;
  final int start;
  final int end;
  final double y;
  final String heading;
  final TextStyle style;
  final TextStyle headingStyle;
  final double height;
  final double sectionGap;
  String get text => block.text.substring(start, end);
}

class FortressBookletPage {
  const FortressBookletPage(this.slices);
  final List<FortressBookletSlice> slices;
}

/// Preview and both export formats paint exactly this measured page plan.
class FortressBookletPlan {
  const FortressBookletPlan({
    required this.title,
    required this.pages,
    required this.blocks,
    required this.colors,
    required this.l10n,
    required this.appName,
  });
  static const width = 540.0;
  static const height = 675.0;
  static const margin = 36.0;
  static const bodyWidth = width - margin * 2;
  static const bodyTop = 78.0;
  static const bodyBottom = height - 48;
  final String title;
  final List<FortressBookletPage> pages;
  final List<FortressBookletBlock> blocks;
  final FColors colors;
  final AppLocalizations l10n;
  final bool appName;

  static List<FortressBookletBlock> content({
    required List<FortressDuaItem> items,
    required FortressShareOptions options,
    required Map<int, HisnCommentary?> commentary,
    required AppLocalizations l10n,
  }) {
    final result = <FortressBookletBlock>[];
    for (final (index, item) in items.indexed) {
      void add(
        String key,
        String heading,
        String text, {
        bool dhikr = false,
        bool quran = false,
        bool source = false,
        bool virtue = false,
      }) {
        if (text.trim().isEmpty) return;
        result.add(
          FortressBookletBlock(
            id: '${item.contentId}:$key',
            itemId: item.contentId,
            itemNumber: index + 1,
            target: options.contains(FortressShareInclude.repetition)
                ? item.targetCount
                : 0,
            heading: heading,
            text: text,
            dhikr: dhikr,
            quran: quran,
            source: source,
            virtue: virtue,
          ),
        );
      }

      // Resolved Quran quotations remain distinct from neighbouring prose.
      final quotes = RegExp(r'﴿[^﴾]*﴾', dotAll: true).allMatches(item.text);
      var cursor = 0;
      var part = 0;
      for (final quote in quotes) {
        if (quote.start > cursor)
          add(
            'text-${part++}',
            '',
            item.text.substring(cursor, quote.start),
            dhikr: true,
          );
        add('text-${part++}', '', quote.group(0)!, dhikr: true, quran: true);
        cursor = quote.end;
      }
      if (cursor < item.text.length)
        add(
          'text-${part++}',
          '',
          item.text.substring(cursor),
          dhikr: true,
          quran: item.isQuranicPassage && cursor == 0,
        );
      final details = commentary[item.contentId] ?? item.commentary;
      void study(
        FortressShareInclude include,
        String heading,
        String? text,
        bool available,
      ) {
        if (!options.contains(include) || !available) return;
        if (text == null || text.trim().isEmpty)
          throw FortressBookletDetailFailure(index + 1, include);
        final parsed = FortressCommentaryParser.parse(text);
        for (final (i, block) in parsed.indexed) {
          final body = [
            if (block.listNumber != null) '${block.listNumber}.',
            block.body,
            ...block.citations,
          ].join('\n');
          add('${include.name}-$i', heading, body);
        }
      }

      if (options.contains(FortressShareInclude.virtue) && item.hasVirtue)
        add('virtue', l10n.fortressVirtue, item.virtue!, virtue: true);
      if (options.contains(FortressShareInclude.source) && item.hasSource)
        add(
          'source',
          '${l10n.fortressSourceReference} [${index + 1}]',
          item.source!,
          source: true,
        );
      study(
        FortressShareInclude.sharh,
        l10n.fortressSharh,
        details?.sharh,
        item.hasSharh,
      );
      study(
        FortressShareInclude.benefit,
        l10n.fortressBenefit,
        details?.benefit,
        item.hasBenefit,
      );
      study(
        FortressShareInclude.hadith,
        l10n.fortressRelatedHadith,
        details?.hadith,
        item.hasHadith,
      );
    }
    return List.unmodifiable(result);
  }

  static Future<FortressBookletPlan> create({
    required String title,
    required List<FortressBookletBlock> blocks,
    required FColors colors,
    required AppLocalizations l10n,
    double textScale = 1,
    bool appName = true,
    bool Function()? cancelled,
  }) async {
    final pages = <FortressBookletPage>[];
    var slices = <FortressBookletSlice>[];
    var y = bodyTop;
    int? lastItem;
    final seenItems = <int>{};
    void newPage() {
      if (slices.isNotEmpty)
        pages.add(FortressBookletPage(List.unmodifiable(slices)));
      slices = [];
      y = bodyTop;
      lastItem = null;
    }

    final scale = textScale.clamp(.8, 1.6);
    final headingStyle = TextStyle(
      fontFamily: FontFamily.iBMPlexSansArabic,
      fontSize: 14,
      height: 1.5,
      color: colors.primary,
      fontWeight: FontWeight.w700,
    );
    TextStyle styleFor(FortressBookletBlock block) => TextStyle(
      fontFamily: block.quran
          ? FontFamily.uthmanicHafs
          : block.dhikr
          ? FontFamily.uthmanTN
          : FontFamily.iBMPlexSansArabic,
      fontSize:
          (block.dhikr
              ? 22
              : block.source
              ? 15
              : block.virtue
              ? 16.5
              : 18) *
          scale,
      height: block.dhikr ? 1.9 : 1.8,
      color: block.source || block.virtue
          ? colors.mutedForeground
          : colors.foreground,
    );
    String itemHeading(FortressBookletBlock block) =>
        '${block.itemNumber}.${block.target > 0 ? "  ×${block.target}" : ""}';
    for (final (blockIndex, block) in blocks.indexed) {
      if (cancelled?.call() ?? false) throw const FortressBookletCancelled();
      final style = styleFor(block);
      // Keep an entire fitting reading group together, including its source.
      if (!seenItems.contains(block.itemId) && slices.isNotEmpty) {
        var groupHeight = 0.0;
        var trailingGap = 0.0;
        var first = true;
        for (final candidate in blocks.skip(blockIndex)) {
          if (candidate.itemId != block.itemId ||
              (!candidate.dhikr && !candidate.source && !candidate.virtue))
            break;
          final heading = [
            if (first) itemHeading(candidate),
            if (candidate.heading.isNotEmpty) candidate.heading,
          ].join(' · ');
          groupHeight +=
              (candidate.source || candidate.virtue ? 12 : 0) +
              (heading.isEmpty ? 0 : _measure(heading, headingStyle) + 8) +
              _measure(candidate.text, styleFor(candidate)) +
              (candidate.dhikr ? 18 : 14);
          trailingGap = candidate.dhikr ? 18 : 14;
          first = false;
        }
        groupHeight -= trailingGap;
        if (groupHeight <= bodyBottom - bodyTop && groupHeight > bodyBottom - y)
          newPage();
      }
      final clusters = block.text.characters.toList();
      final offsets = [0];
      for (final cluster in clusters)
        offsets.add(offsets.last + cluster.length);
      var from = 0;
      while (from < clusters.length) {
        if (cancelled?.call() ?? false) throw const FortressBookletCancelled();
        final itemChanged = lastItem != block.itemId;
        final heading = [
          if (itemChanged) itemHeading(block),
          if (block.heading.isNotEmpty) block.heading,
          if (from > 0 || (itemChanged && seenItems.contains(block.itemId)))
            l10n.fortressContinued,
        ].join(' · ');
        final sectionGap = (block.source || block.virtue) ? 12.0 : 0.0;
        final headingHeight =
            sectionGap +
            (heading.isEmpty ? 0.0 : _measure(heading, headingStyle) + 8);
        final available = bodyBottom - y - headingHeight;
        if (from == 0 && slices.isNotEmpty) {
          final fullHeight = _measure(block.text, style);
          final freshHeading = [
            itemHeading(block),
            if (block.heading.isNotEmpty) block.heading,
            l10n.fortressContinued,
          ].join(' · ');
          if (fullHeight > available &&
              fullHeight +
                      _measure(freshHeading, headingStyle) +
                      8 +
                      sectionGap <=
                  bodyBottom - bodyTop) {
            newPage();
            continue;
          }
        }
        if (available < style.fontSize! * style.height! * 2 &&
            slices.isNotEmpty) {
          newPage();
          continue;
        }
        var low = from + 1;
        var high = clusters.length;
        var fit = from;
        while (low <= high) {
          final middle = (low + high) ~/ 2;
          final text = block.text.substring(offsets[from], offsets[middle]);
          if (_measure(text, style) <= available) {
            fit = middle;
            low = middle + 1;
          } else {
            high = middle - 1;
          }
        }
        if (fit == from)
          throw StateError('A glyph cannot fit in a booklet page');
        // Prefer an actual source word/paragraph boundary; grapheme splitting
        // still guarantees progress for a single oversized word.
        if (fit < clusters.length) {
          for (var i = fit; i > from + (fit - from) ~/ 2; i--) {
            if (RegExp(r'\s').hasMatch(clusters[i - 1])) {
              fit = i;
              break;
            }
          }
        }
        final text = block.text.substring(offsets[from], offsets[fit]);
        final h = _measure(text, style);
        slices.add(
          FortressBookletSlice(
            block: block,
            start: offsets[from],
            end: offsets[fit],
            y: y,
            heading: heading,
            style: style,
            headingStyle: headingStyle,
            height: h,
            sectionGap: sectionGap,
          ),
        );
        y += headingHeight + h + (block.dhikr ? 18 : 14);
        lastItem = block.itemId;
        seenItems.add(block.itemId);
        from = fit;
        if (from < clusters.length) {
          newPage();
          await Future<void>.delayed(Duration.zero);
        }
      }
      await Future<void>.delayed(Duration.zero);
    }
    newPage();
    return FortressBookletPlan(
      title: title,
      pages: List.unmodifiable(pages),
      blocks: blocks,
      colors: colors,
      l10n: l10n,
      appName: appName,
    );
  }

  static double _measure(String text, TextStyle style) {
    final painter = _painter(text, style)..layout(maxWidth: bodyWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  static TextPainter _painter(
    String text,
    TextStyle style, {
    TextAlign align = TextAlign.start,
  }) => TextPainter(
    text: TextSpan(
      text: style.fontFamily == FontFamily.uthmanicHafs
          ? fortressQuranDisplayText(text)
          : text,
      style: style,
    ),
    textDirection: TextDirection.rtl,
    textAlign: align,
    textScaler: TextScaler.noScaling,
  );

  void paint(Canvas canvas, int index) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = colors.background,
    );
    void text(
      String value,
      TextStyle style,
      Offset at, {
      double maxWidth = bodyWidth,
      TextAlign align = TextAlign.start,
    }) {
      final painter = _painter(value, style, align: align)
        ..layout(minWidth: maxWidth, maxWidth: maxWidth);
      painter.paint(canvas, at);
      painter.dispose();
    }

    final small = TextStyle(
      fontFamily: FontFamily.iBMPlexSansArabic,
      fontSize: 12,
      height: 1.4,
      color: colors.primary,
    );
    text(
      title,
      small.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      const Offset(margin, 26),
      align: TextAlign.center,
    );
    canvas.drawLine(
      const Offset(margin, 61),
      const Offset(width - margin, 61),
      Paint()
        ..color = colors.border
        ..strokeWidth = 1,
    );
    for (final slice in pages[index].slices) {
      var top = slice.y + slice.sectionGap;
      if (slice.block.source) {
        canvas.drawLine(
          Offset(width - margin - 112, slice.y + 2),
          Offset(width - margin, slice.y + 2),
          Paint()
            ..color = colors.border
            ..strokeWidth = 1,
        );
      }
      if (slice.heading.isNotEmpty) {
        text(slice.heading, slice.headingStyle, Offset(margin, top));
        top += _measure(slice.heading, slice.headingStyle) + 8;
      }
      text(slice.text, slice.style, Offset(margin, top));
    }
    canvas.drawLine(
      const Offset(margin, height - 35),
      const Offset(width - margin, height - 35),
      Paint()
        ..color = colors.border
        ..strokeWidth = 1,
    );
    text(
      l10n.fortressPagePosition(index + 1, pages.length),
      small,
      const Offset(margin, height - 26),
      align: TextAlign.center,
    );
    if (appName)
      text('تَوَّاق', small, const Offset(margin, height - 26), maxWidth: 70);
  }

  Future<Uint8List> png(int index) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(2);
    paint(canvas, index);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt() * 2, height.toInt() * 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('PNG encoding failed');
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  String get plainText => [
    title,
    for (final block in blocks)
      '${block.heading.isEmpty ? '${block.itemNumber}.${block.target > 0 ? ' ×${block.target}' : ''}' : block.heading}\n${block.text}',
  ].join('\n\n');
}

class FortressBookletCancelled implements Exception {
  const FortressBookletCancelled();
}

class FortressBookletPreview extends StatelessWidget {
  const FortressBookletPreview({
    required this.plan,
    required this.index,
    super.key,
  });
  final FortressBookletPlan plan;
  final int index;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${plan.title}. ${plan.l10n.fortressPagePosition(index + 1, plan.pages.length)}. ${plan.pages[index].slices.map((s) => s.text).join('\n')}',
    child: FittedBox(
      fit: BoxFit.contain,
      child: CustomPaint(
        size: const Size(FortressBookletPlan.width, FortressBookletPlan.height),
        painter: _PagePainter(plan, index),
      ),
    ),
  );
}

class _PagePainter extends CustomPainter {
  const _PagePainter(this.plan, this.index);
  final FortressBookletPlan plan;
  final int index;
  @override
  void paint(Canvas canvas, Size size) => plan.paint(canvas, index);
  @override
  bool shouldRepaint(_PagePainter old) =>
      old.plan != plan || old.index != index;
}
