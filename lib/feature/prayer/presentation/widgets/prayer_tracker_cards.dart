import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_tracker/prayer_tracker_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/clickable_prayer_card.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class PrayerTrackerCards extends ConsumerWidget {
  final bool expanded;
  const PrayerTrackerCards({this.expanded = true, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsStream = ref.watch(prayerTrackerCardsProvider(context.l10n));
    final time = ref
        .read(prayerTrackerCardsProvider(context.l10n).notifier)
        .currentLocationTime();

    return OutlinedContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      borderColor:
          Theme.of(context).colorScheme.secondaryForeground.withAlpha(45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.prayerTrackerTitle,
          ).x2Large.bold,
          SizedBox(height: expanded ? 6 : 4),
          Text(
            context.l10n.prayerTrackerSubtitle,
          ).small.muted,
          SizedBox(height: expanded ? 14 : 12),
          cardsStream.when(
            data: (data) {
              return _MainWidget(
                data: data,
                expanded: expanded,
                time: time
              //   onCompletionChanged: ref
              //       .read(prayerTrackerCardsProvider(context.l10n).notifier)
              //       .addOrUpdateCompletion,
              );
            },
            error: (error, stackTrace) => Center(child: Text('Error: $error')),
            loading: () => _MainWidget(
              // onCompletionChanged: (prayerCompletion) {},
              data: List.generate(5, (index) => PrayerTrackerCardModel.empty()),
              expanded: true,
              time: DateTime.now(),
            ).asSkeleton(),
          ),
        ],
      ),
    );
  }
}

class _MainWidget extends StatelessWidget {
  final List<PrayerTrackerCardModel> data;
  // final Function(PrayerCompletion) onCompletionChanged;

  final bool expanded;
  final DateTime time;
  const _MainWidget({
    required this.data,
    required this.expanded,
    required this.time,
    // required this.onCompletionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: expanded ? 14 : 10,
      runSpacing: expanded ? 14 : 10,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runAlignment: WrapAlignment.center,
      children: data.mapIndexed((index, card) {
        return ClickablePrayerCard(
          cardData: card,
          completionTime: time,
          // onCompletionChanged: onCompletionChanged,
          key: ValueKey("clickable-prayer-card-$index"),
          expanded: expanded,
        );
      }).toList(),
    );
  }
}
