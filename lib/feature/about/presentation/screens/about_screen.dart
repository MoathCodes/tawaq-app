import 'package:flutter/material.dart';
import 'package:tawaq/core/layout/centered_viewport_shell.dart';
import 'package:tawaq/feature/about/data/about_info.dart';
import 'package:tawaq/feature/about/presentation/widgets/about_view.dart';
import 'package:tawaq/theme/theme.dart';

/// Full-screen presentation of the about content.
///
/// The about entry normally opens the about dialog from the sidebar; this
/// screen is the fallback when the `/about` route is reached directly (e.g. a
/// deep link), reusing the same [AboutView].
class AboutScreen extends StatelessWidget {
  /// Creates an [AboutScreen].
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return centeredViewportScrollTab(
      maxContentWidth: 560,
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AboutView(content: aboutContent),
      ),
    );
  }
}
