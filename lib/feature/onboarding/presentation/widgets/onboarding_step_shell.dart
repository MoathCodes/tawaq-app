import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared chrome for an onboarding step body.
class OnboardingStepShell extends StatelessWidget {
  /// Creates [OnboardingStepShell].
  const OnboardingStepShell({
    required this.child,
    this.padding,
    super.key,
  });

  /// Step content.
  final Widget child;

  /// Optional inner padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
