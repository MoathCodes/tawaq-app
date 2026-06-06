import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/ui_state_settings_providers.dart';

part 'shell_providers.g.dart';

/// Whether the shell sidebar is collapsed.
@riverpod
bool shellSidebarCollapsed(Ref ref, bool tabletDefault) {
  return ref.watch(sidebarSettingsProvider).value ?? tabletDefault;
}

/// App-wide text scale for shell layout.
@riverpod
double shellAppTextScaleFactor(Ref ref) {
  return ref.watch(appTextScaleFactorProvider);
}
