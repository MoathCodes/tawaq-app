import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mushaf_reader/src/presentation/widgets/surah_name_widget.dart';

class SurahHeaderWidget extends StatelessWidget {
  // Static caching for SVG pictures to avoid repeated loading
  static final Map<String, Widget> _svgCache = {};
  final String name;
  final bool? isDark;
  final double width;

  final TextStyle? textStyle;

  const SurahHeaderWidget({
    super.key,
    required this.name,
    this.textStyle,
    this.isDark,
    this.width = 500,
  });

  @override
  Widget build(BuildContext context) {
    final bannerAssetPath = isDark == true
        ? 'assets/images/surah_banner_dark.svg'
        : 'assets/images/surah_banner.svg';

    // Use cached SVG or create new one
    final svgWidget = _svgCache.putIfAbsent('${bannerAssetPath}_$width', () {
      return SvgPicture.asset(
        bannerAssetPath,
        package: 'mushaf_reader',
        width: width,
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        svgWidget,
        SizedBox(
          height: 50,
          child: SurahNameWidget(name: name, textStyle: textStyle),
        ),
      ],
    );
  }

  /// Clear SVG cache if needed for memory management
  static void clearCache() {
    _svgCache.clear();
  }
}
