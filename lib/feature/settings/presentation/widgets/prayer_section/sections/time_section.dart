import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/sections/custom_parameters_section.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';

class PrayerSettingsTimeSection extends ConsumerStatefulWidget {
  final double maxWidth;

  const PrayerSettingsTimeSection({super.key, required this.maxWidth});

  @override
  ConsumerState<PrayerSettingsTimeSection> createState() => _TimeSectionState();
}

class _TimeSectionState extends ConsumerState<PrayerSettingsTimeSection>
    with TickerProviderStateMixin {
  late TextEditingController _fajrIqamahController;
  late TextEditingController _dhuhrIqamahController;
  late TextEditingController _asrIqamahController;
  late TextEditingController _maghribIqamahController;
  late TextEditingController _ishaIqamahController;

  late FSelectController<CalculationMethod> _methodController;

  @override
  Widget build(BuildContext context) {
    final prayerSettings = ref.watch(
      prayerSettingsNotifierProvider.select(
        (value) => (
          is24Hours: value.valueOrNull?.is24Hours,
          iqamahSettings: value.valueOrNull?.iqamahSettings,
        ),
      ),
    );
    return SettingsSection(
      crossAxisAlignment: CrossAxisAlignment.center,
      title: context.l10n.timeSectionTitle,
      subtitle: context.l10n.timeSectionSubtitle,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Column(
          spacing: 20,
          children: [
            FCard(
              title: Text(context.l10n.calculationMethod),
              child: _buildCalculationMethodSelector(),
            ),
            PrayerSettingsCustomParametersCard(maxWidth: widget.maxWidth),
            FCard(
              title: Text(context.l10n.timeFormat),
              child: FSwitch(
                value: prayerSettings.is24Hours ?? false, // Placeholder value
                onChange: (value) {
                  ref
                      .read(prayerSettingsNotifierProvider.notifier)
                      .set24HourFormat(value);
                },
                label: Text(context.l10n.use24HourFormat),
              ),
            ),
            Row(
              spacing: 8,
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: FTileGroup(
                    label: Text(context.l10n.iqamahAdjustment),
                    children: Prayer.values
                        .where(
                          (element) =>
                              element != Prayer.fajrAfter &&
                              element != Prayer.ishaBefore &&
                              element != Prayer.sunrise,
                        )
                        .map(
                          (e) => _buildPrayerTimeTile(
                            e,
                            _getPrayerController(e),
                            false,
                          ),
                        )
                        .toList()
                        .cast<FTileMixin>(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fajrIqamahController.dispose();
    _dhuhrIqamahController.dispose();
    _asrIqamahController.dispose();
    _maghribIqamahController.dispose();
    _ishaIqamahController.dispose();
    _methodController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final prayerSettings = ref.read(prayerSettingsNotifierProvider);
    final values = prayerSettings.value?.iqamahSettings;
    _fajrIqamahController = TextEditingController(
      text: (values?[Prayer.fajr] ?? '').toString(),
    );
    _dhuhrIqamahController = TextEditingController(
      text: (values?[Prayer.dhuhr] ?? '').toString(),
    );
    _asrIqamahController = TextEditingController(
      text: (values?[Prayer.asr] ?? '').toString(),
    );
    _maghribIqamahController = TextEditingController(
      text: (values?[Prayer.maghrib] ?? '').toString(),
    );
    _ishaIqamahController = TextEditingController(
      text: (values?[Prayer.isha] ?? '').toString(),
    );

    _methodController = FSelectController(
      vsync: this,
      value: prayerSettings.value?.method,
    );
  }

  Widget _buildCalculationMethodSelector() {
    return FSelect<CalculationMethod>.search(
      items: {
        for (final method in CalculationMethod.values) method.getLocaleName(context.l10n): method,
      },
      controller: _methodController,
      autofocus: true,
      label: Text(context.l10n.calculationMethod),
      // format: (value) => value.getLocaleName(context.l10n),
      filter: (query) => CalculationMethod.values.where(
        (method) => method
            .getLocaleName(context.l10n)
            .toLowerCase()
            .contains(query.toLowerCase()),
      ),

      // builder: (context, data) => data.values
      //     .map((method) => FSelectItem(
      //           method.getLocaleName(context.l10n),
      //           method,
      //         ))
      //     .toList(),
      onChange: (value) {
        if (value != null) {
          ref
              .read(prayerSettingsNotifierProvider.notifier)
              .update((settings) => settings.copyWith(method: value));
        }
      },
    );
  }

  Widget _buildPrayerTimeTile(
    Prayer prayer,
    TextEditingController controller,
    bool allowSigned,
  ) {
    final theme = context.theme;
    return FTile(
      key: ValueKey(prayer),
      prefix: Icon(prayer.icon, size: 32),
      title: Text(
        prayer.getLocaleName(context.l10n),
        style: theme.typography.xl.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colors.foreground,
        ),
      ),
      suffix: Row(
        children: [
          const Expanded(child: SizedBox.shrink()),
          Expanded(
            child: FTextField(
              controller: controller,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
                signed: false,
              ),
              inputFormatters: [
                allowSigned
                    ? FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*$'))
                    : FilteringTextInputFormatter.digitsOnly,
              ],
              onEditingComplete: () => _saveTextField(prayer),
              hint: allowSigned ? context.l10n.signedExampleHint : null,

              onSubmit: (value) => _saveTextField(prayer),
              // suffixBuilder: (context, value, child) => ,
              description: Text(
                context.l10n.minute,
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ),
          Expanded(
            child: FTextField(
              controller: controller,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
                signed: false,
              ),
              inputFormatters: [
                allowSigned
                    ? FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*$'))
                    : FilteringTextInputFormatter.digitsOnly,
              ],
              onEditingComplete: () => _saveTextField(prayer),
              hint: allowSigned ? context.l10n.signedExampleHint : null,

              onSubmit: (value) => _saveTextField(prayer),
              // suffixBuilder: (context, value, child) => ,
              description: Text(
                context.l10n.minute,
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ),
          FButton.icon(onPress: () {}, child: const Icon(FIcons.volume2)),
        ],
      ),
    );
  }

  TextEditingController _getPrayerController(Prayer prayer) => switch (prayer) {
    Prayer.fajr => _fajrIqamahController,
    Prayer.dhuhr => _dhuhrIqamahController,
    Prayer.asr => _asrIqamahController,
    Prayer.maghrib => _maghribIqamahController,
    Prayer.isha => _ishaIqamahController,
    _ => throw UnimplementedError(),
  };

  void _saveTextField(Prayer prayer) {
    final controller = _getPrayerController(prayer);
    final text = controller.text.trim();

    // If the field is empty, do not update the provider yet.
    if (text.isEmpty) return;

    final value = int.tryParse(text);
    if (value != null) {
      ref
          .read(prayerSettingsNotifierProvider.notifier)
          .updatePrayerIqamahTime(prayer, value);
    }
  }
}
