import 'package:flutter_quran/flutter_quran.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class AyahWidget extends StatelessWidget {
  final Ayah ayah;

  const AyahWidget(this.ayah, {super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
        text: TextSpan(
      children:
          ayah.ayah.split(' ').map((word) => TextSpan(text: word)).toList(),
      style: FlutterQuran().hafsStyle,
    ));
  }
}
