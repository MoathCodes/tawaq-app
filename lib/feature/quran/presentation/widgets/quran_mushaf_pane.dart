import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_mushaf_style.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/ayah_selection_actions.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Stable mushaf subtree shared across reading layouts.
///
/// Assign a stable [key] so Flutter reparents this widget when layout chrome
/// changes instead of tearing down shortcuts, semantics, and ayah actions.
class QuranMushafPane extends HookConsumerWidget {
  /// Creates a [QuranMushafPane] instance.
  const new({this.onPageChanged, super.key});

  /// Reports the settled page/spread anchor to the route owner.
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final layout = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.layout ?? QuranReadingLayout.studyMode,
      ),
    );
    final wantsDoubleSpread = layout == QuranReadingLayout.doublePage;
    final l10n = context.l10n;
    final pendingPage = useRef<int?>(null);

    void publishPendingPage() {
      final page = pendingPage.value;
      if (page == null) return;
      pendingPage.value = null;
      onPageChanged?.call(page);
    }

    void queuePage(int page) {
      pendingPage.value = page;
      // Programmatic jumpToPage can complete without a user drag. Defer one
      // frame so PageController has updated its scrolling flag first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || !controller.pageController.hasClients) return;
        if (!controller.pageController.position.isScrollingNotifier.value) {
          publishPendingPage();
        }
      });
    }

    // Bridge package session zoom (pinch / Ctrl+scroll / Ctrl+±) into the
    // persisted mushafZoom. Null means "cleared to style boost" — ignore so
    // didUpdateWidget resets after persist do not loop.
    final pendingZoom = useRef<double?>(null);
    final debouncedZoomCommit = useDebouncedCallback(() {
      final zoom = pendingZoom.value;
      if (zoom == null) return;
      pendingZoom.value = null;
      ref.read(quranScreenSettingsProvider.notifier).setMushafZoom(zoom);
    });
    useEffect(() {
      void onSessionZoomChanged() {
        final boost = controller.sessionReadingBoost.value;
        if (boost == null) return;
        pendingZoom.value = boost;
        debouncedZoomCommit();
      }

      controller.sessionReadingBoost.addListener(onSessionZoomChanged);
      return () {
        controller.sessionReadingBoost.removeListener(onSessionZoomChanged);
        debouncedZoomCommit.cancel();
      };
    }, [controller]);

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
          key: ValueKey(pagesPerViewport),
          controller: controller,
          pagesPerViewport: pagesPerViewport,
          loadingWidget: const FCircularProgress.loader(),
          pageLoadingWidget: const FCircularProgress.loader(),
          style: style,
          onAyahTap: onAyahTapped,
          onPageChanged: pagesPerViewport == 2
              ? null
              : (info) => queuePage(info.pageNumber),
          onSpreadChanged: pagesPerViewport == 2
              ? (info) => queuePage(info.$1.pageNumber)
              : null,
        );

        final mushaf = AppShortcutScope(
          autofocus: true,
          shortcuts: {
            AppShortcut.quranPageNext,
            AppShortcut.quranPagePrev,
            AppShortcut.quranPageNextSpace,
            AppShortcut.quranZoomIn,
            AppShortcut.quranZoomOut,
            AppShortcut.quranZoomReset,
          },
          handlers: {
            AppShortcut.quranPageNext: () => unawaited(
              controller.animateToPage(controller.currentPage + 1),
            ),
            AppShortcut.quranPagePrev: () => unawaited(
              controller.animateToPage(controller.currentPage - 1),
            ),
            AppShortcut.quranPageNextSpace: () => unawaited(
              controller.animateToPage(controller.currentPage + 1),
            ),
            // Package CallbackShortcuts usually win when the reader is focused;
            // these handlers keep the cheatsheet live and cover edge cases.
            AppShortcut.quranZoomIn: () => controller.nudgeReadingBoost(
              0.04,
              scale: style.scale,
            ),
            AppShortcut.quranZoomOut: () => controller.nudgeReadingBoost(
              -0.04,
              scale: style.scale,
            ),
            AppShortcut.quranZoomReset: () {
              debouncedZoomCommit.cancel();
              pendingZoom.value = null;
              ref
                  .read(quranScreenSettingsProvider.notifier)
                  .setMushafZoom(kMushafZoomFitPage);
              controller.resetSessionReadingBoost();
            },
          },
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            // Only the a11y label needs page notifies — keep the reader stack
            // as ListenableBuilder.child so page changes do not rebuild it.
            child: ListenableBuilder(
              listenable: controller.page,
              builder: (context, child) {
                final info = controller.currentPageInfo;
                final pageNumber = info?.pageNumber ?? controller.currentPage;
                final juzNumber = info?.juzNumber ?? 1;
                final label =
                    '${l10n.quran}, ${l10n.pageJuzInfo(pageNumber, juzNumber)}';

                return QuranSemantics.mushafReadingRegion(
                  label: label,
                  child: child!,
                );
              },
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  NotificationListener<ScrollEndNotification>(
                    onNotification: (_) {
                      publishPendingPage();
                      return false;
                    },
                    child: NonSelectable(child: reader),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpacing.lg,
                    child: Align(
                      alignment: _ayahActionsAlignment(context, layout),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: layout == QuranReadingLayout.studyMode
                              ? AppSpacing.lg
                              : 0,
                        ),
                        child: const AyahSelectionActionsBar(),
                      ),
                    ),
                  ),
                ],
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

/// Study mode pins the bar to the mushaf pane's outer edge (away from the
/// study panel). Double-page mode keeps it centered over the spread.
Alignment _ayahActionsAlignment(
  BuildContext context,
  QuranReadingLayout layout,
) {
  if (layout != QuranReadingLayout.studyMode) {
    return Alignment.bottomCenter;
  }

  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return isArabic ? Alignment.bottomLeft : Alignment.bottomRight;
}
