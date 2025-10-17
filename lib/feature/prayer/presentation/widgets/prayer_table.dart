import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/utils/text_extensions.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_table_model.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_table/prayer_table_provider.dart';
import 'package:hasanat/l10n/app_localizations.dart';

class PrayerTable extends ConsumerWidget {

  const PrayerTable({super.key});
  // Static constants for performance
  static const double _headerHeight = 48;
  static const Size _imageSize = Size(56, 56);
  static const double _imageBorderRadius = 12;
  static const int _nextPrayerAlpha = 30;
  static const int _currentPrayerAlpha = 50;

  // Static objects to avoid repeated creation
  static final BorderRadius _imageBorderRadiusGeometry = BorderRadius.circular(
    _imageBorderRadius,
  );
  static const EdgeInsets _cellPadding = EdgeInsets.all(8);
  static const SizedBox _imagePadding = SizedBox(width: 12);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prayerTableStream = ref.watch(prayerTableProvider(l10n));

    return HoverCard(
      padding: EdgeInsets.zero,
      child: prayerTableStream.when(
        data: (rows) => _PrayerTableContent(rows: rows),
        loading: () => const _LoadingWidget(),
        error: (error, _) => _ErrorWidget(error: error),
      ),
    );
  }
}

/// Error widget for when data loading fails
class _ErrorWidget extends StatelessWidget {

  const _ErrorWidget({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colors.destructive,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading prayer table',
              style: theme.typography.base,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading widget with skeleton effect
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;

    return FSkeletonizer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalH = constraints.maxHeight;
          const rowCount = 8;
          final rowH = (totalH - PrayerTable._headerHeight) / rowCount;

          return DataTable(
            headingRowHeight: PrayerTable._headerHeight,
            dataRowMaxHeight: rowH.clamp(24.0, double.infinity),
            columnSpacing: 16,
            dividerThickness: 1,
            columns: _buildColumns(l10n, theme),
            rows: List.generate(
              8,
              (index) => DataRow(
                cells: [
                  DataCell(
                    Padding(
                      padding: PrayerTable._cellPadding,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: PrayerTable._imageSize.width,
                            height: PrayerTable._imageSize.height,
                            decoration: BoxDecoration(
                              color: theme.colors.mutedForeground,
                              borderRadius:
                                  PrayerTable._imageBorderRadiusGeometry,
                            ),
                          ),
                          PrayerTable._imagePadding,
                          const Text('Loading Prayer'),
                        ],
                      ),
                    ),
                  ),
                  const DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text('00:00'), Text('Loading')],
                    ),
                  ),
                  const DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text('00:00'), Text('Loading')],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<DataColumn> _buildColumns(AppLocalizations l10n, FThemeData theme) {
    return [
      DataColumn(
        label: Text(l10n.prayer, style: theme.typography.sm),
      ),
      DataColumn(
        label: Text(l10n.adhan, style: theme.typography.sm),
        numeric: true,
      ),
      DataColumn(
        label: Text(l10n.iqamah, style: theme.typography.sm),
        numeric: true,
      ),
    ];
  }
}

/// Main content widget for the prayer table
class _PrayerTableContent extends StatelessWidget {
  const _PrayerTableContent({required this.rows});
  // Static cached columns to avoid rebuilding
  static List<DataColumn>? _cachedColumns;

  static AppLocalizations? _cachedL10n;

  static FThemeData? _cachedTheme;
  final List<PrayerTableRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalH = constraints.maxHeight;
        const rowCount = 8;
        final rowH = (totalH - PrayerTable._headerHeight) / rowCount;

        return DataTable(
          border: TableBorder.symmetric(
            inside: BorderSide(color: theme.colors.primary.withAlpha(150)),
          ),
          headingRowHeight: PrayerTable._headerHeight,
          dataRowMaxHeight: rowH.clamp(24.0, double.infinity),
          columnSpacing: 16,
          dividerThickness: 1,
          columns: _buildColumns(l10n, theme),
          rows: rows.map((row) => _buildDataRow(row, theme, l10n)).toList(),
        );
      },
    );
  }

  List<DataColumn> _buildColumns(AppLocalizations l10n, FThemeData theme) {
    // Return cached columns if available and valid
    if (_cachedColumns != null &&
        _cachedL10n == l10n &&
        _cachedTheme == theme) {
      return _cachedColumns!;
    }

    _cachedColumns = [
      DataColumn(
        label: Text(l10n.prayer, style: theme.typography.sm),
      ),
      DataColumn(
        label: Text(l10n.adhan, style: theme.typography.sm),
        numeric: true,
      ),
      DataColumn(
        label: Text(l10n.iqamah, style: theme.typography.sm),
        numeric: true,
      ),
    ];
    _cachedL10n = l10n;
    _cachedTheme = theme;

    return _cachedColumns!;
  }

  DataRow _buildDataRow(
    PrayerTableRow row,
    FThemeData theme,
    AppLocalizations l10n,
  ) {
    // Define the background color based on the prayer state
    Color? rowColor;
    if (row.isCurrentPrayer) {
      rowColor = theme.colors.primary.withAlpha(
        PrayerTable._currentPrayerAlpha,
      );
    } else if (row.isNextPrayer) {
      rowColor = theme.colors.primary.withAlpha(PrayerTable._nextPrayerAlpha);
    }

    final cells = [
      _buildPrayerCell(row, theme, l10n),
      _buildTimeCell(row.adhan, theme),
      _buildTimeCell(row.iqamah, theme),
    ];

    return DataRow(color: WidgetStateProperty.all(rowColor), cells: cells);
  }

  /// Builds the cell containing the prayer name and image.
  DataCell _buildPrayerCell(
    PrayerTableRow row,
    FThemeData theme,
    AppLocalizations l10n,
  ) {
    return DataCell(
      Padding(
        padding: PrayerTable._cellPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prayer Image with optimized container
            Container(
              width: PrayerTable._imageSize.width,
              height: PrayerTable._imageSize.height,
              decoration: BoxDecoration(
                color: theme.colors.mutedForeground,
                borderRadius: PrayerTable._imageBorderRadiusGeometry,
              ),
              child: ClipRRect(
                borderRadius: PrayerTable._imageBorderRadiusGeometry,
                child: Image.asset(
                  row.prayer.imagePath,
                  fit: BoxFit.cover,
                  alignment: row.prayer.alignment,
                  cacheWidth: (PrayerTable._imageSize.width * 2).toInt(),
                  cacheHeight: (PrayerTable._imageSize.height * 2).toInt(),
                ),
              ),
            ),
            PrayerTable._imagePadding,
            // Prayer Name
            Text(row.prayer.getLocaleName(l10n), style: theme.typography.lg),
          ],
        ),
      ),
    );
  }

  /// Builds a generic cell for Adhan and Iqamah times.
  DataCell _buildTimeCell(
    ({String title, String? subtitle}) timeInfo,
    FThemeData theme,
  ) {
    return DataCell(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
