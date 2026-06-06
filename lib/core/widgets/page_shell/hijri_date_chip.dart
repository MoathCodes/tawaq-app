import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/utils/hijri_provider.dart';

/// Isolated Hijri date display for the shell app bar.
///
/// Only this subtree rebuilds on the 1 Hz [hijriClockProvider] tick.
class HijriDateChip extends ConsumerWidget {
  /// Creates a [HijriDateChip].
  const HijriDateChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijriDate = ref.watch(hijriClockProvider);

    return switch (hijriDate) {
      AsyncData<String>(:final value) => Container(
        padding: context.theme.buttonStyles.outline.sm.contentStyle.padding,
        decoration: context.theme.buttonStyles.outline.sm.decoration.base,
        child: Text(value),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
