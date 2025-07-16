import 'package:flutter/widgets.dart';

class PageNumberWidget extends StatelessWidget {
  final int page;
  const PageNumberWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = TextStyle(fontSize: 20, color: Color(0xFF000000));
    return Container(
      child: Text(
        _hinduArabicNumber(page),
        style: defaultTextStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  String _hinduArabicNumber(int page) {
    return page
        .toString()
        .replaceAll('0', '٠')
        .replaceAll('1', '١')
        .replaceAll('2', '٢')
        .replaceAll('3', '٣')
        .replaceAll('4', '٤')
        .replaceAll('5', '٥')
        .replaceAll('6', '٦')
        .replaceAll('7', '٧')
        .replaceAll('8', '٨')
        .replaceAll('9', '٩');
  }
}
