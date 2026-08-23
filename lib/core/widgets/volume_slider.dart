import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';

/// A volume slider (0–100) whose local value is synced to a persisted volume
/// and whose preview updates continuously while dragging.
///
/// [persistedVolume] is the authoritative volume from settings. The slider's
/// local value mirrors it via [useEffect] whenever it changes externally, so
/// the thumb always reflects the persisted value (e.g. when volume is changed
/// from another surface, reset, or migrated). External changes do **not**
/// emit preview writes — they only resync the displayed position.
///
/// During a drag, [onPreview] is called on every value change so playback can
/// follow the thumb in real time. On release, [onCommit] persists the final
/// value.
///
/// Shared by the recitation drawer and the adhan settings section so both
/// have identical sync behaviour, and so the logic is testable without a live
/// audio service or Riverpod scope.
class PersistedVolumeSlider extends HookWidget {
  /// Creates a [PersistedVolumeSlider].
  const new({
    required this.persistedVolume,
    required this.onPreview,
    required this.onCommit,
    this.enabled = true,
    super.key,
  });

  /// The authoritative persisted volume (0–100).
  final double persistedVolume;

  /// Called on every value change while dragging (0–100).
  final ValueChanged<double> onPreview;

  /// Persists the final volume (0–100) when the user releases the slider.
  final ValueChanged<double> onCommit;

  /// Whether the slider is enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Local state mirrors the persisted value; updated by the effect below
    // whenever the authoritative value changes from outside this widget.
    final volumeState = useState<double>(persistedVolume);
    final colors = context.theme.colors;

    useEffect(
      () {
        volumeState.value = persistedVolume;
        return null;
      },
      [persistedVolume],
    );

    final normalizedVolume = (volumeState.value / 100).clamp(0.0, 1.0);

    return FSlider(
      enabled: enabled,
      control: FSliderControl.liftedContinuous(
        value: FSliderValue(
          max: normalizedVolume,
        ),
        onChange: (value) {
          final next = (value.max * 100).clamp(0, 100).toDouble();
          volumeState.value = next;
          onPreview(next);
        },
      ),
      onEnd: (value) => onCommit(value.max * 100),
      marks: [
        .mark(
          value: 0,
          label: Icon(
            Icons.volume_off,
            color: _isPassed(normalizedVolume, 0) && !(normalizedVolume > 0.01)
                ? colors.primary
                : colors.secondaryForeground,
            size: 16,
          ),
        ),
        .mark(
          value: 0.5,
          label: Icon(
            Icons.volume_down,
            size: 16,
            color: _isPassed(normalizedVolume, 0.5)
                ? colors.primary
                : colors.secondaryForeground,
          ),
        ),
        .mark(
          value: 1,
          label: Icon(
            Icons.volume_up,
            size: 16,
            color: _isPassed(normalizedVolume, 1)
                ? colors.primary
                : colors.secondaryForeground,
          ),
        ),
      ],
    );
  }

  bool _isPassed(double value, double mark) {
    return value >= mark;
  }
}
