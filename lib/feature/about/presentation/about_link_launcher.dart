import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/about/presentation/about_strings.dart';

/// Opens an about link identified by [url].
///
/// `url_launcher` is intentionally not a dependency of this project yet, so for
/// now the URL is copied to the clipboard and a toast confirms it. To open
/// links directly later, add `url_launcher` to `pubspec.yaml` and replace the
/// body of this function with `await launchUrlString(url)` — every call site
/// stays unchanged.
Future<void> openAboutLink(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  showFToast(
    context: context,
    title: Text(AboutStrings.linkCopied.resolve(context)),
  );
}
