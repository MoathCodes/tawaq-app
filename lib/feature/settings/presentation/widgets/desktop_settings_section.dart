import 'dart:async';
import 'dart:io';

import 'package:forui/forui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/provider/desktop_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Desktop tray and window behaviour settings.
class DesktopSettingsSection extends HookConsumerWidget {
  /// Creates [DesktopSettingsSection].
  const new({super.key});

  Future<void> _handleLaunchAtLoginChange(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final l10n = context.l10n;
    try {
      final showHint = await ref
          .read(desktopSettingsProvider.notifier)
          .setLaunchAtLogin(value: value);
      if (!context.mounted || !showHint) return;

      showFToast(context: context, title: Text(l10n.desktopLaunchAtLoginHint));
    } catch (_) {
      if (!context.mounted) return;
      showFToast(
        context: context,
        title: Text(l10n.errorOccurredWhile(l10n.desktopLaunchAtLogin)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatingLogin = useState(false);
    if (!isDesktopPlatform) return const SizedBox.shrink();

    final l10n = context.l10n;
    final ready = ref.watch(desktopSettingsProvider.select((s) => s.hasValue));
    final forceMacStyleWindowControls = ref.watch(
      desktopSettingsProvider.select(
        (s) => s.value?.forceMacStyleWindowControls ?? false,
      ),
    );
    final launchAtLogin = ref.watch(
      desktopSettingsProvider.select((s) => s.value?.launchAtLogin ?? false),
    );
    final minimizeToTrayOnClose = ref.watch(
      desktopSettingsProvider.select(
        (s) => s.value?.minimizeToTrayOnClose ?? true,
      ),
    );
    final minimizeToTray = ref.watch(
      desktopSettingsProvider.select((s) => s.value?.minimizeToTray ?? false),
    );
    final launchToTray = ref.watch(
      desktopSettingsProvider.select((s) => s.value?.launchToTray ?? false),
    );

    return SettingsSection(
      title: l10n.desktopSectionTitle,
      subtitle: l10n.desktopSectionSubtitle,
      child: Column(
        spacing: AppSpacing.md,
        children: [
          if (!Platform.isMacOS)
            NonSelectable(
              child: FSwitch(
                enabled: ready,
                value: forceMacStyleWindowControls,
                onChange: (value) => ref
                    .read(desktopSettingsProvider.notifier)
                    .setForceMacStyleWindowControls(value: value),
                label: Text(l10n.desktopForceMacStyleWindowControls),
              ),
            ),
          NonSelectable(
            child: FSwitch(
              enabled: ready && !updatingLogin.value,
              value: launchAtLogin,
              onChange: (value) async {
                if (updatingLogin.value) return;
                updatingLogin.value = true;
                await _handleLaunchAtLoginChange(context, ref, value);
                if (context.mounted) updatingLogin.value = false;
              },
              label: Text(l10n.desktopLaunchAtLogin),
            ),
          ),
          NonSelectable(
            child: FSwitch(
              enabled: ready,
              value: minimizeToTrayOnClose,
              onChange: (value) => ref
                  .read(desktopSettingsProvider.notifier)
                  .setMinimizeToTrayOnClose(value: value),
              label: Text(l10n.desktopMinimizeToTrayOnClose),
            ),
          ),
          NonSelectable(
            child: FSwitch(
              enabled: ready,
              value: minimizeToTray,
              onChange: (value) => ref
                  .read(desktopSettingsProvider.notifier)
                  .setMinimizeToTray(value: value),
              label: Text(l10n.desktopMinimizeToTray),
            ),
          ),
          NonSelectable(
            child: FSwitch(
              enabled: ready,
              value: launchToTray,
              onChange: (value) => ref
                  .read(desktopSettingsProvider.notifier)
                  .setLaunchToTray(value: value),
              label: Text(l10n.desktopLaunchToTray),
            ),
          ),
        ],
      ),
    );
  }
}
