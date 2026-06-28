import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_layout.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_dua_content.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_focus_thikr_stage.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_focus_toolbar.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_reading_nav_bar.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/use_fortress_focus_session.dart';
import 'package:tawaq/theme/theme.dart';

/// Full-screen focus reading for a fortress chapter.
class FortressFocusReadingView extends HookConsumerWidget {
  const FortressFocusReadingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(
      fortressScreenControllerProvider.select((s) => s.selectedCategory),
    );
    if (category == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final duasAsync = ref.watch(muslimFortressDuasProvider(category.chapterId));
    final initialIndex = ref.watch(
      fortressScreenControllerProvider.select((s) => s.focusStartIndex),
    );

    return duasAsync.when(
      data: (duas) => _FortressFocusReadingBody(
        category: category,
        duas: duas,
        initialIndex: initialIndex,
      ),
      loading: () => FSkeletonizer(
        child: _FortressFocusReadingBody(
          category: category,
          duas: const [],
          initialIndex: initialIndex,
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: ErrorStatePanel(
            message: l10n.fortressLoadError,
            detail: '$error',
            retryLabel: l10n.fortressRetry,
            onRetry: () => ref.invalidate(
              muslimFortressDuasProvider(category.chapterId),
            ),
          ),
        ),
      ),
    );
  }
}

class _FortressFocusReadingBody extends HookConsumerWidget {
  const _FortressFocusReadingBody({
    required this.category,
    required this.duas,
    required this.initialIndex,
  });

  final FortressCategory category;
  final List<FortressDuaItem> duas;
  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final onExit =
        ref.read(fortressScreenControllerProvider.notifier).exitFocusMode;

    if (duas.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.fortressNoAdhkarInChapter,
            style: theme.typography.body.md,
          ),
        ),
      );
    }

    final session = useFortressFocusSession(
      context: context,
      duas: duas,
      initialIndex: initialIndex,
    );
    final currentDua = duas[session.index];

    return LayoutBuilder(
      builder: (context, bodyConstraints) {
        final shortHeight = bodyConstraints.maxHeight < 560;
        final horizontalPadding =
            fortressFocusHorizontalPadding(bodyConstraints.maxWidth);

        return Scaffold(
          backgroundColor: theme.colors.background,
          body: AppShortcutScope(
            autofocus: true,
            shortcuts: const {
              AppShortcut.fortressCount,
              AppShortcut.fortressThikrNext,
              AppShortcut.fortressThikrPrev,
            },
            handlers: {
              AppShortcut.fortressCount: session.decrement,
              AppShortcut.fortressThikrNext: session.goToNext,
              AppShortcut.fortressThikrPrev: session.goToPrevious,
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FortressFocusToolbar(
                  category: category,
                  duas: duas,
                  index: session.index,
                  remaining: session.remaining,
                  isDone: session.isDone,
                  progress: session.progress,
                  counterScale: session.counterScale,
                  onExit: onExit,
                ),
                Expanded(
                  child: FortressFocusThikrStage(
                    category: category,
                    duas: duas,
                    index: session.index,
                    remaining: session.remaining,
                    isDone: session.isDone,
                    horizontalPadding: horizontalPadding,
                    slideDirection: session.slideDirection,
                    tapFeedback: session.tapFeedback,
                    onDecrement: session.decrement,
                    onNext: session.goToNext,
                    onPrevious: session.goToPrevious,
                    onHorizontalScroll: session.handleHorizontalScroll,
                    showReadingHint: !shortHeight,
                  ),
                ),
                if (!shortHeight && currentDua.hasVirtue)
                  FortressFocusVirtueFooter(
                    virtue: currentDua.virtue!,
                    horizontalPadding: horizontalPadding,
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: FortressReadingNavBar(
                      canGoPrevious: session.index > 0,
                      canGoNext: session.index < duas.length - 1,
                      onPrevious: session.goToPrevious,
                      onNext: session.goToNext,
                      studyDua: currentDua.hasFocusStudyAction
                          ? currentDua
                          : null,
                      center: Text(
                        session.isDone
                            ? l10n.fortressCompleted
                            : l10n.fortressRemainingCount(session.remaining),
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
