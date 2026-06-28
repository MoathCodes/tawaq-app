import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/hooks/hooks.dart';

/// A volume slider (0–100) whose local value is synced to a persisted volume
/// and whose preview writes are debounced during a drag.
///
/// [persistedVolume] is the authoritative volume from settings. The slider's
/// local value mirrors it via [useEffect] whenever it changes externally, so
/// the thumb always reflects the persisted value (e.g. when volume is changed
/// from another surface, reset, or migrated). External changes do **not**
/// emit preview writes — they only resync the displayed position.
///
/// During a drag, [onPreview] is debounced (default 100ms) to avoid flooding
/// the preview store / audio service with a write on every pixel. On release,
/// [onCommit] persists the final value.
///
/// Shared by the recitation drawer and the adhan settings section so both
/// have identical sync + debounce behaviour, and so the logic is testable
/// without a live audio service or Riverpod scope.
class PersistedVolumeSlider extends HookWidget {
  /// Creates a [PersistedVolumeSlider].
  const PersistedVolumeSlider({
    required this.persistedVolume,
    required this.onPreview,
    required this.onCommit,
    this.enabled = true,
    this.debounceDuration = const Duration(milliseconds: 100),
    super.key,
  });

  /// The authoritative persisted volume (0–100).
  final double persistedVolume;

  /// Debounced during a drag; receives the current local volume (0–100).
  final ValueChanged<double> onPreview;

  /// Persists the final volume (0–100) when the user releases the slider.
  final ValueChanged<double> onCommit;

  /// Whether the slider is enabled.
  final bool enabled;

  /// Debounce window for [onPreview].
  final Duration debounceDuration;

  @override
  Widget build(BuildContext context) {
    // Local state mirrors the persisted value; updated by the effect below
    // whenever the authoritative value changes from outside this widget.
    final volumeState = useState<double>(persistedVolume);

    useEffect(
      () {
        volumeState.value = persistedVolume;
        return null;
      },
      [persistedVolume],
    );

    final debouncedPreview = useDebouncedCallback(
      () => onPreview(volumeState.value),
      duration: debounceDuration,
    );

    return FSlider(
      enabled: enabled,
      control: FSliderControl.liftedContinuous(
        value: FSliderValue(
          max: (volumeState.value / 100).clamp(0.0, 1.0),
        ),
        onChange: (value) {
          final next = (value.max * 100).clamp(0, 100).toDouble();
          volumeState.value = next;
          debouncedPreview();
        },
      ),
      onEnd: (value) => onCommit(value.max * 100),
      label: Text('${volumeState.value.round()}%'),
    );
  }
}
