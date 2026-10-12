import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:mushaf_reader/src/core/mushaf_layout.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart';

/// Fits the complete, naturally laid-out page rather than an assumed aspect.
/// The transform also maps taps and semantics into the printed page geometry.
class MushafPageFit extends SingleChildRenderObjectWidget {
  const MushafPageFit({
    required this.viewport,
    required this.scale,
    required super.child,
    super.key,
  });

  final Size viewport;
  final MushafScale scale;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMushafPageFit(viewport: viewport, scale: scale);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMushafPageFit renderObject,
  ) {
    renderObject.configure(viewport, scale);
  }
}

class _RenderMushafPageFit extends RenderTransform {
  _RenderMushafPageFit({required Size viewport, required MushafScale scale})
    : _viewport = viewport,
      _scale = scale,
      super(transform: Matrix4.identity());

  Size _viewport;
  MushafScale _scale;

  void configure(Size viewport, MushafScale scale) {
    if (_viewport == viewport && _scale == scale) return;
    _viewport = viewport;
    _scale = scale;
    markNeedsLayout();
  }

  double _factor(Size natural) => resolvePageScale(
    scaleConfig: _scale.factor == null ? _scale.copyWith(minScale: 0) : _scale,
    availableWidth: _viewport.width,
    // Translate measured height into the existing zoom model's reference
    // coordinates. At 100%, contain is exactly viewport / actual page size.
    availableHeight:
        _viewport.height * mushafReferencePageHeight / natural.height,
  );

  @override
  void performLayout() {
    child!.layout(
      BoxConstraints.tightFor(width: _scale.referenceWidth),
      parentUsesSize: true,
    );
    final natural = child!.size;
    final factor = _factor(natural);
    final fitted = Size(natural.width * factor, natural.height * factor);
    size = constraints.constrain(fitted);
    transform = Matrix4.diagonal3Values(factor, factor, 1)
      ..setTranslationRaw(
        (size.width - fitted.width) / 2,
        (size.height - fitted.height) / 2,
        0,
      );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final natural = child!.getDryLayout(
      BoxConstraints.tightFor(width: _scale.referenceWidth),
    );
    final factor = _factor(natural);
    return constraints.constrain(
      Size(natural.width * factor, natural.height * factor),
    );
  }
}
