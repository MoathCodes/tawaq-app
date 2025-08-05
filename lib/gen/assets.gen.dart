/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/888-02.png
  AssetGenImage get a88802 => const AssetGenImage('assets/images/888-02.png');

  /// File path: assets/images/Basmala.png
  AssetGenImage get basmala => const AssetGenImage('assets/images/Basmala.png');

  /// File path: assets/images/asr.jpg
  AssetGenImage get asr => const AssetGenImage('assets/images/asr.jpg');

  /// File path: assets/images/duhr.jpg
  AssetGenImage get duhr => const AssetGenImage('assets/images/duhr.jpg');

  /// File path: assets/images/fajr.webp
  AssetGenImage get fajr => const AssetGenImage('assets/images/fajr.webp');

  /// File path: assets/images/isha.jpg
  AssetGenImage get isha => const AssetGenImage('assets/images/isha.jpg');

  /// File path: assets/images/lastThirdOfNight.jpg
  AssetGenImage get lastThirdOfNight =>
      const AssetGenImage('assets/images/lastThirdOfNight.jpg');

  /// File path: assets/images/magrib.jpg
  AssetGenImage get magrib => const AssetGenImage('assets/images/magrib.jpg');

  /// File path: assets/images/midnight.jpg
  AssetGenImage get midnight =>
      const AssetGenImage('assets/images/midnight.jpg');

  /// File path: assets/images/sunrise.jpg
  AssetGenImage get sunrise => const AssetGenImage('assets/images/sunrise.jpg');

  /// List of all assets
  List<AssetGenImage> get values => [
    a88802,
    basmala,
    asr,
    duhr,
    fajr,
    isha,
    lastThirdOfNight,
    magrib,
    midnight,
    sunrise,
  ];
}

class Assets {
  const Assets._();

  static const $AssetsImagesGen images = $AssetsImagesGen();
}

class AssetGenImage {
  const AssetGenImage(this._assetName, {this.size, this.flavors = const {}});

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
