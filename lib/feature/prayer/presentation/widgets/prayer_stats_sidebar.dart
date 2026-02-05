import 'package:flutter/material.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/analysis_section.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/sunnah_times_card.dart';
import 'package:hasanat/theme/theme.dart';

/// Stats sidebar showing prayer analytics and insights.
class PrayerStatsSidebar extends StatelessWidget {
  /// Creates a [PrayerStatsSidebar] instance.
  const PrayerStatsSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SidebarContent();
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AnalysisSection(),
        SizedBox(height: AppSpacing.md),
        // Sunnah Times - moved down
        SunnahTimesCard(),
      ],
    );
  }
}
