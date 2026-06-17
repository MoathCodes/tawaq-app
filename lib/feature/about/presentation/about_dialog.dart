import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/about/data/about_info.dart';
import 'package:tawaq/feature/about/domain/models/about_content.dart';
import 'package:tawaq/feature/about/presentation/about_strings.dart';
import 'package:tawaq/feature/about/presentation/widgets/about_view.dart';
import 'package:tawaq/theme/theme.dart';

/// Opens the app's about dialog.
///
/// Named with an `App` suffix to avoid clashing with Flutter's Material
/// `showAboutDialog`.
Future<void> showAboutAppDialog(
  BuildContext context, {
  AboutContent content = aboutContent,
}) {
  return showFDialog<void>(
    context: context,
    builder: (context, style, animation) => AboutDialog(content: content),
  );
}

/// A modal dialog presenting information about the app.
class AboutDialog extends StatelessWidget {
  /// Creates an [AboutDialog].
  const AboutDialog({required this.content, super.key});

  /// The content to render.
  final AboutContent content;

  @override
  Widget build(BuildContext context) {
    final constraints = dialogConstraints(
      context,
      preferredWidth: 520,
      preferredHeight: isDesktopPlatform ? 680 : 720,
      minWidth: 320,
    );

    return FDialog(
      constraints: constraints,
      title: Text(AboutStrings.title.resolve(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: AboutView(content: content),
      ),
      actions: [
        FButton(
          variant: FButtonVariant.secondary,
          onPress: () => Navigator.of(context).pop(),
          child: Text(AboutStrings.close.resolve(context)),
        ),
      ],
    );
  }
}
