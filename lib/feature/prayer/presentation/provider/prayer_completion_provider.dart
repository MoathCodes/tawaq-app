import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prayer_completion_provider.g.dart';

@Riverpod(keepAlive: true)
class PrayerCompletionNotifier extends _$PrayerCompletionNotifier {
  /// Adds or updates a prayer completion.
  /// This method provides an optimistic update to the UI.
  Future<void> addOrUpdateCompletion(PrayerCompletion completion) async {
    final service = ref.read(prayerServiceProvider);
    final log = ref.read(talkerNotifierProvider);

    // 1. Optimistic Update: Update the local state immediately for a responsive UI.
    final previousState = state;
    state = {
      ...state,
      completion.prayer: completion,
    };

    try {
      // 2. Persist the change to the database.
      await service.addOrUpdateCompletion(completion);

      // 3. Invalidate dependent providers upon success.
      ref.invalidate(prayerAnalyticsNotifierProvider);
    } catch (e, s) {
      log.handle(e, s,
          '[PrayerCompletionNotifier] Error adding or updating completion');
      // If the database update fails, revert to the previous state.
      state = previousState;
      // Optionally, show an error message to the user.
    }
  }

  @override
  Map<Prayer, PrayerCompletion> build() {
    // Watch the completions for the current date
    final currentTime = ref.watch(currentLocationTimeProvider);
    final completionsAsync =
        ref.watch(prayerCompletionsForDateProvider(currentTime));

    // Transform the list into a map for efficient lookups
    return completionsAsync.when(
      data: (completions) => {for (final c in completions) c.prayer: c},
      loading: () => {}, // Start with an empty map while loading
      error: (e, s) => {}, // Handle error case
    );
  }
}
