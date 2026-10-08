/// Layout decisions use feature constraints after the application shell.
class HadithDeskLayout {
  const HadithDeskLayout._(
    this.filtersMin,
    this.resultsMin,
    this.readerMin,
    this.areas,
  );
  factory HadithDeskLayout.resolve(double width, double textScale) {
    final scale = textScale.clamp(1.0, 2.0);
    final filter = 260 * scale;
    final results = 380 * scale;
    final reader = 360 * scale;
    return HadithDeskLayout._(
      filter,
      results,
      reader,
      width >= filter + results + reader + 24
          ? 3
          : width >= results + reader + 12
          ? 2
          : 1,
    );
  }
  final double filtersMin;
  final double resultsMin;
  final double readerMin;
  final int areas;
}
