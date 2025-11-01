import 'package:flumpose/flumpose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/utils/text_extensions.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_tracker/prayer_tracker_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/tracker_completion_card.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:timezone/timezone.dart';

class PrayerTrackerWidget extends ConsumerStatefulWidget {
  final bool expanded;
  const PrayerTrackerWidget({this.expanded = true, super.key});

  @override
  ConsumerState<PrayerTrackerWidget> createState() =>
      _PrayerTrackerWidgetState();
}

class _MainWidget extends StatelessWidget {
  final List<PrayerTrackerCardModel> data;
  final Function(PrayerCompletion) onCompletionChanged;
  final bool expanded;
  final DateTime time;

  const _MainWidget({
    required this.data,
    required this.expanded,
    required this.time,
    required this.onCompletionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: expanded ? 14 : 10,
      runSpacing: expanded ? 14 : 10,
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
                'clickable-prayer-card-$index-${time.day}-${time.month}-${time.year}',
              ),
              expanded: expanded,
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

class _PrayerTrackerWidgetState extends ConsumerState<PrayerTrackerWidget> {
  late final FCalendarController<DateTime?> controller;
  @override
  Widget build(BuildContext context) {
    final selectedDay = controller.value;
    final prayerTimes = ref.watch(
      currentPrayerTimesProvider(forDate: selectedDay),
    );
    final formatter = ref.watch(timeFormatterProvider);
    final now = ref.watch(currentLocationTimeProvider);
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

    return StaticCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.prayerTrackerTitle).bold(),
                  SizedBox(height: widget.expanded ? 6 : 4),
                  Text(context.l10n.prayerTrackerSubtitle).sm,
                ],
              ).expanded(),
              FLineCalendar(
                controller: controller,
                onChange: (value) {
                  if (value != null) {
                    ref.read(prayerCompletionProvider.notifier).setDate(value);
                  }
                },
                end: now,
                start: now.subtract(const Duration(days: 6)),
              ).expanded(),
            ],
          ),

          SizedBox(height: widget.expanded ? 14 : 12),
          if (controller.value != null)
            _MainWidget(
              data: cards,
              expanded: widget.expanded,
              time: controller.value!,
              onCompletionChanged: ref
                  .read(prayerCompletionProvider.notifier)
                  .addOrUpdateCompletion,
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = FCalendarController.date(
      initialSelection: ref.read(currentLocationTimeProvider),
      toggleable: false,
    );
  }
}
