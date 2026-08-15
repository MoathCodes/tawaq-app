import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';

part 'prayer_completions_repair_provider.g.dart';

const _repairMetaKey = 'repaired_v1';

/// Repairs duplicate legacy completions once a prayer timezone is available.
@Riverpod(keepAlive: true)
Future<void> prayerCompletionsRepair(Ref ref) async {
  await ref.watch(hiveCoreInitProvider.future);
  final repairedBox = Box<String, int>('prayer_completions_meta');
  final alreadyRepaired = (await repairedBox.get(_repairMetaKey) ?? 0) == 1;
  if (alreadyRepaired) return;

  final inputs = ref.watch(prayerTimeInputsProvider);
  if (inputs == null) return;
  final removed = await ref
      .read(prayerDatabaseProvider)
      .repairDuplicates(inputs.location);
  if (removed > 0) {
    ref
        .read(loggerProvider)
        .i(
          'Repaired $removed duplicate prayer completion row(s)',
        );
  }
  await repairedBox.put(_repairMetaKey, 1);
}
