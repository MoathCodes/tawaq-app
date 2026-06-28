import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/domain/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_mushaf_style.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/ayah_selection_actions.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

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
    final l10n = context.l10n;
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

        final mushaf = AppShortcutScope(
          autofocus: true,
          shortcuts: {
            AppShortcut.quranPageNext,
            AppShortcut.quranPagePrev,
            AppShortcut.quranPageNextSpace,
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
          },
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: ListenableBuilder(
              listenable: controller.page,
              builder: (context, _) {
                final info = controller.currentPageInfo;
                final pageNumber = info?.pageNumber ?? fallbackPage;
                final juzNumber = info?.juzNumber ?? fallbackJuz;
                final label =
                    '${l10n.quran}, ${l10n.pageJuzInfo(pageNumber, juzNumber)}';

                return QuranSemantics.mushafReadingRegion(
                  label: label,
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      NonSelectable(child: reader),
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
                );
              },
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
