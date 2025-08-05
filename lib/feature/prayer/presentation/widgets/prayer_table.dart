import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/utils/text_extensions.dart';
import 'package:hasanat/core/widgets/hover_card.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_table_model.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_table/prayer_table_provider.dart';
import 'package:hasanat/l10n/app_localizations.dart';

class PrayerTable extends ConsumerWidget {
  // Constants for styling
  static const double _headerHeight = 48.0;

  static const double _imageSize = 56.0;
  static const double _imageBorderRadius = 12.0;
  static const int _nextPrayerAlpha = 30;
  static const int _currentPrayerAlpha = 50;
  const PrayerTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final prayerTableStream = ref.watch(prayerTableProvider(l10n));

    // Using a Material Card as the main container
    return HoverCard(
      padding: const EdgeInsets.all(0),
      // clipBehavior:
      //     Clip.antiAlias, // Ensures content respects the border radius
      // color: theme.colors.secondary,
      // elevation: 0,
      // shape: RoundedRectangleBorder(
      //   side: BorderSide(color: theme.dividerStyles.horizontalStyle.color),
      //   borderRadius: const BorderRadius.all(Radius.circular(12)),
      // ),
      child: switch (prayerTableStream) {
        // Error State
        AsyncError(:final error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${error.toString()}'),
            ),
          ),
        // Loading State
        AsyncLoading() => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: FProgress.circularIcon(),
            ),
          ),
        // Data State
        AsyncValue(:final value) =>
          // DataTable should be horizontally scrollable if content overflows
          LayoutBuilder(builder: (context, constraints) {
            final totalH = constraints.maxHeight;
            const rowCount = 8;

            final rowH = (totalH - _headerHeight) / rowCount;
            return DataTable(
              border: TableBorder.symmetric(
                  inside:
                      BorderSide(color: theme.colors.primary.withAlpha(150))),
              headingRowHeight: _headerHeight,
              dataRowMaxHeight: rowH.clamp(24.0, double.infinity),
              columnSpacing: 16.0,
              dividerThickness: 1.0,
              columns: _buildColumns(l10n, theme),
              rows:
                  value!.map((row) => _buildDataRow(row, theme, l10n)).toList(),
            );
          }),
      },
    );
  }

  /// Builds the list of columns for the DataTable.
  List<DataColumn> _buildColumns(AppLocalizations l10n, FThemeData theme) {
    final columns = [
      DataColumn(
        label: Text(l10n.prayer, style: theme.typography.lg),
      ),
      DataColumn(
          label: Text(l10n.adhan, style: theme.typography.sm), numeric: true),
      DataColumn(
          label: Text(l10n.iqamah, style: theme.typography.sm), numeric: true),
    ];
    // Reverse the order for RTL layouts
    return columns;
  }

  /// Builds a single DataRow for the DataTable.
  DataRow _buildDataRow(
      PrayerTableRow row, FThemeData theme, AppLocalizations l10n) {
    // Define the background color based on the prayer state
    Color? rowColor;
    if (row.isCurrentPrayer) {
      rowColor = theme.colors.primary.withAlpha(_currentPrayerAlpha);
    } else if (row.isNextPrayer) {
      rowColor = theme.colors.primary.withAlpha(_nextPrayerAlpha);
    }

    final cells = [
      _buildPrayerCell(row, theme, l10n),
      _buildTimeCell(row.adhan, theme),
      _buildTimeCell(row.iqamah, theme),
    ];

    return DataRow(
      color: WidgetStateProperty.all(rowColor),
      cells: cells,
    );
  }

  /// Builds the cell containing the prayer name and image.
  DataCell _buildPrayerCell(
      PrayerTableRow row, FThemeData theme, AppLocalizations l10n) {
    return DataCell(
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prayer Image
            Container(
              width: _imageSize.w,
              height: _imageSize.h,
              decoration: BoxDecoration(
                color: theme.colors.mutedForeground,
                borderRadius: BorderRadius.circular(_imageBorderRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_imageBorderRadius),
                child: Image.asset(
                  row.prayer.imagePath,
                  fit: BoxFit.cover,
                  alignment: row.prayer.alignment,
                  cacheWidth:
                      _imageSize.w.toInt() * 2, // Higher res for caching
                  cacheHeight: _imageSize.h.toInt() * 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Prayer Name
            Text(
              row.prayer.getLocaleName(l10n),
            ).lg,
          ],
        ),
      ),
    );
  }

  /// Builds a generic cell for Adhan and Iqamah times.
  DataCell _buildTimeCell(
      ({String title, String? subtitle}) timeInfo, FThemeData theme) {
    return DataCell(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        // crossAxisAlignment:
        //     isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(timeInfo.title).sm,
          if (timeInfo.subtitle != null)
            Text(
              timeInfo.subtitle!,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }
}
