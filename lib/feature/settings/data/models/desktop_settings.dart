import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/settings/presentation/provider/desktop_settings_provider.dart' show DesktopSettingsNotifier;

part 'desktop_settings.freezed.dart';
part 'desktop_settings.g.dart';

/// Persisted desktop shell behaviour (tray, window).
@freezed
abstract class DesktopSettings with _$DesktopSettings {
  /// Creates [DesktopSettings].
  const factory DesktopSettings({
    @Default(true) bool minimizeToTrayOnClose,
    @Default(false) bool minimizeToTray,
    @Default(false) bool launchToTray,
    @Default(false) bool launchAtLogin,
    @Default(false) bool launchAtLoginHintSeen,
  }) = _DesktopSettings;

  /// Default desktop settings.
  factory DesktopSettings.defaults() => const DesktopSettings();

  /// Parses JSON persisted by [DesktopSettingsNotifier].
  factory DesktopSettings.fromJson(Map<String, dynamic> json) =>
      _$DesktopSettingsFromJson(json);
}
