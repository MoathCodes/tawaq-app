import 'dart:io';

void main(List<String> arguments) {
  final candidate =
      arguments.length == 4 &&
      arguments[0] == '--build-number' &&
      arguments[2] == '--build-name';
  if (arguments.length != 1 && !candidate) {
    stderr.writeln(
      'Usage: dart tool/set_pubspec_version.dart <version> or '
      '--build-number <number> --build-name <name-or-empty>',
    );
    exitCode = 64;
    return;
  }

  final pubspec = File('pubspec.yaml');
  final contents = pubspec.readAsStringSync();
  final versionLine = RegExp(r'^version:.*$', multiLine: true);
  final matches = versionLine.allMatches(contents).length;
  if (matches != 1) {
    stderr.writeln('Expected exactly one version entry in pubspec.yaml.');
    exitCode = 65;
    return;
  }

  final current = versionLine
      .firstMatch(contents)!
      .group(0)!
      .split(':')
      .last
      .trim();
  final version = candidate
      ? '${arguments[3].isEmpty ? current.split('+').first : arguments[3]}+${arguments[1]}'
      : arguments.single;
  if (candidate && !RegExp(r'^[1-9]\d*$').hasMatch(arguments[1])) {
    stderr.writeln('Candidate build number must be a positive integer.');
    exitCode = 65;
    return;
  }

  pubspec.writeAsStringSync(
    contents.replaceFirst(versionLine, 'version: $version'),
  );
  stdout.writeln('Set pubspec.yaml version to $version');
}
