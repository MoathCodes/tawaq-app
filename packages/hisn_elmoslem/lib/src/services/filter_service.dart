import '../models/content.dart';
import '../models/enums.dart';
import '../models/models.dart';

/// Applies source/authenticity filters to content lists.
abstract final class HisnFilterService {
  /// Filters [items] using [criteria].
  static List<HisnContent> apply(
    List<HisnContent> items,
    HisnFilterCriteria criteria,
  ) {
    if (!criteria.filterBySource && !criteria.filterByAuthenticity) {
      return items;
    }

    return [
      for (final item in items)
        if (_matches(item, criteria)) item,
    ];
  }

  static bool _matches(HisnContent item, HisnFilterCriteria criteria) {
    if (criteria.filterBySource &&
        !_matchesSource(item.source, criteria.activeSources)) {
      return false;
    }

    if (criteria.filterByAuthenticity &&
        !_matchesAuthenticity(item.hokm, criteria.activeAuthenticities)) {
      return false;
    }

    return true;
  }

  static bool _matchesSource(String source, Set<HisnSourceFilter> active) {
    for (final filter in active) {
      if (filter.isHokm) continue;
      if (source.contains(filter.lookupWord)) return true;
    }
    return false;
  }

  static bool _matchesAuthenticity(
    String hokm,
    Set<HisnAuthenticity> active,
  ) {
    for (final authenticity in active) {
      if (hokm == authenticity.dbValue) return true;
    }
    return false;
  }
}
