// part of '../flutter_quran_screen.dart';

import 'package:flutter_quran/flutter_quran.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class BasmallahWidget extends StatelessWidget {
  const BasmallahWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
        style: FlutterQuran().hafsStyle,
      ),
    );
  }
}
