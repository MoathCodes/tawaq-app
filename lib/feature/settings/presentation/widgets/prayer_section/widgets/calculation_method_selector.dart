import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Builds a search [FSelect] for [CalculationMethod] tied to prayer settings.
///
/// Persists the chosen method through [prayerSettingsProvider].
Widget buildCalculationMethodSelector(
  BuildContext context,
  WidgetRef ref,
  CalculationMethod methodValue, {
  bool enabled = true,
}) {
  final l10n = context.l10n;
  return NonSelectable(
    child: FSelect<CalculationMethod>.searchBuilder(
      enabled: enabled,
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
      format: (method) => method.getLocaleName(l10n),
      filter: (query) async {
        return query.isEmpty
            ? CalculationMethod.values
            : CalculationMethod.values.where(
                (method) => method
                    .getLocaleName(l10n)
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              );
      },
      contentBuilder: (_, _, data) => data
          .map(
            (method) => FSelectItem(
              title: Text(method.getLocaleName(l10n)),
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
            const Icon(FLucideIcons.searchX),
            Text(l10n.noResults),
          ],
        ),
      ),
      contentLoadingBuilder: (_, _) => const FCircularProgress(),
    ),
  );
}
