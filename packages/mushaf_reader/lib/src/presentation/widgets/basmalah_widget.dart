import 'package:flutter/material.dart';
import 'package:mushaf_reader/core/font_manager.dart';
import 'package:mushaf_reader/src/logic/mushaf_controller.dart';

class BasmalahWidget extends StatelessWidget {
  final TextStyle? textStyle;
  const BasmalahWidget({super.key, this.textStyle});

  @override
  Widget build(BuildContext context) {
    // This widget now assumes the 'QCF4_BSML' font has been pre-loaded
    // by the parent MushafPage's provider.
    return FutureBuilder<String>(
      future: MushafController.instance.getBasmalah(),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done || !snap.hasData) {
          return const SizedBox.shrink();
        }
        final glyph = snap.data ?? '';
        return Text(
          glyph,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style:
              textStyle?.copyWith(
                fontFamily: FontHelper.basmalahFamily,
                package: 'mushaf_reader',
              ) ??
              const TextStyle(
                fontFamily: FontHelper.basmalahFamily,
                package: 'mushaf_reader',
                fontSize: 21,
                height: 1.6,
                color: Color(0xFF000000),
              ),
        );
      },
    );
  }
}
