import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/layout/persisted_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/domain/models/quran_layouts.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/quran/presentation/widgets/mushaf_page_shortcut_scope.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/quran_selected_ayah_actions.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

const _kResizableSpacer = 20.0;
const _kStudyPanelMaxExtent = 480.0;

/// Resolves study-panel and mushaf pane widths for [StudyModeLayout].
({
  double sideExtent,
  double mainExtent,
  double sideMin,
  double mainMin,
  double sideMax,
}) _resolveStudySplitExtents({
  required double totalWidth,
  required double sideWidth,
}) {
  final available =
      (totalWidth - _kResizableSpacer).clamp(0.0, double.infinity);
  if (available <= 0) {
    return (
      sideExtent: 0,
      mainExtent: 0,
      sideMin: 0,
      mainMin: 0,
      sideMax: 0,
    );
  }

  final sideMin = kStudyPanelMinExtent.clamp(0.0, available);
  final mainMin = kMushafPaneMinExtent.clamp(0.0, available - sideMin);
  final sideMax = math
      .min(_kStudyPanelMaxExtent, available * 0.45)
      .clamp(sideMin, available - mainMin);

  final extents = resolveSplitExtents(
    totalWidth: available,
    sideWidth: sideWidth,
    sideMin: sideMin,
    mainMin: mainMin,
    sideMax: sideMax,
  );

  return (
    sideExtent: extents.sideExtent,
    mainExtent: extents.mainExtent,
    sideMin: sideMin,
    mainMin: mainMin,
    sideMax: sideMax,
  );
}

/// Stable mushaf subtree shared across reading layouts.
///
/// Assign a stable [key] so Flutter reparents this widget when layout chrome
/// changes instead of tearing down shortcuts, semantics, and ayah actions.
class QuranMushafPane extends HookConsumerWidget {
  /// Creates a [QuranMushafPane] instance.
  const QuranMushafPane({
    required this.controller,
    required this.layout,
    required this.buildStyle,
    required this.onPageChanged,
    required this.onAyahTapped,
    super.key,
  });

  /// The mushaf reader controller.
  final MushafReaderController controller;

  /// Active reading layout (single-page vs two-page reader).
  final QuranReadingLayout layout;

  /// Function to build the mushaf style.
  final MushafStyle Function(FThemeData, [QuranTextScale]) buildStyle;

  /// Callback when page changes.
  final void Function(MushafPageInfo) onPageChanged;

  /// Callback when an ayah is tapped.
  final void Function(Ayah) onAyahTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetViewport = layout == QuranReadingLayout.doublePage ? 2 : 1;
    useEffect(() {
      if (controller.pagesPerViewport != targetViewport) {
        controller.pagesPerViewport = targetViewport;
      }
      return null;
    }, [targetViewport]);

    final theme = context.theme;
    final textScale = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.quranTextScale ?? QuranTextScale.medium,
      ),
    );
    final style = buildStyle(theme, textScale);

    final reader = layout == QuranReadingLayout.doublePage
        ? MushafTwoPageReader(
            controller: controller,
            loadingWidget: const FCircularProgress.loader(),
            pageLoadingWidget: const FCircularProgress.loader(),
            style: style,
            onAyahTap: onAyahTapped,
            onPageChanged: (info) => onPageChanged(info.$1),
          )
        : MushafReader(
            controller: controller,
            loadingWidget: const FCircularProgress.loader(),
            pageLoadingWidget: const FCircularProgress.loader(),
            style: style,
            onPageChanged: onPageChanged,
            onAyahTap: onAyahTapped,
          );

    return MushafPageShortcutScope(
      controller: controller,
      child: _MushafReadingSemantics(
        child: QuranReaderWithAyahActions(
          controller: controller,
          layout: layout,
          reader: NonSelectable(child: reader),
        ),
      ),
    );
  }
}

/// Single page layout for the Quran reader.
class SinglePageLayout extends StatelessWidget {
  /// Creates a [SinglePageLayout] instance.
  const SinglePageLayout({required this.mushaf, super.key});

  /// The shared mushaf reading pane.
  final Widget mushaf;

  @override
  Widget build(BuildContext context) {
    return StaticCard(child: mushaf);
  }
}

/// Double page layout for the Quran reader.
class DoublePageLayout extends StatelessWidget {
  /// Creates a [DoublePageLayout] instance.
  const DoublePageLayout({required this.mushaf, super.key});

  /// The shared mushaf reading pane.
  final Widget mushaf;

  @override
  Widget build(BuildContext context) {
    return StaticCard(child: mushaf);
  }
}

/// Study mode layout for the Quran reader with a side panel.
class StudyModeLayout extends ConsumerWidget {
  /// Creates a [StudyModeLayout] instance.
  const StudyModeLayout({
    required this.controller,
    required this.mushaf,
    super.key,
  });

  /// The mushaf reader controller (for the study side panel).
  final MushafReaderController controller;

  /// The shared mushaf reading pane.
  final Widget mushaf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textDirection = Directionality.of(context);
    final isArabic = textDirection == TextDirection.rtl;

    final panel = RepaintBoundary(
      child: Directionality(
        textDirection: textDirection,
        child: StudyPanel(controller: controller),
      ),
    );

    final content = StaticCard(
      child: Center(child: mushaf),
    );

    final sidePanelWidth = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.sidePanelWidth ?? 350,
      ),
    );

    return PersistedHorizontalSplitPane(
      sidePanelWidth: sidePanelWidth,
      sideRegionIndex: isArabic ? 1 : 0,
      resolve: ({required totalWidth, required sideWidth}) {
        final resolved = _resolveStudySplitExtents(
          totalWidth: totalWidth,
          sideWidth: sideWidth,
        );
        return (
          sideExtent: resolved.sideExtent,
          mainExtent: resolved.mainExtent,
          sideMin: resolved.sideMin,
          mainMin: resolved.mainMin,
        );
      },
      onSidePanelWidthChanged: (width) => ref
          .read(quranScreenSettingsProvider.notifier)
          .setSidePanelWidth(width),
      sidePane: Padding(
        padding: EdgeInsetsDirectional.only(
          end: isArabic ? 0 : 8,
          start: isArabic ? 8 : 0,
        ),
        child: panel,
      ),
      mainPane: Padding(
        padding: EdgeInsetsDirectional.only(
          end: isArabic ? 8 : 0,
          start: isArabic ? 0 : 8,
        ),
        child: content,
      ),
    );
  }
}

/// Announces the mushaf page region without per-ayah semantics.
class _MushafReadingSemantics extends ConsumerWidget {
  const _MushafReadingSemantics({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pageNumber = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.pageInfo.pageNumber ?? 1,
      ),
    );
    final juzNumber = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.pageInfo.juzNumber ?? 1,
      ),
    );
    final label =
        '${l10n.quran}, ${l10n.pageJuzInfo(pageNumber, juzNumber)}';

    return QuranSemantics.mushafReadingRegion(label: label, child: child);
  }
}
