import 'package:hasanat/main.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'talker_provider.g.dart';

/// Exposes the shared [Talker] instance to Riverpod widgets and services.
@riverpod
Talker talkerNotifier(Ref ref) {
  return talker;
}
