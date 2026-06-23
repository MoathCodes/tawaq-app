import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_scope.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/core/widgets/reading_swipe_viewport.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_reading_nav_bar.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_thikr_body.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/theme/theme.dart';

/// Maximum readable width for focus-reading thikr and virtue lines.
const kFortressReadingMaxWidth = 720.0;

class FortressFocusReadingView extends HookConsumerWidget {
  const FortressFocusReadingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(fortressSelectedCategoryProvider);
    if (category == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final duasAsync = ref.watch(muslimFortressDuasProvider(category.chapterId));
    final initialIndex = ref.watch(fortressFocusStartIndexProvider);

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
      () =>
          () => advanceTimer.value?.cancel(),
      const [],
    );

    void goToIndex(int index) {
      if (index < 0 || index >= duas.length) return;
      advanceTimer.value?.cancel();
      if (index != currentIndex.value) {
        slideDirection.value = index > currentIndex.value ? -1 : 1;
      }
      currentIndex.value = index;
    }

    void goToNext() {
      if (currentIndex.value < duas.length - 1) {
        goToIndex(currentIndex.value + 1);
      }
    }

    void goToPrevious() {
      if (currentIndex.value > 0) {
        goToIndex(currentIndex.value - 1);
      }
    }

    void advanceToNext() => goToNext();

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
      final index = currentIndex.value;
      final remaining = remainingCounts.value[index];
      if (remaining <= 0) return;

      final next = List<int>.from(remainingCounts.value);
      next[index] = remaining - 1;
      remainingCounts.value = next;
      triggerFeedback(localPosition);

      if (next[index] <= 0 && index < duas.length - 1) {
        advanceTimer.value?.cancel();
        advanceTimer.value = Timer(const Duration(milliseconds: 600), () {
          if (context.mounted) {
            advanceToNext();
          }
        });
      }
    }

    void handleHorizontalScroll(double delta) {
      const threshold = 4.0;
      if (delta.abs() < threshold) return;
      // Match kReadingPageTurnDirection: scroll left = next.
      if (delta < 0) {
        goToNext();
      } else {
        goToPrevious();
      }
    }

    final counterScale = Tween<double>(begin: 1, end: 0.88).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeOutCubic),
    );

    return LayoutBuilder(
      builder: (context, bodyConstraints) {
        final shortHeight = bodyConstraints.maxHeight < 560;

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
              AppShortcut.fortressCount: decrement,
              AppShortcut.fortressThikrNext: goToNext,
              AppShortcut.fortressThikrPrev: goToPrevious,
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FortressFocusProgressBar(
                  currentIndex: currentIndex,
                  remainingCounts: remainingCounts,
                  duas: duas,
                ),
                _FortressFocusToolbar(
                  category: category,
                  duas: duas,
                  currentIndex: currentIndex,
                  remainingCounts: remainingCounts,
                  counterScale: counterScale,
                  onExit: onExit,
                ),
                Expanded(
                  child: _FortressFocusThikrPane(
                    category: category,
                    duas: duas,
                    currentIndex: currentIndex,
                    remainingCounts: remainingCounts,
                    slideDirection: slideDirection,
                    tapFeedback: tapFeedback.value,
                    onDecrement: decrement,
                    onNext: goToNext,
                    onPrevious: goToPrevious,
                    onHorizontalScroll: handleHorizontalScroll,
                    showReadingHint: !shortHeight,
                  ),
                ),
                if (!shortHeight)
                  ValueListenableBuilder<int>(
                    valueListenable: currentIndex,
                    builder: (context, index, _) {
                      final currentDua = duas[index];
                      if (!currentDua.hasVirtue) return const SizedBox.shrink();

                      return LayoutBuilder(
                        builder: (context, virtueConstraints) {
                          final horizontalPadding =
                              virtueConstraints.maxWidth < 480
                              ? AppSpacing.lg
                              : virtueConstraints.maxWidth < 640
                              ? AppSpacing.xl
                              : AppSpacing.xxl;

                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              AppSpacing.md,
                              horizontalPadding,
                              AppSpacing.sm,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: kFortressReadingMaxWidth,
                                ),
                                child: FortressDuaVirtueLine(
                                  virtue: currentDua.virtue!,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ValueListenableBuilder<int>(
                  valueListenable: currentIndex,
                  builder: (context, index, _) {
                    return ValueListenableBuilder<List<int>>(
                      valueListenable: remainingCounts,
                      builder: (context, counts, _) {
                        final currentDua = duas[index];
                        final remaining = counts[index];
                        final isDone = remaining <= 0;

                        return SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.sm,
                              AppSpacing.lg,
                              AppSpacing.lg,
                            ),
                            child: FortressReadingNavBar(
                              canGoPrevious: index > 0,
                              canGoNext: index < duas.length - 1,
                              onPrevious: goToPrevious,
                              onNext: goToNext,
                              studyDua: currentDua.hasFocusStudyAction
                                  ? currentDua
                                  : null,
                              center: Text(
                                isDone
                                    ? l10n.fortressCompleted
                                    : l10n.fortressRemainingCount(remaining),
                                style: theme.typography.body.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FortressFocusProgressBar extends StatelessWidget {
  const _FortressFocusProgressBar({
    required this.currentIndex,
    required this.remainingCounts,
    required this.duas,
  });

  final ValueNotifier<int> currentIndex;
  final ValueNotifier<List<int>> remainingCounts;
  final List<FortressDuaItem> duas;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FortressExcludeDecorative(
      child: ValueListenableBuilder<int>(
        valueListenable: currentIndex,
        builder: (context, index, _) {
          return ValueListenableBuilder<List<int>>(
            valueListenable: remainingCounts,
            builder: (context, counts, _) {
              final currentDua = duas[index];
              final remaining = counts[index];
              final isDone = remaining <= 0;
              final progress = isDone
                  ? 1.0
                  : 1.0 - (remaining / currentDua.targetCount).clamp(0.0, 1.0);

              return TweenAnimationBuilder<double>(
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
              );
            },
          );
        },
      ),
    );
  }
}

class _FortressFocusToolbar extends StatelessWidget {
  const _FortressFocusToolbar({
    required this.category,
    required this.duas,
    required this.currentIndex,
    required this.remainingCounts,
    required this.counterScale,
    required this.onExit,
  });

  final FortressCategory category;
  final List<FortressDuaItem> duas;
  final ValueNotifier<int> currentIndex;
  final ValueNotifier<List<int>> remainingCounts;
  final Animation<double> counterScale;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return NonSelectable(
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
                ValueListenableBuilder<int>(
                  valueListenable: currentIndex,
                  builder: (context, index, _) {
                    return ValueListenableBuilder<List<int>>(
                      valueListenable: remainingCounts,
                      builder: (context, counts, _) {
                        final remaining = counts[index];
                        final isDone = remaining <= 0;

                        return Semantics(
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
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FortressFocusThikrPane extends StatelessWidget {
  const _FortressFocusThikrPane({
    required this.category,
    required this.duas,
    required this.currentIndex,
    required this.remainingCounts,
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
  final ValueNotifier<int> currentIndex;
  final ValueNotifier<List<int>> remainingCounts;
  final ObjectRef<int> slideDirection;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 480
            ? AppSpacing.lg
            : constraints.maxWidth < 640
            ? AppSpacing.xl
            : AppSpacing.xxl;
        const verticalPadding = AppSpacing.xl;

        return ValueListenableBuilder<int>(
          valueListenable: currentIndex,
          builder: (context, index, _) {
            return ValueListenableBuilder<List<int>>(
              valueListenable: remainingCounts,
              builder: (context, counts, _) {
                final currentDua = duas[index];
                final remaining = counts[index];
                final isDone = remaining <= 0;
                final canGoNext = index < duas.length - 1;
                final canGoPrevious = index > 0;
                final hintReserve = showReadingHint && !isDone
                    ? AppSpacing.xxl + AppSpacing.md
                    : AppSpacing.lg;
                final viewportMinHeight = (constraints.maxHeight -
                        verticalPadding * 2 -
                        hintReserve)
                    .clamp(0.0, double.infinity);

                return Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      if (event.scrollDelta.dx.abs() >
                          event.scrollDelta.dy.abs()) {
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
                              slideDirection: slideDirection.value,
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
                                child: FortressThikrBody(
                                  dua: currentDua,
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
                          child: FortressExcludeDecorative(
                            child: IgnorePointer(
                              child: Text(
                                l10n.fortressReadingHint,
                                style: theme.typography.body.xs.copyWith(
                                  color: theme.colors.mutedForeground
                                      .withAlpha(160),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      if (tapFeedback case (final position, final tick))
                        FortressTapRippleFeedback(
                          key: ValueKey(tick),
                          position: position,
                          color: theme.colors.primary,
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class FortressTapRippleFeedback extends HookWidget {
  const FortressTapRippleFeedback({
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

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    return Positioned(
      left: position.dx - 28,
      top: position.dy - 28,
      child: FortressExcludeDecorative(
        child: IgnorePointer(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.45, end: 0).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.35, end: 1.6).animate(animation),
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
