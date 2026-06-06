import 'package:json_annotation/json_annotation.dart';

/// Discrete app-wide UI text scale steps applied via Forui typography scaling.
@JsonEnum()
enum AppTextScale {
  /// Smaller UI text (0.9×).
  compact,

  /// Default UI text (1.0×).
  normal,

  /// Larger UI text (1.1×).
  large,

  /// Extra large UI text (1.2×).
  extraLarge,
  ;

  /// Multiplier passed to typography scaling and [scaledSp].
  double get scalar => switch (this) {
    AppTextScale.compact => 0.9,
    AppTextScale.normal => 1.0,
    AppTextScale.large => 1.1,
    AppTextScale.extraLarge => 1.2,
  };
}
