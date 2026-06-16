import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/provider/iqamah_draft_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/custom_parameters_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/calculation_method_selector.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/prayer_iqamah_tile.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Widget for the prayer time settings section.
class PrayerSettingsTimeSection extends HookConsumerWidget {
  /// Creates a new [PrayerSettingsTimeSection] instance.
  const PrayerSettingsTimeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unsavedPrayers = ref.watch(
      iqamahDraftProvider.select((draft) => draft.unsavedPrayers),
    );
    final draft = ref.read(iqamahDraftProvider.notifier);

    useEffect(
      () {
        final listeners = <Prayer, VoidCallback>{};
        for (final prayer in kIqamahDraftPrayers) {
          void listener() {
            if (!draft.focusNode(prayer).hasFocus) {
              draft.save(context, prayer);
            }
          }

          draft.focusNode(prayer).addListener(listener);
          listeners[prayer] = listener;
        }

        return () {
          for (final entry in listeners.entries) {
            draft.focusNode(entry.key).removeListener(entry.value);
          }
        };
      },
      const [],
    );

    final method = ref.watch(
      prayerSettingsProvider.select(
        (value) => value.value?.method ?? CalculationMethod.ummAlQura,
      ),
    );
    final is24Hours = ref.watch(
      prayerSettingsProvider.select(
        (value) => value.value?.is24Hours,
      ),
    );
    final l10n = context.l10n;

    return SettingsSection(
      crossAxisAlignment: CrossAxisAlignment.center,
      title: l10n.timeSectionTitle,
      subtitle: l10n.timeSectionSubtitle,
      child: FCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: [
            SettingsGroup(
              title: l10n.calculationMethod,
              child: Column(
                spacing: AppSpacing.md,
                children: [
                  buildCalculationMethodSelector(
                    context,
                    ref,
                    method,
                  ),
                  const PrayerSettingsCustomParametersCard(),
                ],
              ),
            ),
            const FDivider(),
            SettingsGroup(
              title: l10n.timeFormat,
              child: NonSelectable(
                child: _TimeFormatSwitch(is24Hours: is24Hours ?? false),
              ),
            ),
            const FDivider(),
            SettingsGroup(
              title: l10n.iqamahAdjustment,
              subtitle: l10n.iqamahAfterAdhan,
              trailing: NonSelectable(
                child: FTooltip(
                  tipBuilder: (ctx, ctrl) => Text(l10n.save),
                  child: FButton(
                    variant: unsavedPrayers.isEmpty ? .outline : .primary,
                    prefix: const Icon(FLucideIcons.save, size: 16),
                    style: const FButtonStyleDelta.delta(
                      contentStyle: FButtonContentStyleDelta.delta(
                        padding: EdgeInsetsGeometryDelta.value(
                          EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    onPress: unsavedPrayers.isEmpty
                        ? null
                        : () => draft.saveAll(context),
                    child: Text(l10n.save),
                  ),
                ),
              ),
              child: IqamahPrayerList(
                children: kIqamahDraftPrayers
                    .map(
                      (prayer) => PrayerIqamahTile(
                        key: ValueKey(prayer),
                        prayer: prayer,
                        allowSigned: false,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeFormatSwitch extends ConsumerWidget {
  const _TimeFormatSwitch({required this.is24Hours});

  final bool is24Hours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      prayerSettingsProvider.select((value) => value.hasValue),
    );
    final l10n = context.l10n;

    return FSwitch(
      enabled: enabled,
      value: is24Hours,
      onChange: (value) {
        ref.read(prayerSettingsProvider.notifier).set24HourFormat(value: value);
      },
      label: Text(l10n.use24HourFormat),
    );
  }
}
