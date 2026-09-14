import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/desktop/omarchy_theme_source.dart';

part 'omarchy_theme_provider.g.dart';

/// Emits the active Omarchy palette and refreshes after theme changes.
@Riverpod(keepAlive: true)
Stream<OmarchyThemeSnapshot> omarchyTheme(Ref ref) async* {
  final source = OmarchyThemeSource();
  yield source.read();
  if (source.isOmarchySession) yield* source.watch();
}
