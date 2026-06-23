import 'package:flutter/material.dart';

/// Defers building a tab's body until the tab is first selected.
///
/// [TabBarView] mounts every page at once, so heavy tabs (e.g. the timezone
/// map) would otherwise build and run their providers while off-screen. Once a
/// tab is activated it stays built, since [TabBarView] keeps pages mounted.
class LazyTabContent extends StatefulWidget {
  /// Creates [LazyTabContent].
  const LazyTabContent({
    required this.controller,
    required this.index,
    required this.builder,
    super.key,
  });

  /// Tab controller shared with the surrounding [TabBarView].
  final TabController controller;

  /// Index of this tab within [TabBarView.children].
  final int index;

  /// Builds the tab body when the tab is first activated.
  final Widget Function() builder;

  @override
  State<LazyTabContent> createState() => _LazyTabContentState();
}

class _LazyTabContentState extends State<LazyTabContent> {
  bool _activated = false;

  @override
  void initState() {
    super.initState();
    _maybeActivate();
    widget.controller.addListener(_maybeActivate);
  }

  void _maybeActivate() {
    if (_activated || !mounted) return;
    if (widget.controller.index == widget.index) {
      setState(() => _activated = true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_maybeActivate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _activated ? widget.builder() : const SizedBox.shrink();
  }
}

/// Defers building indexed panel content until [selectedIndex] first matches
/// [index].
///
/// Use with index-controlled tab widgets (e.g. Forui [FTabs]) that do not use
/// a [TabController]. Once activated, content stays built.
class LazyIndexedContent extends StatefulWidget {
  /// Creates [LazyIndexedContent].
  const LazyIndexedContent({
    required this.selectedIndex,
    required this.index,
    required this.builder,
    super.key,
  });

  /// Currently selected tab index from the parent control.
  final int selectedIndex;

  /// Index of this panel within the parent tab list.
  final int index;

  /// Builds the panel body when first activated.
  final Widget Function() builder;

  @override
  State<LazyIndexedContent> createState() => _LazyIndexedContentState();
}

class _LazyIndexedContentState extends State<LazyIndexedContent> {
  bool _activated = false;

  @override
  void didUpdateWidget(LazyIndexedContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeActivate();
  }

  @override
  void initState() {
    super.initState();
    _maybeActivate();
  }

  void _maybeActivate() {
    if (_activated || !mounted) return;
    if (widget.selectedIndex == widget.index) {
      setState(() => _activated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _activated ? widget.builder() : const SizedBox.shrink();
  }
}
