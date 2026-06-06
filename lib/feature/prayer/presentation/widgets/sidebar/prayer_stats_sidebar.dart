import 'package:flutter/material.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/analysis_section.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/sidebar/sunnah_times_card.dart';
import 'package:tawaq/theme/theme.dart';

/// Stats sidebar showing prayer analytics and insights.
class PrayerStatsSidebar extends StatelessWidget {
  /// Creates a [PrayerStatsSidebar] instance.
  const PrayerStatsSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AnalysisSection(),
        SizedBox(height: AppSpacing.md),
        SunnahTimesCard(),
      ],
    );
  }
}
