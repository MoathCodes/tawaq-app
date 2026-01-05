// ignore_for_file: avoid_print
/// Script to update pubspec.yaml to use the new QCF4 TTF fonts.
///
/// Run with: `dart run tool/update_pubspec_fonts.dart`
///
/// This replaces the fonts section in pubspec.yaml to use:
/// - assets/qcf4_ttf/QCF4XXX_X-Regular.ttf format for pages 1-604
/// - Keeps the BSML font for basmalah
library;

import 'dart:io';

void main() async {
  final projectRoot = Directory.current.path;
  final pubspecPath = '$projectRoot/pubspec.yaml';
  final pubspecFile = File(pubspecPath);

  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found at $pubspecPath');
    exit(1);
  }

  final content = await pubspecFile.readAsString();

  // Find the fonts section and everything after it
  final fontsIndex = content.indexOf('  fonts:');
  if (fontsIndex == -1) {
    print('Error: fonts section not found in pubspec.yaml');
    exit(1);
  }

  // Get the content before fonts section
  final beforeFonts = content.substring(0, fontsIndex);

  // Generate new fonts section
  final newFonts = StringBuffer();
  newFonts.writeln('  fonts:');

  // Add BSML font first (keeping the old OTF for basmalah)
  newFonts.writeln('    - family: QCF4_BSML');
  newFonts.writeln('      fonts:');
  newFonts.writeln('        - asset: assets/otf_fonts/QCF4_BSML.otf');

  // Add page fonts 001-604 with new TTF format
  for (int page = 1; page <= 604; page++) {
    final paddedPage = page.toString().padLeft(3, '0');
    final fontFamily = 'QCF4_$paddedPage';
    final fontFile = 'QCF4${paddedPage}_X-Regular.ttf';

    newFonts.writeln('    - family: $fontFamily');
    newFonts.writeln('      fonts:');
    newFonts.writeln('        - asset: assets/qcf4_ttf/$fontFile');
  }

  // Write the new pubspec
  final newContent = beforeFonts + newFonts.toString();
  await pubspecFile.writeAsString(newContent);

  print('Updated pubspec.yaml with new QCF4 TTF fonts');
  print('  - BSML font: assets/otf_fonts/QCF4_BSML.otf');
  print('  - Page fonts: assets/qcf4_ttf/QCF4XXX_X-Regular.ttf (604 pages)');
}
