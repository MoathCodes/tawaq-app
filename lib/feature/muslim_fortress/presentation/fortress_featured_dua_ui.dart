import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_featured_dua.dart';

/// Featured dua card with presentation accent interpolation.
class FortressFeaturedDuaCard {
  /// Creates a featured card view model.
  const FortressFeaturedDuaCard({
    required this.dua,
    required this.accentShift,
  });

  /// Domain featured dua data.
  final FortressFeaturedDua dua;

  /// Accent color interpolation factor for the card (0–1).
  final double accentShift;
}

/// Assigns staggered accent shifts to featured duas for welcome cards.
List<FortressFeaturedDuaCard> withAccentShifts(
  List<FortressFeaturedDua> duas,
) {
  final result = <FortressFeaturedDuaCard>[];
  var shift = 0.15;

  for (final dua in duas) {
    result.add(FortressFeaturedDuaCard(dua: dua, accentShift: shift));
    shift = (shift + 0.2).clamp(0.0, 0.95);
  }

  return result;
}
