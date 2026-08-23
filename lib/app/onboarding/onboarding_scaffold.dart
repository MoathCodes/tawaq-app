import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/app/desktop/widgets/title_bar_drag_area.dart';
import 'package:tawaq/app/desktop/widgets/window_controls.dart';
import 'package:tawaq/core/layout/centered_viewport_shell.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';
import 'package:tawaq/core/widgets/scroll_overflow_hint_viewport.dart';
import 'package:tawaq/feature/settings/presentation/provider/desktop_settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared onboarding layout — header, animated step body, and navigation.
class OnboardingScaffold extends ConsumerWidget {
  /// Creates [OnboardingScaffold].
  const new({
    required this.stepKey,
    required this.stepIndex,
    required this.stepCount,
    required this.title,
    required this.subtitle,
    required this.slideDirection,
    required this.stepContent,
    required this.navigation,
    super.key,
  });

  /// Identity used to reset scrolling and animate step changes.
  final Object stepKey;

  /// Zero-based active step index.
  final int stepIndex;

  /// Total number of onboarding steps.
  final int stepCount;

  /// Header title.
  final String title;

  /// Header subtitle.
  final String subtitle;

  /// Direction for step transitions (`1` = back, `-1` = forward).
  final int slideDirection;

  /// Animated step body.
  final Widget stepContent;

  /// Bottom or side navigation bar.
  final Widget navigation;

  static const _compactMaxWidth = 640.0;
  static const _desktopMaxWidth = 1120.0;
  static const _desktopRailWidth = 340.0;
  static const _compactMinHeight = 600.0;

  static double _maxPanelHeight(double viewportHeight) =>
      math.min(viewportHeight, math.max(480, viewportHeight - AppSpacing.xl));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktopSettings = ref.watch(desktopSettingsProvider).value;
    final forceMacStyle = desktopSettings?.forceMacStyleWindowControls ?? false;

    final header = _OnboardingHeader(
      stepIndex: stepIndex,
      stepCount: stepCount,
      title: title,
      subtitle: subtitle,
    );

    final content = DirectionalContentSwitcher(
      currentKey: stepKey,
      slideDirection: slideDirection,
      child: _OnboardingStepCard(child: stepContent),
    );

    final showDesktopTopBar = isDesktopPlatform;
    final colors = context.theme.colors;
    final borderWidth = context.theme.style.borderWidth;
    final controlsOnLeft = forceMacStyle;

    return FScaffold(
      child: Column(
        children: [
          if (showDesktopTopBar)
            NonSelectable(
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: colors.card,
                  border: Border(
                    bottom: BorderSide(
                      color: colors.border,
                      width: borderWidth,
                    ),
                  ),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: TitleBarDragArea()),
                      Align(
                        alignment: controlsOnLeft
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: WindowControls(forceMacStyle: forceMacStyle),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: SafeArea(
              top: !showDesktopTopBar,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide =
                        isContainerAtLeast(
                          context,
                          constraints,
                          FBreakpoint.lg,
                        ) &&
                        constraints.maxHeight >= _compactMinHeight;
                    final maxWidth = wide ? _desktopMaxWidth : _compactMaxWidth;
                    final panelHeight = _maxPanelHeight(constraints.maxHeight);

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                        maxHeight: panelHeight,
                      ),
                      child: wide
                          ? Row(
                              spacing: AppSpacing.xxl,
                              children: [
                                SizedBox(
                                  width: _desktopRailWidth,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        header,
                                        const SizedBox(height: AppSpacing.xxxl),
                                        navigation,
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _OnboardingStepViewport(
                                    resetTrigger: stepKey,
                                    maxWidth: maxWidth,
                                    alignment: Alignment.center,
                                    child: content,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                header,
                                const SizedBox(height: AppSpacing.lg),
                                Flexible(
                                  child: _OnboardingStepViewport(
                                    resetTrigger: stepKey,
                                    maxWidth: maxWidth,
                                    child: content,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                navigation,
                              ],
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStepCard extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _OnboardingStepViewport extends StatelessWidget {
  const new({
    required this.resetTrigger,
    required this.maxWidth,
    required this.child,
    this.alignment,
  });

  final Object resetTrigger;
  final double maxWidth;
  final Widget child;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    return ScrollOverflowHintViewport(
      resetTrigger: resetTrigger,
      builder: (controller) => CenteredViewportShell.scrollTab(
        maxContentWidth: maxWidth,
        controller: controller,
        alignment: alignment ?? Alignment.topCenter,
        child: child,
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const new({
    required this.stepIndex,
    required this.stepCount,
    required this.title,
    required this.subtitle,
  });

  final int stepIndex;
  final int stepCount;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        FDeterminateProgress(value: (stepIndex + 1) / stepCount),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.xs,
          children: [
            Text(
              title,
              style: theme.typography.body.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
