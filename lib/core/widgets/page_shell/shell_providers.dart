import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/settings/presentation/provider/ui_state_settings_providers.dart';

part 'shell_providers.g.dart';

/// Whether the shell sidebar is collapsed.
@riverpod
bool shellSidebarCollapsed(Ref ref, bool tabletDefault) {
  // Already projects to a deduped bool for consumers; sidebarSettingsProvider
  // is a class-based notifier and does not expose `.select`.
  return ref.watch(sidebarSettingsProvider).value ?? tabletDefault;
}
