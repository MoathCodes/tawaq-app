import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart tool/set_pubspec_version.dart <version>');
    exitCode = 64;
    return;
  }

  final version = arguments.single;
  final pubspec = File('pubspec.yaml');
  final contents = pubspec.readAsStringSync();
  final versionLine = RegExp(r'^version:.*$', multiLine: true);
  final matches = versionLine.allMatches(contents).length;
  if (matches != 1) {
    stderr.writeln('Expected exactly one version entry in pubspec.yaml.');
    exitCode = 65;
    return;
  }

  pubspec.writeAsStringSync(
    contents.replaceFirst(versionLine, 'version: $version'),
  );
  stdout.writeln('Set pubspec.yaml version to $version');
}
