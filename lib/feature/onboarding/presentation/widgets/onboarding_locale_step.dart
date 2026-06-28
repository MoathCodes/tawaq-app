import 'package:flutter/material.dart';
import 'package:tawaq/core/locale/locale_select_tile_group.dart';

/// Language selection step.
class OnboardingLocaleStep extends StatelessWidget {
  /// Creates [OnboardingLocaleStep].
  const OnboardingLocaleStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const LocaleSelectTileGroup();
  }
}
