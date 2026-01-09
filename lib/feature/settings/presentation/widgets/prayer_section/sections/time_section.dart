import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/hooks/hooks.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/sections/custom_parameters_section.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Widget for the prayer time settings section.
class PrayerSettingsTimeSection extends HookConsumerWidget {
  /// Creates a new [PrayerSettingsTimeSection] instance.
  const PrayerSettingsTimeSection({required this.maxWidth, super.key});

  /// The maximum width of the section.
  final double maxWidth;

  // Prayers that support Iqamah adjustment
  static const List<Prayer> _kIqamahPrayers = <Prayer>[
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerSettings = ref.read(prayerSettingsProvider).value;
    final values = prayerSettings?.iqamahSettings;

    // Controllers and focus nodes keyed by prayer
    final controllers = useMemoized(
      () => {for (final p in _kIqamahPrayers) p: TextEditingController()},
    );
    final focusNodes = useMemoized(
      () => {for (final p in _kIqamahPrayers) p: FocusNode()},
    );

    // Method controller
    final methodController = useFSelectController<CalculationMethod>(
      initialValue: prayerSettings?.method,
    );

    // Track initial values and unsaved state
    final initialIqamahValues = useMemoized(() => <Prayer, String>{});
    final unsavedPrayers = useMemoized(
      () => ValueNotifier<Set<Prayer>>(<Prayer>{}),
    );

    // Force rebuild when unsavedPrayers changes (useListenable triggers rebuild)
    useListenable(unsavedPrayers);

    // Initialize controllers and add listeners
    useEffect(
      () {
        for (final p in _kIqamahPrayers) {
          final v = (values?[p] ?? 0).toString();
          controllers[p]!.text = v;
          initialIqamahValues[p] = v;

          void handleControllerChange() {
            final controller = controllers[p]!;
            final initial = initialIqamahValues[p] ?? '';
            final current = controller.text.trim();
            final isUnsaved = current != initial;
            final set = unsavedPrayers.value;
            final hasUnsavedEntry = set.contains(p);

            if (isUnsaved && !hasUnsavedEntry) {
              unsavedPrayers.value = {...set}..add(p);
            } else if (!isUnsaved && hasUnsavedEntry) {
              unsavedPrayers.value = {...set}..remove(p);
            }
          }

          controllers[p]!.addListener(handleControllerChange);
        }

        return () {
          for (final c in controllers.values) {
            c.dispose();
          }
          for (final f in focusNodes.values) {
            f.dispose();
          }
          unsavedPrayers.dispose();
        };
      },
      const [],
    );

    // Add focus listeners for auto-save
    useEffect(
      () {
        void createFocusListener(Prayer p) {
          focusNodes[p]!.addListener(() {
            if (!focusNodes[p]!.hasFocus) {
              _saveTextField(
                context,
                ref,
                p,
                controllers,
                initialIqamahValues,
                unsavedPrayers,
              );
            }
          });
        }

        for (final p in _kIqamahPrayers) {
          createFocusListener(p);
        }
        return null;
      },
      const [],
    );

    // Listen for external updates to iqamah settings and sync controllers
    ref.listen<Map<Prayer, int>?>(
      prayerSettingsProvider.select(
        (s) => s.value?.iqamahSettings,
      ),
      (prev, next) {
        if (next == null) return;
        for (final p in _kIqamahPrayers) {
          final newValue = (next[p] ?? 0).toString();
          final c = controllers[p]!;
          if (c.text != newValue) {
            c.text = newValue;
          }
          initialIqamahValues[p] = newValue;
          // Remove unsaved flag if now in sync
          final currentUnsaved = unsavedPrayers.value;
          if (currentUnsaved.contains(p) && c.text.trim() == newValue) {
            unsavedPrayers.value = {...currentUnsaved}..remove(p);
          }
        }
      },
    );

    // Keep calculation method selection in sync
    ref.listen<CalculationMethod?>(
      prayerSettingsProvider.select((s) => s.value?.method),
      (prev, next) {
        if (next != null && methodController.value != next) {
          methodController.value = next;
        }
      },
    );

    void saveUnsavedPrayers() {
      final list = List<Prayer>.from(unsavedPrayers.value);
      for (final p in list) {
        _saveTextField(
          context,
          ref,
          p,
          controllers,
          initialIqamahValues,
          unsavedPrayers,
        );
      }
    }

    final is24Hours = ref.watch(
      prayerSettingsProvider.select(
        (value) => value.value?.is24Hours,
      ),
    );
    return SettingsSection(
      crossAxisAlignment: .center,
      title: context.l10n.timeSectionTitle,
      subtitle: context.l10n.timeSectionSubtitle,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          spacing: 20,
          children: [
            FCard(
              title: Text(context.l10n.calculationMethod),
              child: Column(
                children: [
                  _buildCalculationMethodSelector(
                    context,
                    ref,
                    methodController,
                  ),
                  PrayerSettingsCustomParametersCard(maxWidth: maxWidth),
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
                      .set24HourFormat(value: value);
                },
                label: Text(context.l10n.use24HourFormat),
              ),
            ),
            FCard(
              title: Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text(context.l10n.iqamahAdjustment),
                  FTooltip(
                    tipBuilder: (ctx, ctrl) => Text(context.l10n.save),
                    child: FButton(
                      prefix: const Icon(FIcons.save),
                      onPress: unsavedPrayers.value.isEmpty
                          ? null
                          : saveUnsavedPrayers,
                      child: Text(context.l10n.save),
                    ),
                  ),
                ],
              ),
              child: FTileGroup(
                label: Row(
                  children: [
                    Icon(
                      FIcons.info,
                      size: 14,
                      color: context.theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: AppSpacing.xs),
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
                        controller: controllers[p]!,
                        focusNode: focusNodes[p]!,
                        allowSigned: false,
                        onDelta: (delta) =>
                            _changeIqamah(controllers[p]!, delta),
                        onSave: () => _saveTextField(
                          context,
                          ref,
                          p,
                          controllers,
                          initialIqamahValues,
                          unsavedPrayers,
                        ),
                        onReset: () => _resetIqamah(
                          context,
                          ref,
                          p,
                          controllers[p]!,
                          controllers,
                          initialIqamahValues,
                          unsavedPrayers,
                        ),
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
          const SizedBox(width: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64, maxWidth: 120),
            child: FTextField(
              control: .managed(controller: controller),
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
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
          const SizedBox(width: AppSpacing.xs),
          FButton.icon(
            style: FButtonStyle.ghost(),
            onPress: () => onDelta(1),
            child: const Icon(FIcons.plus),
          ),
          const SizedBox(width: AppSpacing.xs),
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

// -- Helper functions for PrayerSettingsTimeSection --

Widget _buildCalculationMethodSelector(
  BuildContext context,
  WidgetRef ref,
  FSelectController<CalculationMethod> methodController,
) {
  return FSelect<CalculationMethod>.search(
    control: .managed(
      controller: methodController,
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
    ),
    items: {
      for (final method in CalculationMethod.values)
        method.getLocaleName(context.l10n): method,
    },
    autofocus: true,
    label: Text(context.l10n.calculationMethod),
  filter: (query) => CalculationMethod.values.where(
      (method) => method
          .getLocaleName(context.l10n)
          .toLowerCase()
          .contains(query.toLowerCase()),
    ),
  );
}

void _changeIqamah(TextEditingController controller, int delta) {
  final current = int.tryParse(controller.text.trim()) ?? 0;
  final next = current + delta;
  controller.text = next.toString();
}

void _resetIqamah(
  BuildContext context,
  WidgetRef ref,
  Prayer prayer,
  TextEditingController controller,
  Map<Prayer, TextEditingController> controllers,
  Map<Prayer, String> initialIqamahValues,
  ValueNotifier<Set<Prayer>> unsavedPrayers,
) {
  controller.text = '0';
  _saveTextField(
    context,
    ref,
    prayer,
    controllers,
    initialIqamahValues,
    unsavedPrayers,
  );
}

void _saveTextField(
  BuildContext context,
  WidgetRef ref,
  Prayer prayer,
  Map<Prayer, TextEditingController> controllers,
  Map<Prayer, String> initialIqamahValues,
  ValueNotifier<Set<Prayer>> unsavedPrayers,
) {
  final controller = controllers[prayer]!;
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

    if (initialIqamahValues[prayer] != normalized ||
        unsavedPrayers.value.contains(prayer)) {
      initialIqamahValues[prayer] = normalized;
      unsavedPrayers.value = {...unsavedPrayers.value}..remove(prayer);
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
