import 'package:freezed_annotation/freezed_annotation.dart';

part 'desktop_settings.freezed.dart';
part 'desktop_settings.g.dart';

/// Persisted desktop shell behaviour (tray, window).
@freezed
abstract class DesktopSettings with _$DesktopSettings {
  /// Creates [DesktopSettings].
  const factory({
    @Default(true) bool minimizeToTrayOnClose,
    @Default(false) bool minimizeToTray,
    @Default(false) bool launchToTray,
    @Default(false) bool launchAtLogin,
    @Default(false) bool launchAtLoginHintSeen,
    @Default(false) bool forceMacStyleWindowControls,
  }) = _DesktopSettings;

  /// Default desktop settings.
  factory defaults() => const DesktopSettings();

  /// Parses persisted JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$DesktopSettingsFromJson(json);
}
