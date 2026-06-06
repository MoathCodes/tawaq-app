import 'package:hisn_elmoslem/hisn_elmoslem.dart';

/// Thin wrapper around [HisnClient] for the Muslim Fortress feature.
class HisnDataSource {
  /// Creates a data source backed by [client].
  HisnDataSource(this.client);

  /// Underlying Hisn al-Muslim client.
  final HisnClient client;
}
