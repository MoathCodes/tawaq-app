import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/scaled_screen_util.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

/// Notification bell button for prayer reminders.
class NotificationButton extends ConsumerWidget {
  /// Creates a [NotificationButton].
  const NotificationButton({required this.prayerName, super.key});

  /// Localized prayer name for screen-reader labels.
  final String prayerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appScale = ref.watch(appTextScaleFactorProvider);
    final l10n = context.l10n;
    return HookBuilder(
      builder: (context) {
        final isEnabled = useState(true);
        return FButton.icon(
          variant: isEnabled.value ? .outline : .secondary,
          semanticsLabel: PrayerSemantics.notificationToggle(
            prayerName: prayerName,
            enabled: isEnabled.value,
            l10n: l10n,
          ),
          onPress: () {
            isEnabled.value = !isEnabled.value;
          },
          child: Icon(
            isEnabled.value ? FLucideIcons.bell : FLucideIcons.bellOff,
            size: scaledSp(20, appScale),
          ),
        );
      },
    );
  }
}
