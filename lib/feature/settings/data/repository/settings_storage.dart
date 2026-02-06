import 'dart:async';

import 'package:riverpod_annotation/experimental/persist.dart';

final class SettingsStorage extends Storage<String, String> {
  @override
  FutureOr<void> delete(String key) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  void deleteOutOfDate() {
    // TODO: implement deleteOutOfDate
  }

  @override
  FutureOr<PersistedData<String>?> read(String key) {
    // TODO: implement read
    throw UnimplementedError();
  }

  @override
  FutureOr<void> write(String key, String value, StorageOptions options) {
    // TODO: implement write
    throw UnimplementedError();
  }

}