import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mushaf_reader/src/presentation/widgets/surah_name_widget.dart';

class SurahHeaderWidget extends StatelessWidget {
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
    return Stack(
      alignment: Alignment.center,
      children: [
        SvgPicture.asset(
          bannerAssetPath,
          package: 'mushaf_reader',
          width: width,
        ),
        SizedBox(
          height: 50,
          child: SurahNameWidget(name: name, textStyle: textStyle),
        ),
      ],
    );
  }
}
