import 'package:flutter/widgets.dart';
import 'package:mushaf_reader/core/font_manager.dart';

class SurahNameWidget extends StatelessWidget {
  final String name;

  final TextStyle? textStyle;
  const SurahNameWidget({super.key, required this.name, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style:
          textStyle?.copyWith(
            fontFamily: FontHelper.basmalahFamily,
            package: 'mushaf_reader',
          ) ??
          const TextStyle(
            fontFamily: FontHelper.basmalahFamily,
            package: 'mushaf_reader',
            fontSize: 24,
            height: 1.6,
            color: Color(0xFF000000),
          ),
    );
  }
}
