import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/iqamah_draft_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/calculation_method_selector.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/custom_parameters_content.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/prayer_iqamah_tile.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Calculation method, custom parameters, and time format controls.
class PrayerCalculationSettings extends ConsumerWidget {
  /// Creates [PrayerCalculationSettings].
  const PrayerCalculationSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Column(
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
              const CustomParametersAccordion(),
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
      ],
    );
  }
}

/// Iqamah offset editors.
class PrayerIqamahSettings extends HookConsumerWidget {
  /// Creates [PrayerIqamahSettings].
  const PrayerIqamahSettings({this.showSaveButton = false, super.key});

  /// When true, shows a save action for unsaved iqamah drafts (settings screen).
  final bool showSaveButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unsavedPrayers = ref.watch(
      iqamahDraftProvider.select((draft) => draft.unsavedPrayers),
    );
    final draft = ref.read(iqamahDraftProvider.notifier);
    final l10n = context.l10n;

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

    final saveButton = showSaveButton
        ? NonSelectable(
            child: FTooltip(
              tipBuilder: (ctx, ctrl) => Text(l10n.save),
              child: FButton(
                variant: unsavedPrayers.isEmpty ? .outline : .primary,
                prefix: const Icon(FLucideIcons.save, size: 16),
                semanticsTooltip: l10n.save,
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
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader = !isContainerAtLeast(
          context,
          constraints,
          FBreakpoint.sm,
        );

        if (!stackHeader || saveButton == null) {
          return SettingsGroup(
            title: l10n.iqamahAdjustment,
            subtitle: l10n.iqamahAfterAdhan,
            trailing: saveButton,
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
          );
        }

        return SettingsGroup(
          title: l10n.iqamahAdjustment,
          subtitle: l10n.iqamahAfterAdhan,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: saveButton,
              ),
              IqamahPrayerList(
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
            ],
          ),
        );
      },
    );
  }
}

/// Prayer time calculation and iqamah settings with optional section chrome.
class PrayerTimeSettings extends ConsumerWidget {
  /// Creates [PrayerTimeSettings].
  const PrayerTimeSettings({this.chrome = SettingsChrome.section, super.key});

  /// Outer card chrome for the settings screen.
  final SettingsChrome chrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        PrayerCalculationSettings(),
        FDivider(),
        PrayerIqamahSettings(showSaveButton: true),
      ],
    );

    if (chrome == SettingsChrome.none) return content;

    final l10n = context.l10n;
    return SettingsSection(
      crossAxisAlignment: CrossAxisAlignment.center,
      title: l10n.timeSectionTitle,
      subtitle: l10n.timeSectionSubtitle,
      child: content,
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
