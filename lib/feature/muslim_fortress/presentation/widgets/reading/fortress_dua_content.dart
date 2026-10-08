import 'package:forui/forui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_reading_tap_region.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_layout.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_study_panel.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_mushaf_style.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_text_spans.dart';
import 'package:tawaq/theme/theme.dart';

const _kFortressAyahBaseFontSize = 32.0;

/// How [FortressDuaContent] composes thikr, virtue, and study sections.
enum FortressDuaContentMode {
  /// Category list: plain excerpt or full text (no mushaf widgets).
  previewCollapsed,

  /// Category list: expanded row with sourced virtue and benefit.
  previewExpanded,

  /// Focus reading: mushaf-backed thikr only (virtue shown separately).
  focusReading,
}

class FortressDhikrText extends StatelessWidget {
  const FortressDhikrText(
    this.text, {
    required this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    super.key,
  });
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  @override
  Widget build(BuildContext context) => Text.rich(
    fortressDhikrSpan(text, style),
    style: style,
    textDirection: TextDirection.rtl,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
  );
}

/// Unified thikr + virtue + study presentation for browse and reading flows.
class FortressDuaContent extends ConsumerWidget {
  /// Creates dua content for the given [mode].
  const new({
    required this.dua,
    required this.mode,
    this.muted = false,
    this.proseStyle,
    this.textAlign = TextAlign.center,
    super.key,
  });

  final FortressDuaItem dua;
  final FortressDuaContentMode mode;
  final bool muted;
  final TextStyle? proseStyle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (mode) {
      FortressDuaContentMode.previewCollapsed => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ThikrPreviewText(dua: dua, isExpanded: false),
          if (dua.hasDistinctVirtue) ...[
            const SizedBox(height: AppSpacing.md),
            FortressDuaVirtueLine(virtue: dua.virtue!),
          ],
        ],
      ),
      FortressDuaContentMode.previewExpanded => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ThikrPreviewText(dua: dua, isExpanded: true),
          if (dua.hasVirtue) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.theme.colors.primary.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.fortressVirtue,
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FortressDuaVirtueLine(virtue: dua.virtue!),
                ],
              ),
            ),
          ],
          if (dua.hasSource) ...[
            const SizedBox(height: 12),
            FortressReadingTapControl(
              child: FTappable(
                onPress: () => showFortressStudySheet(
                  context,
                  dua,
                  kind: FortressDetailKind.source,
                ),
                builder: (_, _, _) => Text(
                  '${context.l10n.fortressSourceReference}: ${dua.source}',
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                    height: 1.65,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      FortressDuaContentMode.focusReading when !dua.isQuranicPassage =>
        FortressDhikrText(
          dua.text,
          style:
              proseStyle ??
              context.theme.typography.body.xl3.copyWith(height: 2),
          textAlign: textAlign,
        ),
      FortressDuaContentMode.focusReading => _FortressThikrBody(
        dua: dua,
        muted: muted,
        proseStyle: proseStyle,
        textAlign: textAlign,
      ),
    };
  }
}

class _ThikrPreviewText extends StatelessWidget {
  const new({required this.dua, required this.isExpanded});

  final FortressDuaItem dua;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isQuran = dua.isQuranicPassage;
    if (isExpanded && isQuran)
      return _FortressThikrBody(
        dua: dua,
        quranFontSize: 26,
        proseStyle: theme.typography.body.lg.copyWith(
          fontFamily: FontFamily.uthmanTN,
          fontSize: 24,
          fontWeight: FontWeight.w400,
          height: 1.8,
        ),
      );

    var style = (isQuran ? theme.typography.body.sm : theme.typography.body.md)
        .copyWith(
          color: theme.colors.foreground,
          height: isQuran ? 2 : 1.75,
          fontSize: isQuran ? (isExpanded ? 22 : 20) : null,
          fontWeight: FontWeight.w400,
        );
    style = style.copyWith(
      fontFamily: isExpanded
          ? FontFamily.uthmanTN
          : FontFamily.iBMPlexSansArabic,
    );

    // Tile titles default to one line. Expanded prose must override that
    // inherited limit rather than treating Text.maxLines == null as unlimited.
    return DefaultTextStyle(
      style: DefaultTextStyle.of(context).style,
      child: FortressDhikrText(
        dua.text,
        style: style,
        textAlign: TextAlign.start,
        maxLines: isExpanded ? null : 4,
        overflow: isExpanded ? null : TextOverflow.ellipsis,
      ),
    );
  }
}

/// Virtue line constrained for focus-reading footer chrome.
class FortressFocusVirtueFooter extends StatelessWidget {
  /// Creates a virtue footer.
  const new({required this.virtue, required this.horizontalPadding, super.key});

  final String virtue;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.md,
        horizontalPadding,
        AppSpacing.sm,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kFortressReadingMaxWidth),
          child: FortressDuaVirtueLine(virtue: virtue),
        ),
      ),
    );
  }
}

/// Mushaf-backed thikr body for focus reading (Quranic passages + prose).
class _FortressThikrBody extends HookConsumerWidget {
  const new({
    required this.dua,
    this.textAlign = TextAlign.center,
    this.proseStyle,
    this.muted = false,
    this.quranFontSize,
  });

  final double? quranFontSize;
  final FortressDuaItem dua;
  final TextAlign textAlign;
  final TextStyle? proseStyle;
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mushafController = useMushafController();
    final retry = useState(0);
    final mushafZoom = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.mushafZoom ?? kMushafZoomDefault,
      ),
    );
    final ayahFontSize =
        (quranFontSize ?? _kFortressAyahBaseFontSize) * mushafZoom;
    final theme = context.theme;
    final colors = theme.colors;

    final fallbackStyle =
        proseStyle ??
        theme.typography.body.xl3.copyWith(
          fontWeight: FontWeight.w600,
          height: 2,
          color: muted ? colors.mutedForeground : colors.foreground,
        );

    if (!dua.isQuranicPassage) {
      return FortressDhikrText(
        dua.text,
        style: fallbackStyle,
        textAlign: textAlign,
      );
    }

    final ayahColor = muted ? colors.mutedForeground : colors.foreground;
    final ayahStyle = TextStyle(color: ayahColor, height: 1.6);
    final loading = SizedBox(
      height: ayahFontSize * 1.6,
      child: const Center(child: FCircularProgress.loader()),
    );
    final error = ErrorStatePanel(
      message: context.l10n.fortressLoadError,
      retryLabel: context.l10n.fortressRetry,
      onRetry: () => retry.value++,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in dua.lines) ...[
          switch (line) {
            HisnPlainLine(:final text) when text.trim().isNotEmpty =>
              FortressDhikrText(
                text,
                style: fallbackStyle,
                textAlign: textAlign,
              ),
            HisnQuranLine(:final presentation) => switch (presentation) {
              HisnQuranSingleAyah(:final range) => AyahWidget.fromSurahAyah(
                key: ValueKey((dua.contentId, range, retry.value)),
                surah: range.surah,
                ayah: range.startAyah,
                fontSize: ayahFontSize,
                style: ayahStyle,
                loadingWidget: loading,
                errorWidget: error,
              ),
              HisnQuranMushafPages(:final pages) => _FortressMushafPages(
                pages: pages,
                controller: mushafController,
                loadingWidget: loading,
              ),
              HisnQuranPassage(:final ranges) => _FortressQuranPassage(
                key: ValueKey((dua.contentId, ranges, retry.value)),
                ranges: ranges,
                controller: mushafController,
                fontSize: ayahFontSize,
                textStyle: ayahStyle,
                loadingWidget: loading,
                errorWidget: error,
              ),
            },
            _ => const SizedBox.shrink(),
          },
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _FortressMushafPages extends ConsumerWidget {
  const new({
    required this.pages,
    required this.controller,
    required this.loadingWidget,
  });

  final List<int> pages;
  final MushafReaderController controller;
  final Widget loadingWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final mushafZoom = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.mushafZoom ?? kMushafZoomDefault,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < pages.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.lg),
              QuranSemantics.mushafReadingRegion(
                label: context.l10n.pageLabel(pages[i]),
                child: Center(
                  child: SizedBox(
                    width: constraints.maxWidth.clamp(0, 640),
                    child: MushafPageRange.onPage(
                      page: pages[i],
                      controller: controller,
                      preserveMushafLineBreaks: true,
                      showSurahHeader: true,
                      showBasmalah: true,
                      loadingWidget: loadingWidget,
                      style: buildQuranMushafStyle(theme, zoom: mushafZoom),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FortressQuranPassage extends StatefulWidget {
  const new({
    required this.ranges,
    required this.controller,
    required this.fontSize,
    required this.textStyle,
    required this.loadingWidget,
    required this.errorWidget,
    super.key,
  });

  final List<HisnVerseRange> ranges;
  final MushafReaderController controller;
  final double fontSize;
  final TextStyle textStyle;
  final Widget loadingWidget;
  final Widget errorWidget;

  @override
  State<_FortressQuranPassage> createState() => _FortressQuranPassageState();
}

class _FortressQuranPassageState extends State<_FortressQuranPassage> {
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
  void didUpdateWidget(_FortressQuranPassage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ranges != widget.ranges ||
        oldWidget.controller != widget.controller) {
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
    _future = _fetchAyahs(widget.controller, widget.ranges);
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
