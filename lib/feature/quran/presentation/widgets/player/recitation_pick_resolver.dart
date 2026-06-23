import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_pick_intent.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

/// Resolves a timed reciter for ayah-level playback.
///
/// Auto-upgrades to a timed moshaf within the current reciter when possible.
/// Opens the unified reciter picker only when no timed option exists.
Future<ReciterPick?> resolveReciterForAyahPlayback(
  BuildContext context,
  WidgetRef ref, {
  bool persistUpgrade = true,
}) async {
  final reciter = await ref.read(selectedReciterProvider.future);
  if (reciter == null) {
    if (!context.mounted) return null;
    return _pickFromDialog(context, ref);
  }

  final settings = await ref.read(recitationSettingsProvider.future);
  final moshaf = reciter.resolveMoshafForIntent(
    settings.moshafId,
    RecitationPickIntent.ayahLevel,
  );
  if (moshaf == null || !moshaf.hasTiming) {
    if (!context.mounted) return null;
    return _pickFromDialog(context, ref);
  }

  if (persistUpgrade && moshaf.id != settings.moshafId) {
    ref.read(recitationSettingsProvider.notifier).setReciter(
      reciterId: reciter.id,
      moshafId: moshaf.id,
    );
  }

  return (reciter: reciter, moshaf: moshaf);
}

Future<ReciterPick?> _pickFromDialog(BuildContext context, WidgetRef ref) {
  return showReciterDialog(
    context,
    intent: RecitationPickIntent.ayahLevel,
    pickOnly: true,
  );
}

/// Resolves reciter/moshaf for general surah playback, upgrading to timed
/// moshaf when available so highlight sync works during whole-surah play.
Future<ReciterPick?> resolveReciterForSurahPlayback(
  WidgetRef ref, {
  bool persistUpgrade = true,
}) async {
  final reciter = await ref.read(selectedReciterProvider.future);
  if (reciter == null) return null;

  final settings = await ref.read(recitationSettingsProvider.future);
  final moshaf = reciter.resolveMoshafForIntent(
    settings.moshafId,
    RecitationPickIntent.ayahLevel,
  );
  if (moshaf == null) return null;

  if (persistUpgrade &&
      moshaf.hasTiming &&
      moshaf.id != settings.moshafId) {
    ref.read(recitationSettingsProvider.notifier).setReciter(
      reciterId: reciter.id,
      moshafId: moshaf.id,
    );
  }

  return (reciter: reciter, moshaf: moshaf);
}
