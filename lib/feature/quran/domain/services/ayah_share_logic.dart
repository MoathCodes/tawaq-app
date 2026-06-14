/// Slider index mapping for the ayah share range control.
abstract final class AyahShareLogic {
  /// Maps a discrete ayah index to a normalized slider value in `[0, 1]`.
  static double ayahIndexToSliderValue(int index, int count) {
    if (count <= 1) return 0;
    return index / (count - 1);
  }

  /// Maps a normalized slider value to the nearest ayah index.
  static int sliderValueToAyahIndex(double value, int count) {
    if (count <= 1) return 0;
    return (value * (count - 1)).round().clamp(0, count - 1);
  }
}
