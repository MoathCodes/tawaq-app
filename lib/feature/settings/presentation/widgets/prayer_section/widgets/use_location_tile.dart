import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/location_helpers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Toggle tile for enabling/disabling automatic location detection.
class UseLocationTile extends ConsumerWidget {
  /// Creates a new [UseLocationTile] instance.
  const UseLocationTile({super.key});

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final notifier = ref.read(prayerSettingsProvider.notifier)
      ..setAutoLocation(value: value);
    if (!value) return;

    final errorAction = context.l10n.gettingLocation;
    try {
      await notifier.useCurrentLocation();
      await notifier.setSystemTimezone();
    } catch (e) {
      if (context.mounted) showLocationError(context, errorAction, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoLocation = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
    );
    final colors = FTheme.of(context).colors;

    return FTile(
      prefix: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(FIcons.locate, color: colors.primary),
      ),
      title: Text(context.l10n.useMyLocation),
      subtitle: Text(
        autoLocation
            ? context.l10n.autoLocationEnabled
            : context.l10n.autoLocationDisabled,
      ),
      suffix: FSwitch(
        value: autoLocation,
        onChange: (v) => _onToggle(context, ref, v),
      ),
    );
  }
}
