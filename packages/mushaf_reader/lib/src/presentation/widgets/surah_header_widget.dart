import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/core/fonts.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:vector_graphics/vector_graphics.dart';

/// A decorative banner widget displaying a Surah name.
///
/// This widget renders an ornate precompiled SVG banner with the Surah name
/// centered on top, matching the traditional Mushaf surah header design.
///
/// ## Appearance
///
/// The banner features:
/// - An ornate precompiled SVG background (light or dark theme)
/// - The Surah name in QCF4_BSML (Basmalah) font
/// - Scalable width for different screen sizes
///
/// When [isDark] is null, the light or dark banner is chosen from
/// [Theme.of] brightness.
///
/// ## Usage
///
/// ```dart
/// // Light theme banner (auto from Theme)
/// SurahHeaderWidget(
///   surahData: surah,
///   width: 400,
/// )
///
/// // Dark theme banner
/// SurahHeaderWidget(
///   surahData: surah,
///   isDark: true,
///   width: 500,
/// )
/// ```
///
/// See also:
/// - [SurahNameWidget], used internally for the text
/// - [MushafFonts.basmalahFamily], the font used for Surah names
class SurahHeaderWidget extends StatefulWidget {
  /// The Surah data to display.
  ///
  /// If provided, the widget renders directly.
  /// If null, [_surahNumber] must be set to load data asynchronously.
  final Surah? _surahData;

  /// The Surah number to load asynchronously.
  ///
  /// Used when created via [SurahHeaderWidget.fromSurahNumber].
  final int? _surahNumber;

  /// Whether to use the dark theme banner variant.
  ///
  /// When `true`, uses the dark header SVG (or [customHeaderImageDark]).
  /// When `false`, uses the light header SVG (or [customHeaderImageLight]).
  /// When `null`, derives from [Theme.of] brightness.
  final bool? isDark;

  /// The width of the SVG banner.
  ///
  /// Height scales proportionally. Defaults to 500.
  final double width;

  /// The font size for the Surah name.
  ///
  /// If not provided, defaults to 25.
  final double? fontSize;

  /// Optional custom text style for the Surah name.
  ///
  /// If provided, the [MushafFonts.basmalahFamily] font is applied
  /// automatically while preserving other style properties.
  final TextStyle? textStyle;

  /// A function to modify the resolved text style.
  ///
  /// Use this for easy customization.
  final StyleModifier? styleModifier;

  /// Callback invoked when the Surah header is tapped.
  ///
  /// Receives the Surah number (1-114).
  final void Function(int surahNumber)? onTap;

  /// Callback invoked when the Surah header is long-pressed.
  ///
  /// Receives the Surah number (1-114).
  final void Function(int surahNumber)? onLongPress;

  /// Optional custom light-theme header banner asset path.
  ///
  /// If provided, used instead of [MushafConstants.surahHeaderLightAsset].
  /// Supports `.svg.vec` (precompiled), `.svg` (runtime parse), or raster.
  final String? customHeaderImageLight;

  /// Optional custom dark-theme header banner asset path.
  ///
  /// If provided, used instead of [MushafConstants.surahHeaderDarkAsset].
  /// Supports `.svg.vec` (precompiled), `.svg` (runtime parse), or raster.
  final String? customHeaderImageDark;

  /// Optional custom header banner asset path for light theme.
  ///
  /// Deprecated: use [customHeaderImageLight].
  @Deprecated('Use customHeaderImageLight instead.')
  final String? customHeaderImage;

  /// Optional repository for testing.
  final IQuranRepository? repository;

  const SurahHeaderWidget({
    super.key,
    required Surah surahData,
    this.fontSize,
    this.textStyle,
    this.styleModifier,
    this.isDark,
    this.width = 300,
    this.onTap,
    this.onLongPress,
    this.customHeaderImageLight,
    this.customHeaderImageDark,
    @Deprecated('Use customHeaderImageLight instead.') this.customHeaderImage,
    this.repository,
  }) : _surahData = surahData,
       _surahNumber = null;

  const SurahHeaderWidget.fromSurahNumber(
    int surahNumber, {
    super.key,
    this.fontSize,
    this.textStyle,
    this.styleModifier,
    this.isDark,
    this.width = 500,
    this.onTap,
    this.onLongPress,
    this.customHeaderImageLight,
    this.customHeaderImageDark,
    @Deprecated('Use customHeaderImageLight instead.') this.customHeaderImage,
    this.repository,
  }) : _surahData = null,
       _surahNumber = surahNumber;

  @override
  State<SurahHeaderWidget> createState() => _SurahHeaderWidgetState();
}

class _SurahHeaderWidgetState extends State<SurahHeaderWidget> {
  Future<Surah?>? _future;

  @override
  void initState() {
    super.initState();
    if (widget._surahData == null && widget._surahNumber != null) {
      _loadFuture();
    }
  }

  @override
  void didUpdateWidget(SurahHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._surahNumber != oldWidget._surahNumber) {
      _loadFuture();
    }
  }

  void _loadFuture() {
    _future = (widget.repository ?? HiveQuranRepository.instance).getSurah(
      widget._surahNumber!,
    );
  }

  bool _resolveIsDark(BuildContext context) {
    return widget.isDark ?? Theme.of(context).brightness == Brightness.dark;
  }

  String? _resolveLightOverride() {
    return widget.customHeaderImageLight ?? widget.customHeaderImage;
  }

  String _resolveAssetPath(bool useDark) {
    if (useDark) {
      return widget.customHeaderImageDark ??
          MushafConstants.surahHeaderDarkAsset;
    }
    return _resolveLightOverride() ?? MushafConstants.surahHeaderLightAsset;
  }

  bool _isPackageAsset(String assetPath) {
    return assetPath == MushafConstants.surahHeaderLightAsset ||
        assetPath == MushafConstants.surahHeaderDarkAsset;
  }

  bool _isCompiledSvgAsset(String assetPath) {
    return assetPath.toLowerCase().endsWith('.svg.vec');
  }

  bool _isSvgAsset(String assetPath) {
    return assetPath.toLowerCase().endsWith('.svg');
  }

  Widget _buildBannerImage(BuildContext context) {
    final useDark = _resolveIsDark(context);
    final assetPath = _resolveAssetPath(useDark);
    final isPackageAsset = _isPackageAsset(assetPath);
    final bannerKey = ValueKey('surah-header-$assetPath');

    if (_isCompiledSvgAsset(assetPath)) {
      return SvgPicture(
        AssetBytesLoader(
          assetPath,
          packageName: isPackageAsset ? packageName : null,
        ),
        key: bannerKey,
        width: widget.width,
        fit: BoxFit.contain,
      );
    }

    if (_isSvgAsset(assetPath)) {
      return SvgPicture.asset(
        assetPath,
        key: bannerKey,
        package: isPackageAsset ? packageName : null,
        width: widget.width,
        fit: BoxFit.contain,
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (widget.width * dpr).round().clamp(1, 4096);

    return Image.asset(
      assetPath,
      key: bannerKey,
      package: isPackageAsset ? packageName : null,
      width: widget.width,
      fit: BoxFit.contain,
      cacheWidth: cacheWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannerImage = _buildBannerImage(context);

    final effectiveFontSize = widget.fontSize ?? 25.0;

    // If we have surah data, render directly
    if (widget._surahData != null) {
      return _buildStack(bannerImage, effectiveFontSize, widget._surahData!);
    }

    // Otherwise, load asynchronously
    return FutureBuilder<Surah?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data == null) {
          // Show just the banner while loading
          return bannerImage;
        }
        return _buildStack(bannerImage, effectiveFontSize, snapshot.data!);
      },
    );
  }

  Widget _buildStack(
    Widget bannerImage,
    double effectiveFontSize,
    Surah surahData,
  ) {
    return GestureDetector(
      onTap: () => widget.onTap?.call(surahData.number),
      onLongPress: () => widget.onLongPress?.call(surahData.number),
      child: Stack(
        alignment: Alignment.center,
        children: [
          bannerImage,
          SurahNameWidget(
            surahData: surahData,
            fontSize: effectiveFontSize,
            textStyle: widget.textStyle,
            styleModifier: widget.styleModifier,
          ),
        ],
      ),
    );
  }
}
