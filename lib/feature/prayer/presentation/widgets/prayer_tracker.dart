import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:forui_hooks/forui_hooks.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_tracker/prayer_tracker_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/tracker_completion_card.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timezone/timezone.dart';

/// Widget that displays the prayer tracker.
class PrayerTrackerWidget extends HookConsumerWidget {
  /// Creates a [PrayerTrackerWidget] instance.
  const PrayerTrackerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentLocationTimeProvider);
    final controller = useFDateCalendarController(
      initial: now,
      toggleable: false,
    );
    ref.watch(prayerCompletionProvider);

    return StaticCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.prayerTrackerTitle,
                      style: FTheme.of(context).typography.lg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.prayerTrackerSubtitle,
                      style: FTheme.of(context).typography.sm.copyWith(
                        color: FTheme.of(context).colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FLineCalendar(
                  control: FLineCalendarControl.managed(
                    controller: controller,
                    onChange: (value) {
                      if (value != null) {
                        unawaited(
                          ref
                              .read(prayerCompletionProvider.notifier)
                              .setDate(value),
                        );
                      }
                    },
                  ),
                  end: now,
                  start: now.subtract(const Duration(days: 6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const FDivider(),
          const SizedBox(height: AppSpacing.lg),
          if (controller.value != null)
            _TrackerCardsWrapper(
              selectedDay: controller.value!,
            ),
        ],
      ),
    );
  }
}

/// Wrapper widget that watches providers for tracker cards.
/// Isolates rebuilds from the parent widget.
class _TrackerCardsWrapper extends ConsumerWidget {
  const _TrackerCardsWrapper({
    required this.selectedDay,
  });

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentLocationTimeProvider);
    final prayerTimes = ref.watch(
      currentPrayerTimesProvider(forDate: selectedDay),
    );
    final formatter = ref.watch(timeFormatterProvider);
    final customLocation = ref.watch(
      prayerSettingsProvider.select((settings) => settings.value?.location),
    );
    final location = customLocation ?? getLocation('Asia/Riyadh');
    final completions = ref
        .watch(prayerCompletionProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <PrayerCompletion>[],
        );
    final completionByPrayer = {
      for (final completion in completions) completion.prayer: completion,
    };

    final cards = buildPrayerTrackerCards(
      l10n: context.l10n,
      day: selectedDay,
      formatter: formatter,
      prayerTimes: prayerTimes,
      completionByPrayer: completionByPrayer,
      now: now,
      location: location,
    );

    return _MainWidget(
      data: cards,
      time: selectedDay,
      onCompletionChanged: ref
          .read(prayerCompletionProvider.notifier)
          .addOrUpdateCompletion,
    );
  }
}

class _MainWidget extends StatelessWidget {
  const _MainWidget({
    required this.data,
    required this.time,
    required this.onCompletionChanged,
  });
  final List<PrayerTrackerCardModel> data;
  final void Function(PrayerCompletion) onCompletionChanged;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xl,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runAlignment: WrapAlignment.center,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final card = entry.value;
        return TrackerCompletionCard(
              cardData: card,
              completionTime: time,
              onCompletionChanged: onCompletionChanged,
              key: ValueKey(
                'clickable-prayer-card-$index-${time.day}-'
                '${time.month}-${time.year}',
              ),
            )
            .animate()
            .slideY(
              begin: 0.1,
              end: 0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
            )
            .fadeIn();
      }).toList(),
    );
  }
}
