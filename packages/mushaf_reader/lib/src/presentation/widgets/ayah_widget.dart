import 'package:flutter/material.dart';
import 'package:mushaf_reader/core/font_manager.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// Displays part of the page text with per-ayah mouse-over / tap highlight.
class AyahWidget extends StatelessWidget {
  final int ayah;
  final int surah;
  final int? ayahId;
  final TextStyle? style;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  const AyahWidget({
    super.key,
    required this.ayah,
    required this.surah,
    this.ayahId,
    this.style,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final getAyah = MushafController.instance.getAyahBySurah(surah, ayah);

    return FutureBuilder(
      future: getAyah,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return errorWidget ?? Center(child: Text('Error: ${snapshot.error}'));
        }
        // Use the ayah's page to determine the correct font chunk
        final pageFontFamily = FontHelper.getFontFamilyForPage(
          snapshot.data!.page,
        );

        final defaultAyahStyle = TextStyle(
          fontFamily: pageFontFamily,
          package: 'mushaf_reader',
          fontSize: 28,
          height: 1.6,
          color: const Color(0xFF000000),
        );
        return Text(
          snapshot.data!.codeV4,
          textAlign: TextAlign.right,
          style:
              style?.copyWith(
                fontFamily: pageFontFamily,
                package: 'mushaf_reader',
              ) ??
              defaultAyahStyle,
        );
      },
    );
  }
}
