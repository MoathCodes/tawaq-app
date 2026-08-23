import 'package:tawaq/l10n/app_localizations.dart';

/// Localized labels for shell navigation and window chrome.
abstract final class ShellA11y {
  new _();

  /// Label for the theme mode toggle.
  static String themeToggleLabel(
    AppLocalizations l10n, {
    required bool isDark,
  }) => isDark ? l10n.a11ySwitchToLightTheme : l10n.a11ySwitchToDarkTheme;

  /// Label for a shell navigation destination.
  static String navItemLabel(String routeLabel) => routeLabel;

  /// Hint when a route is listed but cannot be opened.
  static String navDisabledHint(AppLocalizations l10n) =>
      l10n.a11yNavigationUnavailable;

  /// Hint for the sidebar expand control when collapsed.
  static String expandSidebarLabel(AppLocalizations l10n) =>
      l10n.a11yExpandSidebar;

  /// Label for minimize.
  static String windowMinimize(AppLocalizations l10n) =>
      l10n.a11yWindowMinimize;

  /// Label for maximize.
  static String windowMaximize(AppLocalizations l10n) =>
      l10n.a11yWindowMaximize;

  /// Label for restore from maximized.
  static String windowRestore(AppLocalizations l10n) =>
      l10n.a11yWindowRestore;

  /// Label for close.
  static String windowClose(AppLocalizations l10n) => l10n.a11yWindowClose;

  /// Label for the shell location chip that opens location settings.
  static String openLocationSettings(AppLocalizations l10n) =>
      l10n.a11yOpenLocationSettings;
}
