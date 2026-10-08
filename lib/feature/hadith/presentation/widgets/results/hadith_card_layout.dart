import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/theme/theme.dart';

/// The same geometry for loaded cards and initial loading placeholders.
class HadithCardFrame extends StatelessWidget {
  const HadithCardFrame({
    required this.child,
    this.surface,
    this.border,
    super.key,
  });
  final Widget child;
  final Color? surface;
  final Color? border;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: surface ?? context.theme.colors.card,
      border: Border.all(color: border ?? context.theme.colors.border),
      borderRadius: context.theme.radii.lg,
    ),
    child: child,
  );
}

class HadithAttributionLayout extends StatelessWidget {
  const HadithAttributionLayout({
    required this.wide,
    required this.compact,
    super.key,
  });
  final List<Widget> wide;
  final List<Widget> compact;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => constraints.maxWidth < 520
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: compact,
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [for (final field in wide) Expanded(child: field)],
          ),
  );
}
