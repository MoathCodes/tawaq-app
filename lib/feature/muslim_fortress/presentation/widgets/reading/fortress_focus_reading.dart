import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_scope.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';
import 'package:tawaq/core/widgets/reading_swipe_viewport.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_reading_nav_bar.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_thikr_body.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/theme/theme.dart';

/// Maximum readable width for focus-reading thikr and virtue lines.
const kFortressReadingMaxWidth = 720.0;

class FortressFocusReadingView extends HookWidget {
  const FortressFocusReadingView({required this.category, required this.duas, required this.onExit, super.key,
    this.initialIndex = 0,
  });

  final FortressCategory category;
  final List<FortressDuaItem> duas;
  final VoidCallback onExit;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    if (duas.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.fortressNoAdhkarInChapter,
            style: theme.typography.md,
          ),
        ),
      );
    }
    final currentIndex = useState(
      initialIndex.clamp(0, duas.isEmpty ? 0 : duas.length - 1),
    );
    final remainingCounts = useState(
      duas.map((d) => d.targetCount).toList(growable: false),
    );
    final advanceTimer = useRef<Timer?>(null);
    final slideDirection = useRef(1);
    final pulseController = useAnimationController(
      duration: const Duration(milliseconds: 180),
    );
    final tapFeedback = useState<(Offset position, int tick)?>(null);

    useEffect(
      () =>
          () => advanceTimer.value?.cancel(),
      const [],
    );

    final currentDua = duas[currentIndex.value];
    final remaining = remainingCounts.value[currentIndex.value];
    final isDone = remaining <= 0;
    final progress = isDone
        ? 1.0
        : 1.0 - (remaining / currentDua.targetCount).clamp(0.0, 1.0);

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
      if (remaining <= 0) return;

      final next = List<int>.from(remainingCounts.value);
      next[currentIndex.value] = remaining - 1;
      remainingCounts.value = next;
      triggerFeedback(localPosition);

      if (next[currentIndex.value] <= 0 &&
          currentIndex.value < duas.length - 1) {
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

    final canGoNext = currentIndex.value < duas.length - 1;
    final canGoPrevious = currentIndex.value > 0;

    final counterScale = Tween<double>(begin: 1, end: 0.88).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: AppShortcutScope(
        autofocus: true,
        shortcuts: const {
          AppShortcutId.fortressCount,
          AppShortcutId.fortressThikrNext,
          AppShortcutId.fortressThikrPrev,
        },
        handlers: {
          AppShortcutId.fortressCount: decrement,
          AppShortcutId.fortressThikrNext: goToNext,
          AppShortcutId.fortressThikrPrev: goToPrevious,
        },
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FortressExcludeDecorative(
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
                      final compactToolbar = toolbarConstraints.maxWidth <
                          context.theme.breakpoints.sm;

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
                                style: theme.typography.sm.copyWith(
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
                                    style: theme.typography.xl3.copyWith(
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
                                  '${currentIndex.value + 1} / ${duas.length}',
                                  style: theme.typography.xs.copyWith(
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
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const horizontalPadding = AppSpacing.xxl;
                    const verticalPadding = AppSpacing.xl;
                    final hintReserve = isDone
                        ? AppSpacing.lg
                        : AppSpacing.xxl + AppSpacing.md;

                    final viewportMinHeight = (constraints.maxHeight -
                            verticalPadding * 2 -
                            hintReserve)
                        .clamp(0.0, double.infinity);

                    return Listener(
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          if (event.scrollDelta.dx.abs() >
                              event.scrollDelta.dy.abs()) {
                            handleHorizontalScroll(event.scrollDelta.dx);
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
                            onNext: goToNext,
                            onPrevious: goToPrevious,
                            semanticsLabel: l10n.fortressReadingHint,
                            onTapDown: decrement,
                            child: NonSelectable(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: kFortressReadingMaxWidth,
                                ),
                                child: DirectionalContentSwitcher(
                                  currentKey: currentIndex.value,
                                  slideDirection: slideDirection.value,
                                  child: Semantics(
                                    container: true,
                                    label: FortressA11y.thikrSectionLabel(
                                      l10n: l10n,
                                      categoryTitle: category.title,
                                      index: currentIndex.value,
                                      total: duas.length,
                                      remaining: remaining,
                                      targetCount: currentDua.targetCount,
                                      isDone: isDone,
                                    ),
                                    child: FortressThikrBody(
                                      dua: currentDua,
                                      muted: isDone,
                                      proseStyle: theme.typography.xl3
                                          .copyWith(
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
                          if (!isDone)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: AppSpacing.lg,
                              child: FortressExcludeDecorative(
                                child: IgnorePointer(
                                  child: Text(
                                    l10n.fortressReadingHint,
                                    style: theme.typography.xs.copyWith(
                                      color: theme.colors.mutedForeground
                                          .withAlpha(160),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          if (tapFeedback.value case (
                            final position,
                            final tick,
                          ))
                            FortressTapRippleFeedback(
                              key: ValueKey(tick),
                              position: position,
                              color: theme.colors.primary,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (currentDua.hasVirtue)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.md,
                    AppSpacing.xxl,
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
                    canGoPrevious: canGoPrevious,
                    canGoNext: canGoNext,
                    onPrevious: goToPrevious,
                    onNext: goToNext,
                    studyDua: currentDua.hasFocusStudyAction
                        ? currentDua
                        : null,
                    center: Text(
                      isDone
                          ? l10n.fortressCompleted
                          : l10n.fortressRemainingCount(remaining),
                      style: theme.typography.sm.copyWith(
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
