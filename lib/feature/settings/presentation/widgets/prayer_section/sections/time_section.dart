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
  const PrayerSettingsTimeSection({required this.maxWidth, super.key});
  final double maxWidth;

  @override
  ConsumerState<PrayerSettingsTimeSection> createState() => _TimeSectionState();
}

class _PrayerIqamahTile extends StatelessWidget implements FTileMixin {
  const _PrayerIqamahTile({
    required this.prayer,
    required this.controller,
    required this.focusNode,
    required this.allowSigned,
    required this.onDelta,
    required this.onSave,
    required this.onReset,
    super.key,
  });
  final Prayer prayer;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool allowSigned;
  final ValueChanged<int> onDelta;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final textStyle = theme.typography.sm.copyWith(
      color: colors.foreground,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return FTile(
      prefix: Icon(prayer.icon, size: 32),
      title: Text(
        prayer.getLocaleName(context.l10n),
        style: theme.typography.xl.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colors.foreground,
        ),
      ),
      details: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FButton.icon(
            style: FButtonStyle.ghost(),
            onPress: () => onDelta(-1),
            child: const Icon(FIcons.minus),
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64, maxWidth: 120),
            child: FTextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(),
              inputFormatters: [
                if (allowSigned)
                  FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*$'))
                else
                  FilteringTextInputFormatter.digitsOnly,
              ],
              onEditingComplete: onSave,
              onSubmit: (_) => onSave(),
              suffixBuilder: (context, value, child) => Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                child: Text(context.l10n.minute, style: textStyle),
              ),
            ),
          ),
          const SizedBox(width: 4),
          FButton.icon(
            style: FButtonStyle.ghost(),
            onPress: () => onDelta(1),
            child: const Icon(FIcons.plus),
          ),
          const SizedBox(width: 6),
          FTooltip(
            tipBuilder: (context, controller) =>
                Text(context.l10n.resetToDefaults),
            child: FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: onReset,
              child: const Icon(FIcons.rotateCcw),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSectionState extends ConsumerState<PrayerSettingsTimeSection>
    with TickerProviderStateMixin {
  // Prayers that support Iqamah adjustment
  static const List<Prayer> _kIqamahPrayers = <Prayer>[
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  // Controllers and focus nodes keyed by prayer
  late final Map<Prayer, TextEditingController> _controllers = {
    for (final p in _kIqamahPrayers) p: TextEditingController(),
  };
  late final Map<Prayer, FocusNode> _focusNodes = {
    for (final p in _kIqamahPrayers) p: FocusNode(),
  };

  late FSelectController<CalculationMethod> _methodController;
  final Map<Prayer, String> _initialIqamahValues = <Prayer, String>{};
  // Track unsaved state without rebuilding the whole widget
  final ValueNotifier<Set<Prayer>> _unsavedPrayers = ValueNotifier<Set<Prayer>>(
    <Prayer>{},
  );

  @override
  Widget build(BuildContext context) {
    // Listen for external updates to iqamah settings and sync controllers
    ref.listen<Map<Prayer, int>?>(
      prayerSettingsProvider.select(
        (s) => s.value?.iqamahSettings,
      ),
      (prev, next) {
        if (next == null) return;
        for (final p in _kIqamahPrayers) {
          final newValue = (next[p] ?? 0).toString();
          final c = _controllers[p]!;
          if (c.text != newValue) {
            c.text = newValue;
          }
          _initialIqamahValues[p] = newValue;
          // Remove unsaved flag if now in sync
          final currentUnsaved = _unsavedPrayers.value;
          if (currentUnsaved.contains(p) && c.text.trim() == newValue) {
            _unsavedPrayers.value = {...currentUnsaved}..remove(p);
          }
        }
      },
    );

    // Keep calculation method selection in sync
    ref.listen<CalculationMethod?>(
      prayerSettingsProvider.select((s) => s.value?.method),
      (prev, next) {
        if (next != null && _methodController.value != next) {
          _methodController.value = next;
        }
      },
    );

    final is24Hours = ref.watch(
      prayerSettingsProvider.select(
        (value) => value.value?.is24Hours,
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
              child: Column(
                children: [
                  _buildCalculationMethodSelector(),
                  PrayerSettingsCustomParametersCard(maxWidth: widget.maxWidth),
                ],
              ),
            ),
            FCard(
              title: Text(context.l10n.timeFormat),
              child: FSwitch(
                value: is24Hours ?? false,
                onChange: (value) {
                  ref
                      .read(prayerSettingsProvider.notifier)
                      .set24HourFormat(value);
                },
                label: Text(context.l10n.use24HourFormat),
              ),
            ),
            FCard(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.iqamahAdjustment),
                  ValueListenableBuilder<Set<Prayer>>(
                    valueListenable: _unsavedPrayers,
                    builder: (_, set, __) => FTooltip(
                      tipBuilder: (context, controller) =>
                          Text(context.l10n.save),
                      child: FButton(
                        prefix: const Icon(FIcons.save),
                        onPress: set.isEmpty ? null : _saveUnsavedPrayers,
                        child: Text(context.l10n.save),
                      ),
                    ),
                  ),
                ],
              ),
              child: FTileGroup(
                // Visual grouping of prayers with concise instruction
                label: Row(
                  children: [
                    Icon(
                      FIcons.info,
                      size: 14,
                      color: context.theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.l10n.iqamahAfterAdhan,
                        style: context.theme.typography.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                children: _kIqamahPrayers
                    .map(
                      (p) => _PrayerIqamahTile(
                        key: ValueKey(p),
                        prayer: p,
                        controller: _controllers[p]!,
                        focusNode: _focusNodes[p]!,
                        allowSigned: false,
                        onDelta: (delta) =>
                            _changeIqamah(p, _controllers[p]!, delta),
                        onSave: () => _saveTextField(p),
                        onReset: () => _resetIqamah(p, _controllers[p]!),
                      ),
                    )
                    .toList()
                    .cast<FTileMixin>(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    _unsavedPrayers.dispose();
    _methodController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final prayerSettings = ref.read(prayerSettingsProvider).value;
    final values = prayerSettings?.iqamahSettings;

    // Seed controllers and initial values
    for (final p in _kIqamahPrayers) {
      final v = (values?[p] ?? 0).toString();
      _controllers[p]!.text = v;
      _initialIqamahValues[p] = v;
      _controllers[p]!.addListener(() => _handleControllerChange(p));
      _focusNodes[p]!.addListener(() {
        if (!_focusNodes[p]!.hasFocus) _saveTextField(p);
      });
    }

    _methodController = FSelectController(
      vsync: this,
      value: prayerSettings?.method,
    );
  }

  Widget _buildCalculationMethodSelector() {
    return FSelect<CalculationMethod>.search(
      items: {
        for (final method in CalculationMethod.values)
          method.getLocaleName(context.l10n): method,
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
              .read(prayerSettingsProvider.notifier)
              .update(
                (settings) => settings.copyWith(
                  method: value,
                  customParameters: value.parameters,
                ),
              );
        }
      },
    );
  }

  // Removed tile/stepper builders; logic moved into PrayerIqamahTile below.

  void _changeIqamah(
    Prayer prayer,
    TextEditingController controller,
    int delta,
  ) {
    final current = int.tryParse(controller.text.trim()) ?? 0;
    final next = current + delta;
    controller.text = next.toString();
  }

  void _handleControllerChange(Prayer prayer) {
    final controller = _controllers[prayer]!;
    final initial = _initialIqamahValues[prayer] ?? '';
    final current = controller.text.trim();
    final isUnsaved = current != initial;
    final set = _unsavedPrayers.value;
    final hasUnsavedEntry = set.contains(prayer);

    if (isUnsaved && !hasUnsavedEntry) {
      _unsavedPrayers.value = {...set}..add(prayer);
    } else if (!isUnsaved && hasUnsavedEntry) {
      _unsavedPrayers.value = {...set}..remove(prayer);
    }
  }

  // _registerPrayerController removed; controllers are now registered in initState.

  void _resetIqamah(Prayer prayer, TextEditingController controller) {
    controller.text = '0';
    _saveTextField(prayer);
  }

  void _saveTextField(Prayer prayer) {
    final controller = _controllers[prayer]!;
    final text = controller.text.trim();

    // If the field is empty, do not update the provider yet.
    if (text.isEmpty) return;

    final value = int.tryParse(text);
    if (value != null) {
      ref
          .read(prayerSettingsProvider.notifier)
          .updatePrayerIqamahTime(prayer, value);

      final normalized = value.toString();
      if (controller.text != normalized) {
        controller.text = normalized;
      }

      if (_initialIqamahValues[prayer] != normalized ||
          _unsavedPrayers.value.contains(prayer)) {
        _initialIqamahValues[prayer] = normalized;
        _unsavedPrayers.value = {..._unsavedPrayers.value}..remove(prayer);
      }
    }
    showFToast(
      context: context,
      title: Text(context.l10n.iqamahSavedTitle),
      description: Text(
        "${context.l10n.iqamahSavedDescription} '${prayer.getLocaleName(context.l10n)}'",
      ),
    );
  }

  void _saveUnsavedPrayers() {
    final unsavedPrayers = List<Prayer>.from(_unsavedPrayers.value);
    for (final prayer in unsavedPrayers) {
      _saveTextField(prayer);
    }
  }
}
