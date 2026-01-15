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
import 'package:hasanat/theme/theme.dart';

/// Widget that displays prayer times in a table.
class PrayerTable extends ConsumerWidget {
  /// Creates a [PrayerTable] instance.
  const PrayerTable({super.key});

  static const double _headerHeight = 48;
  static const Size _imageSize = Size(56, 56);
  static final BorderRadius _imageBorderRadius = BorderRadius.circular(
    AppSpacing.md,
  );
  static const EdgeInsets _cellPadding = .all(AppSpacing.sm);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(prayerTableProvider(l10n));

    return HoverCard(
      padding: .zero,
      child: data.when(
        data: (rows) => _TableContent(rows: rows),
        loading: () => _LoadingTable(),
        error: (e, _) => _ErrorWidget(error: e),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Center(
      child: Padding(
        padding: const .all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colors.destructive,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Error loading prayer table',
              style: theme.typography.base,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
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

class _LoadingTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;

    return FSkeletonizer(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final rowH = (constraints.maxHeight - PrayerTable._headerHeight) / 8;
          return DataTable(
            headingRowHeight: PrayerTable._headerHeight,
            dataRowMaxHeight: rowH.clamp(24.0, double.infinity),
            columnSpacing: 16,
            dividerThickness: 1,
            columns: _buildColumns(l10n, theme),
            rows: List.generate(
              8,
              (_) => DataRow(
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
                              borderRadius: PrayerTable._imageBorderRadius,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Text('Loading Prayer'),
                        ],
                      ),
                    ),
                  ),
                  const DataCell(
                    Column(
                      mainAxisAlignment: .center,
                      children: [Text('00:00'), Text('Loading')],
                    ),
                  ),
                  const DataCell(
                    Column(
                      mainAxisAlignment: .center,
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
}

class _TableContent extends StatelessWidget {
  const _TableContent({required this.rows});
  final List<PrayerTableRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (_, constraints) {
        final rowH = (constraints.maxHeight - PrayerTable._headerHeight) / 8;
        return DataTable(
          border: TableBorder.symmetric(
            inside: BorderSide(color: theme.colors.primary.withAlpha(150)),
          ),
          headingRowHeight: PrayerTable._headerHeight,
          dataRowMaxHeight: rowH.clamp(24.0, double.infinity),
          columnSpacing: 16,
          dividerThickness: 1,
          columns: _buildColumns(l10n, theme),
          rows: rows.map((row) => _buildRow(row, theme, l10n)).toList(),
        );
      },
    );
  }

  DataRow _buildRow(
    PrayerTableRow row,
    FThemeData theme,
    AppLocalizations l10n,
  ) {
    Color? bgColor;
    if (row.isCurrentPrayer)
      bgColor = theme.colors.primary.withAlpha(50);
    else if (row.isNextPrayer)
      bgColor = theme.colors.primary.withAlpha(30);

    return DataRow(
      color: WidgetStateProperty.all(bgColor),
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
                    borderRadius: PrayerTable._imageBorderRadius,
                  ),
                  child: ClipRRect(
                    borderRadius: PrayerTable._imageBorderRadius,
                    child: Image.asset(
                      row.prayer.imagePath,
                      fit: BoxFit.cover,
                      alignment: row.prayer.alignment,
                      cacheWidth: (PrayerTable._imageSize.width * 2).toInt(),
                      cacheHeight: (PrayerTable._imageSize.height * 2).toInt(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  row.prayer.getLocaleName(l10n),
                  style: theme.typography.lg,
                ),
              ],
            ),
          ),
        ),
        _timeCell(row.adhan, theme),
        _timeCell(row.iqamah, theme),
      ],
    );
  }

  DataCell _timeCell(
    ({String title, String? subtitle}) info,
    FThemeData theme,
  ) {
    return DataCell(
      Column(
        mainAxisAlignment: .center,
        children: [
          Text(info.title).sm,
          if (info.subtitle != null)
            Text(
              info.subtitle!,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }
}

List<DataColumn> _buildColumns(AppLocalizations l10n, FThemeData theme) => [
  DataColumn(label: Text(l10n.prayer, style: theme.typography.sm)),
  DataColumn(
    label: Text(l10n.adhan, style: theme.typography.sm),
    numeric: true,
  ),
  DataColumn(
    label: Text(l10n.iqamah, style: theme.typography.sm),
    numeric: true,
  ),
];
