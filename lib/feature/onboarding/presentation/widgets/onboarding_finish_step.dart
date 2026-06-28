import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/date_formatter.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/theme/theme.dart';

/// Final onboarding step showing today's prayer schedule preview.
class OnboardingFinishStep extends ConsumerWidget {
  /// Creates [OnboardingFinishStep].
  const OnboardingFinishStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final dayAsync = ref.watch(prayerDayProvider);
    final formatter = ref.watch(timeFormatterProvider);

    return dayAsync.when(
      loading: () => const Center(child: FCircularProgress.loader()),
      error: (_, _) => FAlert(
        icon: const Icon(FLucideIcons.triangleAlert),
        title: Text(l10n.onboardingFinishPreviewUnavailable),
      ),
      data: (snapshot) {
        final prayers = <Prayer>[
          Prayer.fajr,
          Prayer.dhuhr,
          Prayer.asr,
          Prayer.maghrib,
          Prayer.isha,
        ];

        return StaticCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              Text(
                l10n.todaysSchedule,
                style: theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.mutedForeground,
                ),
              ),
              for (final prayer in prayers)
                _PrayerPreviewRow(
                  label: prayer.getLocaleName(l10n),
                  time: formatter.format(
                    snapshot.today.timeForPrayer(prayer),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PrayerPreviewRow extends StatelessWidget {
  const _PrayerPreviewRow({
    required this.label,
    required this.time,
  });

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            time,
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
