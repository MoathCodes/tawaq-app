import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

/// Defers building tab/panel content until it is first selected.
///
/// Use [LazyPanelContent.tab] with a [TabController] (Material [TabBarView]) or
/// [LazyPanelContent.indexed] with an index-controlled control (e.g. Forui
/// [FTabs]). Once activated, content stays built.
class LazyPanelContent extends StatefulWidget {
  /// Defers building until [_controller]'s index matches [index].
  const new tab({
    required TabController this._controller,
    required this.index,
    required this.builder,
    this.activateDuringDrag = false,
    super.key,
  }) : _selectedIndex = null;

  /// Defers building until [_selectedIndex] matches [index].
  const new indexed({
    required int this._selectedIndex,
    required this.index,
    required this.builder,
    super.key,
  }) : _controller = null,
       activateDuringDrag = false;

  /// Prepare the incoming panel before it becomes visible during a swipe.
  final bool activateDuringDrag;

  final TabController? _controller;
  final int? _selectedIndex;

  /// Index of this panel within the parent tab list.
  final int index;

  /// Builds the panel body when first activated.
  final Widget Function() builder;

  @override
  State<LazyPanelContent> createState() => _LazyPanelContentState();
}

class _LazyPanelContentState extends State<LazyPanelContent> {
  bool _activated = false;

  @override
  void initState() {
    super.initState();
    widget._controller?.addListener(_maybeActivate);
    if (widget.activateDuringDrag)
      widget._controller?.animation?.addListener(_maybeActivate);
    _maybeActivate();
  }

  @override
  void didUpdateWidget(LazyPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._controller != widget._controller) {
      oldWidget._controller?.removeListener(_maybeActivate);
      oldWidget._controller?.animation?.removeListener(_maybeActivate);
      widget._controller?.addListener(_maybeActivate);
      if (widget.activateDuringDrag)
        widget._controller?.animation?.addListener(_maybeActivate);
    }
    _maybeActivate();
  }

  void _maybeActivate() {
    if (_activated || !mounted) return;
    final active = widget._controller != null
        ? widget._controller!.index == widget.index
        : widget._selectedIndex == widget.index;
    final position = widget._controller?.animation?.value;
    final entering =
        widget.activateDuringDrag &&
        position != null &&
        (position - widget.index).abs() < 1;
    if (active || entering) {
      setState(() => _activated = true);
    }
  }

  @override
  void dispose() {
    widget._controller?.removeListener(_maybeActivate);
    widget._controller?.animation?.removeListener(_maybeActivate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _activated ? widget.builder() : const SizedBox.shrink();
  }
}
