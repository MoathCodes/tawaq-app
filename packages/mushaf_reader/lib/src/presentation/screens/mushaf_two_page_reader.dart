import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart'
    show
        AyahTapCallback,
        AyahLongPressCallback,
        MushafReader,
        MushafReaderController,
        MushafStyle,
        MushafTwoPageChangedCallback;

/// Deprecated alias for [MushafReader] with [MushafReader.pagesPerViewport] = 2.
///
/// Prefer:
///
/// ```dart
/// MushafReader(
///   pagesPerViewport: 2,
///   onSpreadChanged: (info) => ...,
/// )
/// ```
@Deprecated(
  'Use MushafReader with pagesPerViewport: 2. '
  'Will be removed in a future release.',
)
class MushafTwoPageReader extends StatelessWidget {
  final MushafReaderController? controller;
  final int initialPage;
  final bool reverse;
  final TextDirection textDirection;
  final AyahTapCallback? onAyahTap;
  final AyahLongPressCallback? onAyahLongPress;
  final MushafTwoPageChangedCallback? onPageChanged;
  final void Function((int, int) pages)? onPageNumberChanged;
  final MushafStyle? style;
  final Widget? loadingWidget;
  final Widget? pageLoadingWidget;
  final bool hideHeader;
  final Clip clipBehavior;
  final ScrollPhysics? physics;

  const MushafTwoPageReader({
    super.key,
    this.controller,
    this.initialPage = 1,
    this.reverse = false,
    this.textDirection = TextDirection.rtl,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onPageChanged,
    this.onPageNumberChanged,
    this.style,
    this.loadingWidget,
    this.pageLoadingWidget,
    this.hideHeader = false,
    this.clipBehavior = Clip.hardEdge,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return MushafReader(
      controller: controller,
      pagesPerViewport: 2,
      initialPage: initialPage,
      reverse: reverse,
      textDirection: textDirection,
      onAyahTap: onAyahTap,
      onAyahLongPress: onAyahLongPress,
      onSpreadChanged: onPageChanged,
      onSpreadPageNumbersChanged: onPageNumberChanged,
      style: style,
      loadingWidget: loadingWidget,
      pageLoadingWidget: pageLoadingWidget,
      hideHeader: hideHeader,
      clipBehavior: clipBehavior,
      physics: physics,
    );
  }
}
