import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/text_extensions.dart';
import 'package:hasanat/core/widgets/hover_card.dart';
// import 'package:hasanat/core/widgets/hover_card.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_tracker/prayer_tracker_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/clickable_prayer_card.dart';

class PrayerTrackerWidget extends ConsumerWidget {
  final bool expanded;
  const PrayerTrackerWidget({this.expanded = true, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsStream = ref.watch(prayerTrackerCardsProvider(context.l10n));
    final time = ref.read(currentLocationTimeProvider);

    return HoverCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.prayerTrackerTitle,
          ).bold,
          SizedBox(height: expanded ? 6 : 4),
          Text(
            context.l10n.prayerTrackerSubtitle,
          ).sm,
          SizedBox(height: expanded ? 14 : 12),
          _MainWidget(
            data: cardsStream,
            expanded: expanded,
            time: time,
            onCompletionChanged: ref
                .read(prayerCompletionNotifierProvider.notifier)
                .addOrUpdateCompletion,
          ),
        ],
      ),
    );
  }
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
      children: data.mapIndexed((index, card) {
        return ClickablePrayerCard(
          cardData: card,
          completionTime: time,
          onCompletionChanged: onCompletionChanged,
          key: ValueKey("clickable-prayer-card-$index"),
          expanded: expanded,
        );
      }).toList(),
    );
  }
}
