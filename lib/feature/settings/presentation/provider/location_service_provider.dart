import 'package:free_map/free_map.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/settings/domain/services/location_service.dart';

part 'location_service_provider.g.dart';

/// Provider for the [LocationService].
@riverpod
LocationService locationService(Ref ref) {
  final log = ref.read(loggerProvider);
  final lang = ref.watch(localeProvider);
  final service = FmService()
    ..setData(userAgent: 'Tawaq/1.0 (contact: moathaltamimidev@gmail.com)');
  return LocationService(log, service, lang);
}
