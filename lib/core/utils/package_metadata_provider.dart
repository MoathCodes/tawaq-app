import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// One runtime source for the installed application's version and build.
final packageMetadataProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);
