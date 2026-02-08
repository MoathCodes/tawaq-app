import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Search-based calculation method selector.
Widget buildCalculationMethodSelector(
  BuildContext context,
  WidgetRef ref,
  CalculationMethod methodValue,
) {
  return FSelect<CalculationMethod>.searchBuilder(
    control: .lifted(
      value: methodValue,
      onChange: (value) async {
        if (value != null) {
          await ref
              .read(prayerSettingsProvider.notifier)
              .update(
                (settings) => settings.copyWith(method: value),
              );
        }
      },
    ),
    label: Text(context.l10n.calculationMethod),
    format: (method) => method.getLocaleName(context.l10n),
    filter: (query) async {
      return query.isEmpty
          ? CalculationMethod.values
          : CalculationMethod.values.where(
              (method) => method
                  .getLocaleName(context.l10n)
                  .toLowerCase()
                  .contains(query.toLowerCase()),
            );
    },
    contentBuilder: (_, _, data) => data
        .map(
          (method) => FSelectItem(
            title: Text(method.getLocaleName(context.l10n)),
            value: method,
          ),
        )
        .toList(),
    contentEmptyBuilder: (_, _) => Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          const Icon(FIcons.searchX),
          Text(context.l10n.noResults),
        ],
      ),
    ),
    contentLoadingBuilder: (_, _) => const FCircularProgress(),
  );
}
