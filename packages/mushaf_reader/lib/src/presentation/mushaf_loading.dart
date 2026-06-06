import 'package:flutter/widgets.dart';

/// Default placeholders used when [loadingWidget] is not provided.
///
/// Intentionally minimal so host apps can supply their own indicator
/// (e.g. Forui's `FCircularProgress.loader()`) without this package
/// depending on a UI kit.
abstract final class MushafLoading {
  /// Empty placeholder — avoids flashing a Material spinner during fast loads.
  static const Widget none = SizedBox.shrink();
}
