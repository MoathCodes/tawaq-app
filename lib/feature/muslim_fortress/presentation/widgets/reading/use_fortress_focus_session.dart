import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';

/// Session state and navigation for fortress focus-reading mode.
typedef FortressFocusSession = ({
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

/// Manages index, repeat counts, and feedback for focus reading.
FortressFocusSession useFortressFocusSession({
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
