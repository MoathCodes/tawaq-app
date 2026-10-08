import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

/// Brief task help, reachable through focus, hover and touch.
class HadithHelpLabel extends StatelessWidget {
  const HadithHelpLabel({required this.label, required this.help, super.key});
  final String label;
  final String help;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: context.theme.typography.body.sm)),
      FTooltip(
        tipBuilder: (_, _) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(help),
        ),
        builder: (_, controller, _) => FButton.icon(
          variant: .ghost,
          semanticsLabel: '$label: $help',
          onPress: controller.toggle,
          child: const Icon(FLucideIcons.circleHelp, size: 15),
        ),
      ),
    ],
  );
}
