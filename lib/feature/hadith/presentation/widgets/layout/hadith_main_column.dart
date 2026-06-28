import 'package:flutter/material.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_results_list.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/search/hadith_search_header.dart';
import 'package:tawaq/theme/theme.dart';

/// Main Hadith column: search header and scrollable results list.
class HadithMainColumn extends StatelessWidget {
  /// Creates the main content column.
  const HadithMainColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        HadithSearchHeader(),
        SizedBox(height: AppSpacing.lg),
        Expanded(child: HadithResultsList()),
      ],
    );
  }
}
