import 'package:flutter/material.dart';
import 'package:mushaf_reader/core/font_manager.dart';
import 'package:mushaf_reader/src/data/models/juz_model.dart';
import 'package:mushaf_reader/src/logic/mushaf_controller.dart';

class JuzWidget extends StatelessWidget {
  final int number;
  final TextStyle? textStyle;
  const JuzWidget({super.key, required this.number, this.textStyle});

  @override
  Widget build(BuildContext context) {
    // This widget now assumes the 'QCF4_BSML' font has been pre-loaded.
    return FutureBuilder<JuzModel>(
      future: MushafController.instance.getJuz(number),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done || !snap.hasData) {
          return const SizedBox.shrink();
        }
        final juz = snap.data!;
        return Text(
          juz.codeV4,
          textDirection: TextDirection.rtl,
          style:
              textStyle?.copyWith(
                fontFamily: FontHelper.basmalahFamily,
                package: 'mushaf_reader',
              ) ??
              const TextStyle(
                fontFamily: FontHelper.basmalahFamily,
                package: 'mushaf_reader',
                fontSize: 28,
                height: 1.6,
                color: Color(0xFF000000),
              ),
        );
      },
    );
  }
}
