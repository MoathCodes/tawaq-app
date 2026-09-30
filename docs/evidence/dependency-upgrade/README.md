# Flutter and dependency upgrade

Tawaq uses Flutter 3.47.5 with its bundled Dart 3.13.4, Forui 0.27.3,
and the latest mutually compatible hosted dependencies as of September 30, 2026.

## Compatibility

- App, test, and preview imports use `material_ui` alongside Forui. The shared
  localization delegate list uses standalone Material and Cupertino translations.
- `MaterialUiCompatibilityBridge` preserves themes and localization for
  `free_map`, `fl_chart`, and `mushaf_reader`, which still use legacy Material.
- Settings owns a standalone Material tab controller and releases it on disposal.
- The vendored desktop_tray plugin is 2026.6.25. Its Linux menu/title changes and
  Dart listener cleanup remain intact; macOS receives the upstream SPM layout.
- Regenerated Dorar models follow its existing generator configuration. Religious
  content, database schemas, and settings decoding were not edited.

## Updates held by upstream constraints

`free_map` 2.5.0 requires package_info_plus 8.3.1. Geolocator 14.1.1 requires
geolocator_linux 0.2.6, which requires package_info_plus 10. These cannot share
one dependency graph, so package_info_plus remains 8.3.1 and geolocator 14.0.2.
No dependency overrides are used. `pub-outdated.txt` records the remaining
transitive constraints; all direct development dependencies are current.

## Generation

Package and app build_runner generation and Flutter localization generation were
run. FlutterGen 5.15.0 changes to a manifest-based output pipeline. When upgrading
an existing checkout with an older generator cache, clear it once before building:

```sh
fvm dart run build_runner clean
fvm exec bash tool/codegen.sh
```

## Validation

App analysis passes with no errors or warnings; nonfatal lint information remains.
All 1,068 app tests and the adhan_dart, dorar_hadith, dorar_hadith_flutter,
hisn_elmoslem, and mushaf_reader suites pass. Local package analysis passes;
desktop_tray has no analyzer diagnostics. Linux debug app compilation passes.

New widget tests cover settings-tab rebuild and animated disposal in Arabic and
English, and dark themes and Arabic labels in legacy text fields. One Fortress
golden changed by 22 pixels in its source icon and was visually reviewed before
updating. The attached Quran captures came from the native Linux preview harness.

Android, iOS, macOS, Windows, and release builds were not run on this Linux host.

## Sources

- [Flutter releases](https://docs.flutter.dev/install/archive)
- [Forui 0.27.3](https://pub.dev/packages/forui/versions/0.27.3)
- [Standalone Material migration](https://pub.dev/packages/material_ui)
- [desktop_tray](https://pub.dev/packages/desktop_tray/changelog)
