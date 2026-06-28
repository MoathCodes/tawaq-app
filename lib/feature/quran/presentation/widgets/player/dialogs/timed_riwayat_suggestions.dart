import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';

/// The reciter/riwayah a user picked.
typedef ReciterPick = ({Reciter reciter, Moshaf moshaf});

/// Builds a list of timed reciter/moshaf suggestions for ayah-level playback.
///
/// Reads the current selection and catalog from [ref]. The list is never
/// persisted.
List<ReciterPick> resolveReciterForAyahPlayback(WidgetRef ref) {
  final reciterAsync = ref.read(selectedReciterProvider).value;
  final catalog = ref.read(recitersProvider).value ?? const <Reciter>[];
  return buildTimedRiwayatSuggestions(reciterAsync, catalog);
}

/// Builds the ordered list of timed reciter/moshaf suggestions used by the
/// inline timed-riwayat picker.
List<ReciterPick> buildTimedRiwayatSuggestions(
  Reciter? current,
  List<Reciter> catalog,
) {
  final suggestions = <ReciterPick>[];

  if (current != null) {
    for (final m in current.moshaf.where((m) => m.hasTiming)) {
      suggestions.add((reciter: current, moshaf: m));
    }
  }

  for (final reciter in catalog) {
    if (current != null && reciter.id == current.id) continue;
    for (final m in reciter.moshaf.where((m) => m.hasTiming)) {
      suggestions.add((reciter: reciter, moshaf: m));
    }
  }

  return suggestions;
}
