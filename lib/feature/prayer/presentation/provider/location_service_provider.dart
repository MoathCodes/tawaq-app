import 'package:free_map/free_map.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/prayer/domain/services/location_service.dart';

part 'location_service_provider.g.dart';

/// Provider for the [LocationService].
// Used by app-lived state owners outside this feature route.
@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) {
  final log = ref.read(loggerProvider);
  final lang = ref.watch(localeProvider).value ?? 'en';
  final service = FmService()
    ..setData(userAgent: 'Tawaq/1.0 (contact: moathaltamimidev@gmail.com)');
  return LocationService(log, service, lang);
}

/// Availability of the current device source; manual setup stays independent.
@riverpod
Future<bool> deviceLocationAvailable(Ref ref) =>
    ref.watch(locationServiceProvider).isDeviceLocationAvailable();
