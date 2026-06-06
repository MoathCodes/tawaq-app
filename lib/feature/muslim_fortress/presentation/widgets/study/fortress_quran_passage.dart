import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_mushaf_controller_provider.dart';

/// Renders a multi-ayah Quranic passage as one continuous glyph flow.
class FortressQuranPassage extends ConsumerStatefulWidget {
  /// Creates a passage widget.
  const FortressQuranPassage({
    required this.ranges,
    required this.fontSize,
    required this.textStyle,
    required this.loadingWidget,
    required this.errorWidget,
    super.key,
  });

  /// Verse ranges to render in order.
  final List<HisnVerseRange> ranges;

  /// Base font size for ayah glyphs.
  final double fontSize;

  /// User style applied to each ayah span.
  final TextStyle textStyle;

  /// Shown while ayahs load.
  final Widget loadingWidget;

  /// Shown when loading fails.
  final Widget errorWidget;

  @override
  ConsumerState<FortressQuranPassage> createState() =>
      _FortressQuranPassageState();
}

class _FortressQuranPassageState extends ConsumerState<FortressQuranPassage> {
  late Future<List<Ayah>> _future = Future.value(const []);
  var _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadAyahs();
      _initialized = true;
    }
  }

  @override
  void didUpdateWidget(FortressQuranPassage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ranges != widget.ranges) {
      _loadAyahs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ayah>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget;
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return widget.errorWidget;
        }

        final spans = <InlineSpan>[];
        for (final ayah in snapshot.data!) {
          final style = MushafTextStyleMerger.mergeAyahStyle(
            userStyle: widget.textStyle,
            pageNumber: ayah.page,
            baseSize: widget.fontSize,
          );
          spans.add(TextSpan(text: ayah.codeV4, style: style));
        }

        return RichText(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          locale: const Locale('ar'),
          text: TextSpan(children: spans),
        );
      },
    );
  }

  void _loadAyahs() {
    final controller = ref.read(fortressMushafControllerProvider);
    _future = _fetchAyahs(controller, widget.ranges);
  }
}

Future<List<Ayah>> _fetchAyahs(
  MushafReaderController controller,
  List<HisnVerseRange> ranges,
) async {
  final ayahs = <Ayah>[];

  for (final range in ranges) {
    for (var ayah = range.startAyah; ayah <= range.endAyah; ayah++) {
      ayahs.add(await controller.getAyahBySurah(range.surah, ayah));
    }
  }

  return ayahs;
}
