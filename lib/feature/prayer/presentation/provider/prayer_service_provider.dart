import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_service.dart';

part 'prayer_service_provider.g.dart';

/// Provider for completion/analytics [PrayerService] (no prayer-time math).
@riverpod
PrayerService prayerService(Ref ref) {
  final repo = ref.watch(prayerRepoProvider);
  final log = ref.read(loggerProvider);
  return PrayerService(repo, log);
}
