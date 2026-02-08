import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/sections/custom_parameters_section.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/calculation_method_selector.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/iqamah_helpers.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/prayer_iqamah_tile.dart';
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
    final prayerSettings = ref.watch(prayerSettingsProvider).value;
    final values = prayerSettings?.iqamahSettings;

    // Controllers and focus nodes keyed by prayer
    final controllers = useMemoized(
      () => {for (final p in _kIqamahPrayers) p: TextEditingController()},
    );
    final focusNodes = useMemoized(
      () => {for (final p in _kIqamahPrayers) p: FocusNode()},
    );

    // Method controller
    final method = prayerSettings?.method ?? CalculationMethod.ummAlQura;

    // Track initial values and unsaved state
    final initialIqamahValues = useMemoized(() => <Prayer, String>{});
    final unsavedPrayers = useMemoized(
      () => ValueNotifier<Set<Prayer>>(<Prayer>{}),
    );

    // Force rebuild when unsavedPrayers changes (useListenable works)
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
              saveIqamahField(
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

        _kIqamahPrayers.forEach(createFocusListener);
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

    void saveUnsavedPrayers() {
      final list = List<Prayer>.from(unsavedPrayers.value);
      for (final p in list) {
        saveIqamahField(
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
      crossAxisAlignment: CrossAxisAlignment.center,
      title: context.l10n.timeSectionTitle,
      subtitle: context.l10n.timeSectionSubtitle,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          spacing: AppSpacing.xl,
          children: [
            FCard(
              title: Text(context.l10n.calculationMethod),
              child: Column(
                children: [
                  buildCalculationMethodSelector(
                    context,
                    ref,
                    method,
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
                      (p) => PrayerIqamahTile(
                        key: ValueKey(p),
                        prayer: p,
                        controller: controllers[p]!,
                        focusNode: focusNodes[p]!,
                        allowSigned: false,
                        onDelta: (delta) =>
                            changeIqamah(controllers[p]!, delta),
                        onSave: () => saveIqamahField(
                          context,
                          ref,
                          p,
                          controllers,
                          initialIqamahValues,
                          unsavedPrayers,
                        ),
                        onReset: () => resetIqamah(
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
