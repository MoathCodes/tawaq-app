import 'package:adhan_dart/adhan_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'prayer_completion_provider.g.dart';

/// Async notifier for completion records on the active calendar day.
///
/// Watches [prayerCalendarDayKeyProvider] so the list refreshes at midnight
/// without restarting the app.
@riverpod
class PrayerCompletionNotifier extends _$PrayerCompletionNotifier {
  /// Adds or updates a prayer completion.
  /// This method provides an **optimistic update**
  ///  to the UI for instant feedback.
  Future<void> addOrUpdateCompletion(PrayerCompletion completion) async {
    if (!ref.mounted) return;
    final service = ref.read(prayerServiceProvider);
    final location =
        ref.read(prayerSettingsProvider).value?.location ??
        PrayerSettings.defaultSettings().location;

    // --- Optimistic UI Update ---
    // Update the state immediately so the UI reflects the change instantly
    final currentCompletions = state.value ?? [];
    final existingIndex = currentCompletions.indexWhere(
      (c) =>
          c.prayer == completion.prayer &&
          c.completionTime.isSameCalendarDay(
            completion.completionTime,
            location,
          ),
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
    final dayKey = ref.watch(prayerCalendarDayKeyProvider);
    final currentTime = dayKey == 0
        ? ref.read(currentLocationTimeProvider).calendarDayIn(
            ref.read(prayerSettingsProvider).value?.location ??
                PrayerSettings.defaultSettings().location,
          )
        : DateTime(
            dayKey ~/ 10000,
            (dayKey % 10000) ~/ 100,
            dayKey % 100,
          );
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
    final location =
        ref.read(prayerSettingsProvider).value?.location ??
        PrayerSettings.defaultSettings().location;
    if (state.value != null &&
        state.value!.isNotEmpty &&
        state.value!.first.completionTime.isSameCalendarDay(date, location)) {
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
