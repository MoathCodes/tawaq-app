import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/centered_viewport_shell.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';
import 'package:tawaq/core/widgets/scroll_overflow_hint_viewport.dart';
import 'package:tawaq/feature/onboarding/presentation/models/onboarding_steps.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared onboarding layout — header, animated step body, and navigation.
class OnboardingScaffold extends ConsumerWidget {
  /// Creates [OnboardingScaffold].
  const OnboardingScaffold({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.slideDirection,
    required this.stepContent,
    required this.navigation,
    super.key,
  });

  /// Active step.
  final OnboardingStep step;

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
    final header = _OnboardingHeader(
      stepIndex: step.index,
      stepCount: OnboardingStep.values.length,
      title: title,
      subtitle: subtitle,
    );

    final content = DirectionalContentSwitcher(
      currentKey: step,
      slideDirection: slideDirection,
      child: _OnboardingStepCard(child: stepContent),
    );

    return FScaffold(
      child: SafeArea(
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              step: step,
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
                              step: step,
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
    );
  }
}

class _OnboardingStepCard extends StatelessWidget {
  const _OnboardingStepCard({required this.child});

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
  const _OnboardingStepViewport({
    required this.step,
    required this.maxWidth,
    required this.child,
    this.alignment,
  });

  final OnboardingStep step;
  final double maxWidth;
  final Widget child;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    return ScrollOverflowHintViewport(
      resetTrigger: step,
      builder: (controller) => centeredViewportScrollTab(
        maxContentWidth: maxWidth,
        controller: controller,
        child: child,
        alignment: alignment ?? Alignment.topCenter,
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
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
