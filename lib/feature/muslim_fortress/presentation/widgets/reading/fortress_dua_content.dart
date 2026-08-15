import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_layout.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_mushaf_style.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

const _kFortressAyahBaseFontSize = 32.0;

/// How [FortressDuaContent] composes thikr, virtue, and study sections.
enum FortressDuaContentMode {
  /// Category list: plain excerpt or full text (no mushaf widgets).
  previewCollapsed,

  /// Category list: expanded row with virtue and inline study.
  previewExpanded,

  /// Focus reading: mushaf-backed thikr only (virtue shown separately).
  focusReading,
}

/// Unified thikr + virtue + study presentation for browse and reading flows.
class FortressDuaContent extends ConsumerWidget {
  /// Creates dua content for the given [mode].
  const FortressDuaContent({
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
      FortressDuaContentMode.previewCollapsed => _ThikrPreviewText(
        dua: dua,
        isExpanded: false,
      ),
      FortressDuaContentMode.previewExpanded => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ThikrPreviewText(dua: dua, isExpanded: true),
          if (dua.hasVirtue) ...[
            const SizedBox(height: AppSpacing.md),
            FortressDuaVirtueLine(virtue: dua.virtue!),
          ],
          if (dua.hasStudyContent) ...[
            const SizedBox(height: AppSpacing.lg),
            FortressDuaStudyContent(dua: dua, compact: true),
          ],
        ],
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
  const _ThikrPreviewText({
    required this.dua,
    required this.isExpanded,
  });

  final FortressDuaItem dua;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isQuran = dua.isQuranicPassage;

    var style = theme.typography.body.sm.copyWith(
      color: isExpanded
          ? theme.colors.foreground
          : theme.colors.mutedForeground,
      height: isQuran ? 2 : 1.6,
      fontSize: isQuran ? (isExpanded ? 22 : 20) : null,
      fontWeight: isExpanded && isQuran ? FontWeight.w600 : FontWeight.w500,
    );
    if (isQuran) {
      style = style.copyWith(fontFamily: FontFamily.uthmanicHafs);
    }

    return Text(
      dua.text,
      style: style,
      textAlign: TextAlign.start,
      maxLines: isExpanded ? null : 2,
      overflow: isExpanded ? null : TextOverflow.ellipsis,
    );
  }
}

/// Virtue line constrained for focus-reading footer chrome.
class FortressFocusVirtueFooter extends StatelessWidget {
  /// Creates a virtue footer.
  const FortressFocusVirtueFooter({
    required this.virtue,
    required this.horizontalPadding,
    super.key,
  });

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
  const _FortressThikrBody({
    required this.dua,
    this.textAlign = TextAlign.center,
    this.proseStyle,
    this.muted = false,
  });

  final FortressDuaItem dua;
  final TextAlign textAlign;
  final TextStyle? proseStyle;
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mushafController = useMushafController();
    final mushafZoom = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.mushafZoom ?? kMushafZoomDefault,
      ),
    );
    final ayahFontSize = _kFortressAyahBaseFontSize * mushafZoom;
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
      return Text(
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
    final error = Text(
      dua.text,
      style: fallbackStyle,
      textAlign: textAlign,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in dua.lines) ...[
          switch (line) {
            HisnPlainLine(:final text) when text.trim().isNotEmpty => Text(
              text,
              style: fallbackStyle,
              textAlign: textAlign,
            ),
            HisnQuranLine(:final presentation) => switch (presentation) {
              HisnQuranSingleAyah(:final range) => AyahWidget.fromSurahAyah(
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
  const _FortressMushafPages({
    required this.pages,
    required this.controller,
    required this.loadingWidget,
  });

  static const _referenceWidth = 500.0;
  static const _referenceHeight = 850.0;
  static const _maxViewportHeightFraction = 0.55;

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
        final paneHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final maxPageHeight = paneHeight * _maxViewportHeightFraction;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < pages.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.lg),
              QuranSemantics.mushafReadingRegion(
                label: context.l10n.pageLabel(pages[i]),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxPageHeight),
                  child: AspectRatio(
                    aspectRatio: _referenceWidth / _referenceHeight,
                    child: MushafPage(
                      page: pages[i],
                      controller: controller,
                      hideHeader: true,
                      enableAyahHighlight: false,
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
  const _FortressQuranPassage({
    required this.ranges,
    required this.controller,
    required this.fontSize,
    required this.textStyle,
    required this.loadingWidget,
    required this.errorWidget,
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
