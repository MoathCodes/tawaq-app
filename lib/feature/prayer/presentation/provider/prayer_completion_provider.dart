import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/utils/date_extensions.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prayer_completion_provider.g.dart';

/// Notifier for prayer completion records.
@riverpod
class PrayerCompletionNotifier extends _$PrayerCompletionNotifier {
  /// Adds or updates a prayer completion.
  /// This method provides an **optimistic update** to the UI for instant feedback.
  Future<void> addOrUpdateCompletion(PrayerCompletion completion) async {
    if (!ref.mounted) return;
    final service = ref.read(prayerServiceProvider);

    // --- Optimistic UI Update ---
    // Update the state immediately so the UI reflects the change instantly
    final currentCompletions = state.value ?? [];
    final existingIndex = currentCompletions.indexWhere(
      (c) =>
          c.prayer == completion.prayer &&
          c.completionTime.isSameDate(completion.completionTime),
    );

    final List<PrayerCompletion> updatedCompletions;
    if (existingIndex != -1) {
      // Update existing completion with the new status (preserve ID)
      final existingId = currentCompletions[existingIndex].id;
      updatedCompletions = [
        ...currentCompletions.sublist(0, existingIndex),
        completion.copyWith(id: existingId),
        ...currentCompletions.sublist(existingIndex + 1),
      ];
    } else {
      // Add new completion
      updatedCompletions = [...currentCompletions, completion];
    }
    state = AsyncData(updatedCompletions);

    // --- Persist to Database ---
    // Set the first prayer recorded date if not already set
    ref
        .read(firstPrayerRecordedDateProvider.notifier)
        .setIfNull(completion.completionTime);

    await service.addOrUpdateCompletion(completion);
    if (!ref.mounted) return;

    // Refresh from database to get the actual persisted data with IDs
    final completions = await service.getPrayerCompletionForDate(
      completion.completionTime,
    );
    if (!ref.mounted) return;

    state = AsyncData(completions);
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

  /// Returns the prayer completion record for a
  ///  specific prayer on a specific date.
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
