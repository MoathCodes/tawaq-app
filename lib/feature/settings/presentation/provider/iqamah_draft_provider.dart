import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';

part 'iqamah_draft_provider.g.dart';

/// Prayers editable in the iqamah adjustment section.
const List<Prayer> kIqamahDraftPrayers = <Prayer>[
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// Draft edit state for the iqamah adjustment section.
class IqamahDraftState {
  /// Creates [IqamahDraftState].
  const IqamahDraftState({required this.unsavedPrayers});

  /// Prayers whose text field differs from the last saved value.
  final Set<Prayer> unsavedPrayers;
}

/// Manages per-prayer iqamah draft controllers and unsaved tracking.
@riverpod
class IqamahDraft extends _$IqamahDraft {
  final Map<Prayer, TextEditingController> _controllers =
      <Prayer, TextEditingController>{};
  final Map<Prayer, String> _initialValues = <Prayer, String>{};
  final Map<Prayer, FocusNode> _focusNodes = <Prayer, FocusNode>{};
  final Map<Prayer, VoidCallback> _controllerListeners =
      <Prayer, VoidCallback>{};

  @override
  IqamahDraftState build() {
    ref.onDispose(_dispose);

    final values = ref.read(prayerSettingsProvider).value?.iqamahSettings;
    _initControllers(values);

    ref.listen<Map<Prayer, int>?>(
      prayerSettingsProvider.select(
        (s) => s.value?.iqamahSettings,
      ),
      (previous, next) {
        if (next != null) {
          _syncFromProvider(previous, next);
        }
      },
    );

    return const IqamahDraftState(unsavedPrayers: <Prayer>{});
  }

  /// Text controller for [prayer].
  TextEditingController controller(Prayer prayer) => _controllers[prayer]!;

  /// Focus node for [prayer].
  FocusNode focusNode(Prayer prayer) => _focusNodes[prayer]!;

  /// Whether [prayer] has unsaved edits.
  bool isUnsaved(Prayer prayer) => state.unsavedPrayers.contains(prayer);

  /// Applies a +/- delta to [prayer]'s text field.
  void applyDelta(Prayer prayer, int delta) {
    final controller = _controllers[prayer]!;
    final current = int.tryParse(controller.text.trim()) ?? 0;
    controller.text = (current + delta).toString();
  }

  /// Saves [prayer] to persisted settings.
  void save(BuildContext context, Prayer prayer) {
    final controller = _controllers[prayer]!;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final value = int.tryParse(text);
    if (value == null) return;

    ref
        .read(prayerSettingsProvider.notifier)
        .updatePrayerIqamahTime(prayer, value);

    final normalized = value.toString();
    if (controller.text != normalized) {
      controller.text = normalized;
    }

    final initial = _initialValues[prayer];
    if (initial != normalized || state.unsavedPrayers.contains(prayer)) {
      _initialValues[prayer] = normalized;
      _setUnsaved(prayer, unsaved: false);
    }

    final l10n = context.l10n;
    showFToast(
      context: context,
      title: Text(l10n.iqamahSavedTitle),
      description: Text(
        l10n.iqamahSavedForPrayer(prayer.getLocaleName(l10n)),
      ),
    );
  }

  /// Resets [prayer] to zero and saves.
  void reset(BuildContext context, Prayer prayer) {
    _controllers[prayer]!.text = '0';
    save(context, prayer);
  }

  /// Saves every prayer that currently has unsaved edits.
  void saveAll(BuildContext context) {
    for (final prayer in List<Prayer>.from(state.unsavedPrayers)) {
      save(context, prayer);
    }
  }

  /// Commits unsaved iqamah offsets to [prayerSettingsProvider] without toasts.
  ///
  /// Used by onboarding finish — the draft is only a text-field buffer.
  void commitPending() {
    for (final prayer in List<Prayer>.from(state.unsavedPrayers)) {
      final controller = _controllers[prayer]!;
      final text = controller.text.trim();
      if (text.isEmpty) continue;

      final value = int.tryParse(text);
      if (value == null) continue;

      ref
          .read(prayerSettingsProvider.notifier)
          .updatePrayerIqamahTime(prayer, value);

      final normalized = value.toString();
      if (controller.text != normalized) {
        controller.text = normalized;
      }
      _initialValues[prayer] = normalized;
      _setUnsaved(prayer, unsaved: false);
    }
  }

  void _initControllers(Map<Prayer, int>? values) {
    for (final prayer in kIqamahDraftPrayers) {
      final value = (values?[prayer] ?? 0).toString();
      final controller = TextEditingController(text: value);
      final focusNode = FocusNode();
      _controllers[prayer] = controller;
      _initialValues[prayer] = value;
      _focusNodes[prayer] = focusNode;

      void handleChange() => _handleControllerChange(prayer);
      controller.addListener(handleChange);
      _controllerListeners[prayer] = handleChange;
    }
  }

  void _handleControllerChange(Prayer prayer) {
    final controller = _controllers[prayer]!;
    final initial = _initialValues[prayer] ?? '';
    final current = controller.text.trim();
    _setUnsaved(prayer, unsaved: current != initial);
  }

  void _setUnsaved(Prayer prayer, {required bool unsaved}) {
    final hasEntry = state.unsavedPrayers.contains(prayer);
    if (unsaved == hasEntry) return;

    final next = {...state.unsavedPrayers};
    if (unsaved) {
      next.add(prayer);
    } else {
      next.remove(prayer);
    }
    state = IqamahDraftState(unsavedPrayers: next);
  }

  void _syncFromProvider(
    Map<Prayer, int>? previous,
    Map<Prayer, int> next,
  ) {
    for (final prayer in kIqamahDraftPrayers) {
      if (state.unsavedPrayers.contains(prayer)) continue;

      final newMinutes = next[prayer] ?? 0;
      if (previous != null && (previous[prayer] ?? 0) == newMinutes) {
        continue;
      }

      final newValue = newMinutes.toString();
      final controller = _controllers[prayer]!;
      // Update baseline before text so the controller listener does not
      // treat the sync as a user edit.
      _initialValues[prayer] = newValue;
      if (controller.text != newValue) {
        controller.text = newValue;
      }
    }
  }

  void _dispose() {
    for (final entry in _controllerListeners.entries) {
      _controllers[entry.key]?.removeListener(entry.value);
    }
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _controllers.clear();
    _initialValues.clear();
    _focusNodes.clear();
    _controllerListeners.clear();
  }
}
