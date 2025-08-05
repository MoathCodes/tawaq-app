import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';

class TimeSection extends ConsumerStatefulWidget {
  final double maxWidth;

  const TimeSection({super.key, required this.maxWidth});

  @override
  ConsumerState<TimeSection> createState() => _TimeSectionState();
}

class _TimeSectionState extends ConsumerState<TimeSection> {
  late TextEditingController _fajrIqamahController;
  late TextEditingController _duhurIqamahController;
  late TextEditingController _asrIqamahController;
  late TextEditingController _magrihbIqamahController;
  late TextEditingController _ishaIqamahController;

  @override
  Widget build(BuildContext context) {
    final prayerSettings =
        ref.watch(prayerSettingsNotifierProvider.select((value) => (
              is24Hours: value.valueOrNull?.is24Hours,
              iqamahSettings: value.valueOrNull?.iqamahSettings
            )));
    return SettingsSection(
      crossAxisAlignment: CrossAxisAlignment.center,
      title: "عرض الأوقات والإقامة",
      subtitle: "تنسيق عرض الوقت وأوقات الإقامة لكل صلاة.",
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Column(spacing: 20, children: [
          FCard(
            title: const Text("تنسيق الوقت"),
            child: FSwitch(
              value: prayerSettings.is24Hours ?? false, // Placeholder value
              onChange: (value) {
                ref
                    .read(prayerSettingsNotifierProvider.notifier)
                    .set24HourFormat(value);
              },
              label: const Text("استخدام نظام 24 ساعة"),
            ),
          ),
          Row(
            spacing: 8,
            // crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: FTileGroup(
                  label: const Text("ضبط الإقامة"),
                  children: Prayer.values
                      .where((element) =>
                          element != Prayer.fajrAfter &&
                          element != Prayer.ishaBefore &&
                          element != Prayer.sunrise)
                      .map((e) => _buildPrayerTimeTile(
                          e, _getPrayerController(e), false))
                      .toList()
                      .cast<FTileMixin>(),
                ),
              ),
              Expanded(
                child: FTileGroup(
                  label: const Text("ضبط الأذان"),
                  children: Prayer.values
                      .where((element) =>
                          element != Prayer.fajrAfter &&
                          element != Prayer.ishaBefore &&
                          element != Prayer.sunrise)
                      .map((e) => _buildPrayerTimeTile(
                          e, _getPrayerController(e), true))
                      .toList()
                      .cast<FTileMixin>(),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _fajrIqamahController.dispose();
    _duhurIqamahController.dispose();
    _asrIqamahController.dispose();
    _magrihbIqamahController.dispose();
    _ishaIqamahController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final values =
        ref.read(prayerSettingsNotifierProvider).value?.iqamahSettings;
    _fajrIqamahController =
        TextEditingController(text: (values?[Prayer.fajr] ?? '').toString());
    _duhurIqamahController =
        TextEditingController(text: (values?[Prayer.dhuhr] ?? '').toString());
    _asrIqamahController =
        TextEditingController(text: (values?[Prayer.asr] ?? '').toString());
    _magrihbIqamahController =
        TextEditingController(text: (values?[Prayer.maghrib] ?? '').toString());
    _ishaIqamahController =
        TextEditingController(text: (values?[Prayer.isha] ?? '').toString());
  }

  Widget _buildPrayerTimeTile(
      Prayer prayer, TextEditingController controller, bool allowSigned) {
    final theme = context.theme;
    return FTile(
      key: ValueKey(prayer),
      prefix: Icon(
        prayer.icon,
        size: 32,
      ),
      title: Text(
        prayer.getLocaleName(context.l10n),
        style: theme.typography.xl.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colors.foreground,
        ),
      ),
      suffix: SizedBox(
        width: 120,
        child: FTextField(
          controller: controller,

          keyboardType: const TextInputType.numberWithOptions(
              decimal: false, signed: false),
          inputFormatters: [
            allowSigned
                ? FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*$'))
                : FilteringTextInputFormatter.digitsOnly
          ],
          onEditingComplete: () => _saveTextField(prayer),
          hint: allowSigned ? "20 أو -10" : null,

          onSubmit: (value) => _saveTextField(prayer),
          // suffixBuilder: (context, value, child) => ,
          description: Text(
            "دقيقة",
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }

  TextEditingController _getPrayerController(Prayer prayer) => switch (prayer) {
        Prayer.fajr => _fajrIqamahController,
        Prayer.dhuhr => _duhurIqamahController,
        Prayer.asr => _asrIqamahController,
        Prayer.maghrib => _magrihbIqamahController,
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
