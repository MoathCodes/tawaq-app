import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/provider/desktop_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Desktop tray and window behaviour settings.
class DesktopSettingsSection extends ConsumerWidget {
  /// Creates [DesktopSettingsSection].
  const DesktopSettingsSection({super.key});

  Future<void> _handleLaunchAtLoginChange(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final l10n = context.l10n;
    final showHint = await ref
        .read(desktopSettingsProvider.notifier)
        .setLaunchAtLogin(value: value);
    if (!context.mounted || !showHint) return;

    showFToast(
      context: context,
      title: Text(l10n.desktopLaunchAtLoginHint),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDesktopPlatform) return const SizedBox.shrink();

    final l10n = context.l10n;
    final settings = ref.watch(desktopSettingsProvider).value;
    final ready = settings != null;

    return SettingsSection(
      title: l10n.desktopSectionTitle,
      subtitle: l10n.desktopSectionSubtitle,
      child: FCard(
        child: Column(
          spacing: AppSpacing.md,
          children: [
            NonSelectable(
              child: FSwitch(
                enabled: ready,
                value: settings?.launchAtLogin ?? false,
                onChange: (value) => unawaited(
                  _handleLaunchAtLoginChange(context, ref, value),
                ),
                label: Text(l10n.desktopLaunchAtLogin),
              ),
            ),
            NonSelectable(
              child: FSwitch(
                enabled: ready,
                value: settings?.minimizeToTrayOnClose ?? true,
                onChange: (value) => ref
                    .read(desktopSettingsProvider.notifier)
                    .setMinimizeToTrayOnClose(value: value),
                label: Text(l10n.desktopMinimizeToTrayOnClose),
              ),
            ),
            NonSelectable(
              child: FSwitch(
                enabled: ready,
                value: settings?.minimizeToTray ?? false,
                onChange: (value) => ref
                    .read(desktopSettingsProvider.notifier)
                    .setMinimizeToTray(value: value),
                label: Text(l10n.desktopMinimizeToTray),
              ),
            ),
            NonSelectable(
              child: FSwitch(
                enabled: ready,
                value: settings?.launchToTray ?? false,
                onChange: (value) => ref
                    .read(desktopSettingsProvider.notifier)
                    .setLaunchToTray(value: value),
                label: Text(l10n.desktopLaunchToTray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
