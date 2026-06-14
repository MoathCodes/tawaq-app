import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

/// One mushaf page slice of a multi-page ayah selection.
class MushafPageRangeSlice {
  /// Creates a page slice.
  const MushafPageRangeSlice({
    required this.pageNumber,
    required this.ayahIds,
  });

  /// Mushaf page number (1–604).
  final int pageNumber;

  /// Selected ayah ids on this page in reading order.
  final List<int> ayahIds;
}

/// Groups [orderedAyahIds] into per-page slices for [MushafPageRange].
Future<List<MushafPageRangeSlice>> resolvePageRangeSlices(
  List<int> orderedAyahIds,
  IQuranRepository repo,
) async {
  if (orderedAyahIds.isEmpty) {
    throw ArgumentError('orderedAyahIds must not be empty');
  }

  final slices = <int, List<int>>{};
  final pageOrder = <int>[];

  for (final id in orderedAyahIds) {
    final page = await repo.getPageForAyah(id);
    if (!slices.containsKey(page)) {
      pageOrder.add(page);
      slices[page] = [];
    }
    slices[page]!.add(id);
  }

  return [
    for (final page in pageOrder)
      MushafPageRangeSlice(pageNumber: page, ayahIds: slices[page]!),
  ];
}
