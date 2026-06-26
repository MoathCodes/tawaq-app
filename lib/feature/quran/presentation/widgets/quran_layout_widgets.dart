import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/layout/collapsible_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/side_panel_ui_state.dart';
import 'package:tawaq/core/layout/split_extent_resolver.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/domain/models/quran_layouts.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_mushaf_style.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/mushaf_page_shortcut_scope.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/quran_selected_ayah_actions.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

const _kResizableSpacer = 20.0;
const _kStudyPanelMaxExtent = 480.0;
const _kStackedStudyPanelMaxHeight = 360.0;
const _kPagePersistDebounce = Duration(milliseconds: 400);

/// Stable mushaf subtree shared across reading layouts.
///
/// Assign a stable [key] so Flutter reparents this widget when layout chrome
/// changes instead of tearing down shortcuts, semantics, and ayah actions.
class QuranMushafPane extends HookConsumerWidget {
  /// Creates a [QuranMushafPane] instance.
  const QuranMushafPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final layout = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.layout ?? QuranReadingLayout.studyMode,
      ),
    );
    final wantsDoubleSpread = layout == QuranReadingLayout.doublePage;

    final pendingPageInfo = useRef<MushafPageInfo?>(null);
    final persistTimer = useRef<Timer?>(null);

    void flushPagePersist() {
      persistTimer.value?.cancel();
      persistTimer.value = null;
      final info = pendingPageInfo.value;
      if (info == null) return;
      pendingPageInfo.value = null;
      ref.read(quranScreenSettingsProvider.notifier).commitSlimPageInfo(info);
    }

    void schedulePagePersist(MushafPageInfo info) {
      pendingPageInfo.value = info;
      persistTimer.value?.cancel();
      persistTimer.value = Timer(_kPagePersistDebounce, flushPagePersist);
    }

    useEffect(() {
      return () {
        persistTimer.value?.cancel();
        final info = pendingPageInfo.value;
        if (info != null) {
          ref
              .read(quranScreenSettingsProvider.notifier)
              .commitSlimPageInfo(info);
        }
      };
    }, const []);

    void onAyahTapped(Ayah info) {
      toggleQuranAyahSelection(ref, info);
    }

    final style = ref.watch(mushafStyleProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canFitDoubleSpread =
            constraints.maxWidth >= 2 * kMushafPaneMinExtent;
        final pagesPerViewport = wantsDoubleSpread && canFitDoubleSpread
            ? 2
            : 1;

        final reader = MushafReader(
          controller: controller,
          pagesPerViewport: pagesPerViewport,
          loadingWidget: const FCircularProgress.loader(),
          pageLoadingWidget: const FCircularProgress.loader(),
          style: style,
          onAyahTap: onAyahTapped,
          onPageChanged: pagesPerViewport == 2 ? null : schedulePagePersist,
          onSpreadChanged: pagesPerViewport == 2
              ? (info) => schedulePagePersist(info.$1)
              : null,
        );

        final mushaf = MushafPageShortcutScope(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: _MushafReadingSemantics(
              child: QuranReaderWithAyahActions(
                reader: NonSelectable(child: reader),
              ),
            ),
          ),
        );

        if (wantsDoubleSpread && !canFitDoubleSpread) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: FAlert(
                  icon: const Icon(FLucideIcons.info, size: 16),
                  title: Text(
                    context.l10n.quranDoublePageWidthFallback,
                    style: context.theme.typography.body.sm,
                  ),
                ),
              ),
              Expanded(child: mushaf),
            ],
          );
        }

        return mushaf;
      },
    );
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
    return mushaf;
  }
}

/// Study mode layout for the Quran reader with a side panel.
class StudyModeLayout extends ConsumerWidget {
  /// Creates a [StudyModeLayout] instance.
  const StudyModeLayout({
    required this.mushaf,
    super.key,
  });

  /// The shared mushaf reading pane.
  final Widget mushaf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textDirection = Directionality.of(context);
    final isRtl = textDirection == TextDirection.rtl;

    final panel = RepaintBoundary(
      child: Directionality(
        textDirection: textDirection,
        child: const StudyPanel(),
      ),
    );

    final content = Center(child: mushaf);

    final sidePanelRatio = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.sidePanelRatio ?? SidePanelDefaults.quranRatio,
      ),
    );
    final collapsed = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.sidePanelCollapsed ?? SidePanelDefaults.collapsed,
      ),
    );
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        collapsed ? 0 : AppSpacing.lg,
        0,
        AppSpacing.lg,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final totalHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;
          final useSplit = canUseHorizontalSplit(
            containerWidth: totalWidth,
            sideMin: kStudyPanelMinExtent,
            mainMin: kMushafPaneMinExtent,
            spacer: _kResizableSpacer,
          );

          if (!useSplit) {
            final studyHeight = _kStackedStudyPanelMaxHeight.clamp(
              0.0,
              totalHeight * 0.45,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpacing.sm,
                    ),
                    child: content,
                  ),
                ),
                SizedBox(
                  height: studyHeight,
                  child: panel,
                ),
              ],
            );
          }

          return _StudySplitAutoCollapse(
            containerWidth: totalWidth,
            collapsed: collapsed,
            child: CollapsibleHorizontalSplitPane(
              sidePanelRatio: sidePanelRatio,
              sideRegionIndex: isRtl ? 1 : 0,
              collapsed: collapsed,
              onCollapsedChanged: (value) => ref
                  .read(quranScreenSettingsProvider.notifier)
                  .setSidePanelCollapsed(collapsed: value),
              expandSemanticLabel: l10n.expandPanel,
              collapseSemanticLabel: l10n.collapsePanel,
              resolve: ({required totalWidth, required sideWidth}) =>
                  resolveFeatureSplitExtents(
                    totalWidth: totalWidth,
                    sideWidth: sideWidth,
                    sideMin: kStudyPanelMinExtent,
                    mainMin: kMushafPaneMinExtent,
                    sideMaxFraction: 0.45,
                    sideMaxPixels: _kStudyPanelMaxExtent,
                    spacer: _kResizableSpacer,
                  ),
              onSidePanelRatioChanged: (ratio) => ref
                  .read(quranScreenSettingsProvider.notifier)
                  .setSidePanelRatio(ratio),
              sidePane: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: isRtl ? 0 : AppSpacing.sm,
                  start: isRtl ? AppSpacing.sm : 0,
                ),
                child: panel,
              ),
              mainPane: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: isRtl ? AppSpacing.sm : 0,
                  start: isRtl ? 0 : AppSpacing.sm,
                ),
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Collapses an expanded study side panel when the split area becomes tight.
class _StudySplitAutoCollapse extends HookConsumerWidget {
  const _StudySplitAutoCollapse({
    required this.containerWidth,
    required this.collapsed,
    required this.child,
  });

  final double containerWidth;
  final bool collapsed;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      if (collapsed) return null;
      final tightWidth = minSplitContainerWidth(
        sideMin: kStudyPanelMinExtent,
        mainMin: kMushafPaneMinExtent,
        spacer: _kResizableSpacer,
      );
      if (containerWidth < tightWidth + 64) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ref
              .read(quranScreenSettingsProvider.notifier)
              .setSidePanelCollapsed(collapsed: true);
        });
      }
      return null;
    }, [containerWidth, collapsed]);

    return child;
  }
}

/// Announces the mushaf page region without per-ayah semantics.
class _MushafReadingSemantics extends ConsumerWidget {
  const _MushafReadingSemantics({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(quranMushafControllerProvider);
    final fallbackPage = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.pageInfo.pageNumber ?? 1,
      ),
    );
    final fallbackJuz = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.pageInfo.juzNumber ?? 1,
      ),
    );

    return ListenableBuilder(
      listenable: controller.page,
      builder: (context, _) {
        final info = controller.currentPageInfo;
        final pageNumber = info?.pageNumber ?? fallbackPage;
        final juzNumber = info?.juzNumber ?? fallbackJuz;
        final label =
            '${l10n.quran}, ${l10n.pageJuzInfo(pageNumber, juzNumber)}';

        return QuranSemantics.mushafReadingRegion(label: label, child: child);
      },
    );
  }
}

/// Gates mushaf content until the reader library has initialized.
class QuranMushafInitGate extends ConsumerWidget {
  /// Creates [QuranMushafInitGate].
  const QuranMushafInitGate({required this.child, super.key});

  /// Content shown once [mushafLibraryInitProvider] completes.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(mushafLibraryInitProvider);
    return init.when(
      loading: () => const Center(child: FCircularProgress.loader()),
      error: (error, _) => Center(child: Text('$error')),
      data: (_) => child,
    );
  }
}
