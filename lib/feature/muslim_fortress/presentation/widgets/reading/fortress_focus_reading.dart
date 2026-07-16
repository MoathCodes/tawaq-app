import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/core/widgets/reading_swipe_viewport.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_layout.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_nav_controls.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_dua_content.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
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
    final repositoryAsync = ref.watch(fortressRepositoryProvider);
    final initialIndex = ref.watch(
      fortressScreenControllerProvider.select((s) => s.focusStartIndex),
    );

    return repositoryAsync.when(
      data: (repository) => _FortressFocusReadingBody(
        category: category,
        duas: repository.loadDuas(category.chapterId),
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
            onRetry: () => ref.invalidate(fortressRepositoryProvider),
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

    final session = _useFortressFocusSession(
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
            shortcuts: {
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
                _FocusToolbar(
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
                  child: _FocusThikrStage(
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
                    child: _ReadingNavBar(
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

typedef _FortressFocusSession = ({
  int index,
  int remaining,
  bool isDone,
  double progress,
  int slideDirection,
  (Offset position, int tick)? tapFeedback,
  Animation<double> counterScale,
  void Function([Offset? localPosition]) decrement,
  VoidCallback goToNext,
  VoidCallback goToPrevious,
  void Function(double delta) handleHorizontalScroll,
});

_FortressFocusSession _useFortressFocusSession({
  required BuildContext context,
  required List<FortressDuaItem> duas,
  required int initialIndex,
}) {
  final currentIndex = useMemoized(
    () => ValueNotifier(
      initialIndex.clamp(0, duas.isEmpty ? 0 : duas.length - 1),
    ),
    [duas, initialIndex],
  );
  final remainingCounts = useMemoized(
    () => ValueNotifier(duas.map((d) => d.targetCount).toList(growable: false)),
    [duas],
  );
  useListenable(currentIndex);
  useListenable(remainingCounts);

  final index = currentIndex.value;
  final counts = remainingCounts.value;
  final currentDua = duas[index];
  final remaining = counts[index];
  final isDone = remaining <= 0;

  final advanceTimer = useRef<Timer?>(null);
  final slideDirection = useRef(1);
  final pulseController = useAnimationController(
    duration: const Duration(milliseconds: 180),
  );
  final tapFeedback = useState<(Offset position, int tick)?>(null);

  useEffect(
    () {
      return () {
        currentIndex.dispose();
        remainingCounts.dispose();
      };
    },
    [currentIndex, remainingCounts],
  );

  useEffect(
    () => () => advanceTimer.value?.cancel(),
    const [],
  );

  void goToIndex(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= duas.length) return;
    advanceTimer.value?.cancel();
    if (nextIndex != currentIndex.value) {
      slideDirection.value = nextIndex > currentIndex.value ? -1 : 1;
    }
    currentIndex.value = nextIndex;
  }

  void goToNext() {
    if (index < duas.length - 1) {
      goToIndex(index + 1);
    }
  }

  void goToPrevious() {
    if (index > 0) {
      goToIndex(index - 1);
    }
  }

  void triggerFeedback([Offset? localPosition]) {
    unawaited(
      pulseController.forward(from: 0).then((_) {
        if (context.mounted) {
          unawaited(pulseController.reverse());
        }
      }),
    );
    unawaited(HapticFeedback.lightImpact());
    if (localPosition != null) {
      tapFeedback.value = (localPosition, (tapFeedback.value?.$2 ?? 0) + 1);
    }
  }

  void decrement([Offset? localPosition]) {
    if (remaining <= 0) return;

    final next = List<int>.from(counts);
    next[index] = remaining - 1;
    remainingCounts.value = next;
    triggerFeedback(localPosition);

    if (next[index] <= 0 && index < duas.length - 1) {
      advanceTimer.value?.cancel();
      advanceTimer.value = Timer(const Duration(milliseconds: 600), () {
        if (context.mounted) {
          goToNext();
        }
      });
    }
  }

  void handleHorizontalScroll(double delta) {
    const threshold = 4.0;
    if (delta.abs() < threshold) return;
    if (delta < 0) {
      goToNext();
    } else {
      goToPrevious();
    }
  }

  final counterScaleCurve = useMemoized(
    () => CurvedAnimation(
      parent: pulseController,
      curve: Curves.easeOutCubic,
    ),
    [pulseController],
  );
  final counterScale = useMemoized(
    () => Tween<double>(begin: 1, end: 0.88).animate(counterScaleCurve),
    [counterScaleCurve],
  );
  useEffect(
    () => counterScaleCurve.dispose,
    [counterScaleCurve],
  );

  final progress = isDone
      ? 1.0
      : 1.0 - (remaining / currentDua.targetCount).clamp(0.0, 1.0);

  return (
    index: index,
    remaining: remaining,
    isDone: isDone,
    progress: progress,
    slideDirection: slideDirection.value,
    tapFeedback: tapFeedback.value,
    counterScale: counterScale,
    decrement: decrement,
    goToNext: goToNext,
    goToPrevious: goToPrevious,
    handleHorizontalScroll: handleHorizontalScroll,
  );
}

class _FocusToolbar extends StatelessWidget {
  const _FocusToolbar({
    required this.category,
    required this.duas,
    required this.index,
    required this.remaining,
    required this.isDone,
    required this.progress,
    required this.counterScale,
    required this.onExit,
  });

  final FortressCategory category;
  final List<FortressDuaItem> duas;
  final int index;
  final int remaining;
  final bool isDone;
  final double progress;
  final Animation<double> counterScale;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: theme.colors.muted.withAlpha(80),
                valueColor: AlwaysStoppedAnimation(
                  isDone
                      ? theme.colors.primary
                      : theme.colors.primary.withAlpha(200),
                ),
              );
            },
          ),
        ),
        NonSelectable(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: LayoutBuilder(
              builder: (context, toolbarConstraints) {
                final compactToolbar =
                    toolbarConstraints.maxWidth < context.theme.breakpoints.sm;

                return Row(
                  children: [
                    FortressLabeledNavButton(
                      label: l10n.fortressFinish,
                      enabled: true,
                      onPress: onExit,
                      iconOnly: compactToolbar,
                      prefix: const Icon(FLucideIcons.x, size: 18),
                      child: Text(l10n.fortressFinish),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Semantics(
                        header: true,
                        label: category.title,
                        child: Text(
                          category.title,
                          style: theme.typography.body.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      liveRegion: true,
                      label: isDone
                          ? l10n.fortressCompleted
                          : l10n.fortressRemainingCount(remaining),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ScaleTransition(
                            scale: counterScale,
                            child: Text(
                              isDone ? '✓' : '$remaining',
                              style: theme.typography.body.xl3.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1,
                                color: isDone
                                    ? theme.colors.primary
                                    : theme.colors.foreground,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${index + 1} / ${duas.length}',
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FocusThikrStage extends StatelessWidget {
  const _FocusThikrStage({
    required this.category,
    required this.duas,
    required this.index,
    required this.remaining,
    required this.isDone,
    required this.horizontalPadding,
    required this.slideDirection,
    required this.tapFeedback,
    required this.onDecrement,
    required this.onNext,
    required this.onPrevious,
    required this.onHorizontalScroll,
    this.showReadingHint = true,
  });

  final FortressCategory category;
  final List<FortressDuaItem> duas;
  final int index;
  final int remaining;
  final bool isDone;
  final double horizontalPadding;
  final int slideDirection;
  final (Offset position, int tick)? tapFeedback;
  final void Function([Offset? localPosition]) onDecrement;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final void Function(double delta) onHorizontalScroll;
  final bool showReadingHint;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final currentDua = duas[index];
    final canGoNext = index < duas.length - 1;
    final canGoPrevious = index > 0;
    const verticalPadding = AppSpacing.xl;
    final hintReserve = showReadingHint && !isDone
        ? AppSpacing.xxl + AppSpacing.md
        : AppSpacing.lg;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportMinHeight = (constraints.maxHeight -
                verticalPadding * 2 -
                hintReserve)
            .clamp(0.0, double.infinity);

        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              if (event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()) {
                onHorizontalScroll(event.scrollDelta.dx);
              }
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ReadingSwipeViewport(
                viewportMinHeight: viewportMinHeight,
                horizontalPadding: horizontalPadding,
                topPadding: verticalPadding,
                bottomPadding: verticalPadding + hintReserve,
                textDirection: kReadingPageTurnDirection,
                canGoNext: canGoNext,
                canGoPrevious: canGoPrevious,
                onNext: onNext,
                onPrevious: onPrevious,
                semanticsLabel: l10n.fortressReadingHint,
                onTapDown: onDecrement,
                child: NonSelectable(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: kFortressReadingMaxWidth,
                    ),
                    child: DirectionalContentSwitcher(
                      currentKey: index,
                      slideDirection: slideDirection,
                      child: Semantics(
                        container: true,
                        label: FortressA11y.thikrSectionLabel(
                          l10n: l10n,
                          categoryTitle: category.title,
                          index: index,
                          total: duas.length,
                          remaining: remaining,
                          targetCount: currentDua.targetCount,
                          isDone: isDone,
                        ),
                        child: FortressDuaContent(
                          dua: currentDua,
                          mode: FortressDuaContentMode.focusReading,
                          muted: isDone,
                          proseStyle: theme.typography.body.xl3.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 2,
                            color: isDone
                                ? theme.colors.mutedForeground
                                : theme.colors.foreground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showReadingHint && !isDone)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.lg,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Text(
                        l10n.fortressReadingHint,
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground.withAlpha(160),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              if (tapFeedback case (final position, final tick))
                _FocusTapRipple(
                  key: ValueKey(tick),
                  position: position,
                  color: theme.colors.primary,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FocusTapRipple extends HookWidget {
  const _FocusTapRipple({
    required this.position,
    required this.color,
    super.key,
  });

  final Offset position;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 420),
    );

    useEffect(() {
      unawaited(controller.forward(from: 0));
      return null;
    }, const []);

    final animation = useMemoized(
      () => CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ),
      [controller],
    );
    useEffect(
      () => animation.dispose,
      [animation],
    );
    final opacityAnimation = useMemoized(
      () => Tween<double>(begin: 0.45, end: 0).animate(animation),
      [animation],
    );
    final scaleAnimation = useMemoized(
      () => Tween<double>(begin: 0.35, end: 1.6).animate(animation),
      [animation],
    );

    return Positioned(
      left: position.dx - 28,
      top: position.dy - 28,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: FadeTransition(
            opacity: opacityAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(50),
                  border: Border.all(color: color.withAlpha(90)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom prev/next controls for fortress reading (RTL layout).
class _ReadingNavBar extends StatelessWidget {
  const _ReadingNavBar({
    required this.center,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    this.studyDua,
  });

  final Widget center;
  final FortressDuaItem? studyDua;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showStudy = studyDua != null && studyDua!.hasFocusStudyAction;

    return LayoutBuilder(
      builder: (context, constraints) {
        final iconOnly = constraints.maxWidth < context.theme.breakpoints.sm;

        return NonSelectable(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FortressLabeledNavButton(
                label: FortressA11y.navActionLabel(l10n, isPrevious: true),
                enabled: canGoPrevious,
                onPress: onPrevious,
                iconOnly: iconOnly,
                prefix: const Icon(FLucideIcons.chevronLeft, size: 18),
                child: Text(l10n.fortressPrevious),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showStudy) ...[
                      FortressDuaStudyNavAction(dua: studyDua!),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Semantics(
                      liveRegion: true,
                      child: center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FortressLabeledNavButton(
                label: FortressA11y.navActionLabel(l10n, isPrevious: false),
                enabled: canGoNext,
                onPress: onNext,
                iconOnly: iconOnly,
                prefix: const Icon(FLucideIcons.chevronRight, size: 18),
                child: Text(l10n.next),
              ),
            ],
          ),
        );
      },
    );
  }
}
