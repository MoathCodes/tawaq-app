import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/utils/date_extensions.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:hasanat/feature/settings/service/settings_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prayer_completion_provider.g.dart';

/// Notifier for prayer completion records.
@riverpod
class PrayerCompletionNotifier extends _$PrayerCompletionNotifier {
  /// Adds or updates a prayer completion.
  /// This method provides an optimistic update to the UI.
  Future<void> addOrUpdateCompletion(PrayerCompletion completion) async {
    if (!ref.mounted) return;
    final service = ref.read(prayerServiceProvider);
    final settingsService = ref.read(settingsServiceProvider);

    // Set the first prayer recorded date if not already set
    await settingsService.setFirstPrayerRecordedDateIfNull(
      completion.completionTime,
    );

    await service.addOrUpdateCompletion(completion);
    if (!ref.mounted) return;

    final completions = await service.getPrayerCompletionForDate(
      completion.completionTime,
    );
    if (!ref.mounted) return;

    state = AsyncData(completions);
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

  /// Returns the prayer completion record for a specific prayer on a specific date.
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

  /// Sets the date for which to fetch prayer completion records.
  Future<void> setDate(DateTime date) async {
    if (!ref.mounted) return;
    final completions = await ref
        .read(prayerServiceProvider)
        .getPrayerCompletionForDate(date);
    if (!ref.mounted) return;
    state = AsyncData(completions);
  }
}
