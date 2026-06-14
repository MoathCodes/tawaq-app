import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/desktop/adhan_alert_controller.dart';
import 'package:tawaq/core/desktop/window_snapshot.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/adhan/adhan_alert_card.dart';
import 'package:tawaq/theme/theme.dart';

/// Root overlay that renders the dismissible adhan alert above app content.
class AdhanAlertHost extends ConsumerWidget {
  /// Creates [AdhanAlertHost].
  const AdhanAlertHost({required this.child, super.key});

  /// Wrapped app subtree.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(adhanAlertControllerProvider);
    final showing = alert.isShowing;
    final compact = showing && alert.isCompactMorph;
    final colors = context.theme.colors;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Keep the router subtree mounted. Removing it during compact morph
        // unmounts InheritedWidgets while dependents still exist.
        Offstage(
          offstage: compact,
          child: IgnorePointer(
            ignoring: showing,
            child: child,
          ),
        ),
        if (showing) ...[
          if (!compact)
            Positioned.fill(
              child: ModalBarrier(
                color: colors.barrier.withValues(alpha: 0.45),
                dismissible: false,
              ),
            ),
          Positioned.fill(
            child: FocusScope(
              autofocus: true,
              child: compact
                  ? ColoredBox(
                      color: colors.background,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Center(
                            child: AdhanAlertCard(
                              kind: alert.kind!,
                              prayer: alert.prayer!,
                              scheduledTime: alert.scheduledTime!,
                              playsSound: alert.playsSound,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: AnimationEntry(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: kAdhanAlertCompactSize.width,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: AdhanAlertCard(
                              kind: alert.kind!,
                              prayer: alert.prayer!,
                              scheduledTime: alert.scheduledTime!,
                              playsSound: alert.playsSound,
                              showCloseButton: true,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
