import 'package:example/demo_scaffold.dart';
import 'package:example/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// Example loading indicator — demonstrates host-supplied [loadingWidget].
Widget exampleLoadingIndicator({String? message}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(message),
        ],
      ],
    ),
  );
}

/// Loading scaffold with localized message.
Widget exampleLoadingScaffold({required String title}) {
  return DemoScaffold(
    title: title,
    body: exampleLoadingIndicator(message: t.common.loadingPage),
  );
}

/// Error scaffold with retry action.
Widget exampleErrorScaffold({
  required String title,
  required VoidCallback onRetry,
}) {
  return DemoScaffold(
    title: title,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.common.loadFailed),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: Text(t.common.retry),
          ),
        ],
      ),
    ),
  );
}

IconData pagePreviousIcon(BuildContext context) {
  return Directionality.of(context) == TextDirection.rtl
      ? Icons.chevron_right
      : Icons.chevron_left;
}

IconData pageNextIcon(BuildContext context) {
  return Directionality.of(context) == TextDirection.rtl
      ? Icons.chevron_left
      : Icons.chevron_right;
}

/// Unified page navigation: prev/next, mushaf numeral, and jump field.
class PageNavigatorControls extends StatefulWidget {
  const PageNavigatorControls({
    required this.page,
    required this.onPageChanged,
    super.key,
  });

  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  State<PageNavigatorControls> createState() => _PageNavigatorControlsState();
}

class _PageNavigatorControlsState extends State<PageNavigatorControls> {
  late final TextEditingController _jumpController;

  @override
  void initState() {
    super.initState();
    _jumpController = TextEditingController(text: '${widget.page}');
  }

  @override
  void didUpdateWidget(PageNavigatorControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      _jumpController.text = '${widget.page}';
    }
  }

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    final clamped = page.clamp(1, MushafConstants.pageCount);
    widget.onPageChanged(clamped);
  }

  void _submitJump() {
    final value = int.tryParse(_jumpController.text.trim());
    if (value == null || value < 1 || value > MushafConstants.pageCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.common.invalidPage)),
      );
      _jumpController.text = '${widget.page}';
      return;
    }
    _goToPage(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: t.common.previousPage,
            onPressed: widget.page > 1
                ? () => _goToPage(widget.page - 1)
                : null,
            icon: Icon(pagePreviousIcon(context)),
          ),
          PageNumberWidget(page: widget.page, fontSize: 18),
          const SizedBox(width: 8),
          Text(t.common.pageLabel(page: widget.page)),
          const Spacer(),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _jumpController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: t.common.jumpToPage,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submitJump(),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: t.common.nextPage,
            onPressed: widget.page < MushafConstants.pageCount
                ? () => _goToPage(widget.page + 1)
                : null,
            icon: Icon(pageNextIcon(context)),
          ),
        ],
      ),
    );
  }
}

/// Bordered share-card preview container.
class ShareCardPreview extends StatelessWidget {
  const ShareCardPreview({
    required this.child,
    this.maxWidth = 420,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < maxWidth
            ? constraints.maxWidth
            : maxWidth;
        return Center(
          child: Container(
            width: width,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                child,
                const SizedBox(height: 12),
                Text(
                  t.common.footer,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Standalone widget section with usage hint.
class WidgetDemoCard extends StatelessWidget {
  const WidgetDemoCard({
    required this.title,
    required this.hint,
    required this.child,
    super.key,
  });

  final String title;
  final String hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              hint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Resolves an ayah id to its reference string for display.
class AyahReferenceLabel extends StatelessWidget {
  const AyahReferenceLabel({
    required this.ayahId,
    required this.controller,
    required this.builder,
    super.key,
  });

  final int ayahId;
  final MushafReaderController controller;
  final Widget Function(BuildContext context, String reference) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Ayah>(
      future: controller.getAyah(ayahId),
      builder: (context, snapshot) {
        final reference = snapshot.data?.reference ?? '$ayahId';
        return builder(context, reference);
      },
    );
  }
}
