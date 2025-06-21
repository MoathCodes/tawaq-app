import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/main.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'talker_provider.g.dart';

@riverpod
Talker talkerNotifier(Ref ref) {
  return talker;
}
