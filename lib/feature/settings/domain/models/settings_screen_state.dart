import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_screen_state.freezed.dart';
part 'settings_screen_state.g.dart';

/// Persisted UI state for the settings screen.
@freezed
abstract class SettingsScreenState with _$SettingsScreenState {
  /// Creates the settings screen state.
  const factory SettingsScreenState({
    /// ARB label key of the last active settings tab.
    @Default('appearance') String activeTabKey,
  }) = _SettingsScreenState;

  /// Deserializes the settings screen state from JSON.
  factory SettingsScreenState.fromJson(Map<String, dynamic> json) =>
      _$SettingsScreenStateFromJson(json);

  /// Returns the default initial screen state.
  factory SettingsScreenState.initial() => const SettingsScreenState();
}
