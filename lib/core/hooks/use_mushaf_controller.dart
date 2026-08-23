import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// Creates a [MushafReaderController] that is automatically disposed.
MushafReaderController useMushafController({
  int initialPage = 1,
  PageController? pageController,
  int pagesPerViewport = 1,
}) {
  return use(
    _MushafControllerHook(
      initialPage: initialPage,
      pageController: pageController,
      pagesPerViewport: pagesPerViewport,
    ),
  );
}

class _MushafControllerHook extends Hook<MushafReaderController> {
  const new({
    required this.initialPage,
    required this.pagesPerViewport,
    this.pageController,
  });

  final int initialPage;
  final PageController? pageController;
  final int pagesPerViewport;

  @override
  _MushafControllerHookState createState() => _MushafControllerHookState();
}

class _MushafControllerHookState
    extends HookState<MushafReaderController, _MushafControllerHook> {
  late final MushafReaderController _controller = MushafReaderController(
    initialPage: hook.initialPage,
    pageController: hook.pageController,
    pagesPerViewport: hook.pagesPerViewport,
  );

  @override
  MushafReaderController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String get debugLabel => 'useMushafController';
}
