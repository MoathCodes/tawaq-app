import 'package:flutter/material.dart';
import 'package:mushaf_reader/core/performance_utils.dart';

class PageNumberWidget extends StatelessWidget {
  // Static style to avoid recreation
  static const _defaultTextStyle = TextStyle(
    fontSize: 20,
    color: Color(0xFF000000),
  );

  final int page;

  const PageNumberWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Text(
      PerformanceUtils.toHinduArabicNumber(page),
      style: _defaultTextStyle,
      textAlign: TextAlign.center,
    );
  }
}
