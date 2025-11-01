import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/utils/date_extensions.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prayer_completion_provider.g.dart';

@riverpod
class PrayerCompletionNotifier extends _$PrayerCompletionNotifier {
  /// Adds or updates a prayer completion.
  /// This method provides an optimistic update to the UI.
  Future<void> addOrUpdateCompletion(PrayerCompletion completion) async {
    final service = ref.read(prayerServiceProvider);

    await service.addOrUpdateCompletion(completion);

    state = AsyncData(
      await service.getPrayerCompletionForDate(completion.completionTime),
    );
    ref.invalidate(prayerAnalyticsProvider);
  }

  @override
  Future<List<PrayerCompletion>> build() {
    // Watch the completions for the current date
    final currentTime = ref.watch(currentLocationTimeProvider);
    final completions = ref
        .read(prayerServiceProvider)
        .getPrayerCompletionForDate(currentTime);

    // Transform the list into a map for efficient lookups
    return completions;
  }

  Future<PrayerCompletion?> getPrayerCompletionForPrayerOnDate(
    Prayer prayer,
    DateTime date,
  ) async {
    if (!prayer.isObligatory) return null;
    final List<PrayerCompletion> completions;
    if (state.value != null &&
        state.value!.isNotEmpty &&
        state.value!.first.completionTime.isSameDate(date)) {
      completions = state.value!;
    } else {
      completions = await ref
          .read(prayerServiceProvider)
          .getPrayerCompletionForDate(date);
    }

    try {
      return completions.firstWhere(
        (completion) => completion.prayer == prayer,
      );
    } catch (_) {
      return null;
    }
  }

  void setDate(DateTime date) async {
    state = AsyncData(
      await ref.read(prayerServiceProvider).getPrayerCompletionForDate(date),
    );
  }
}
