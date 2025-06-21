part of '../flutter_quran_screen.dart';

class QuranLine extends StatelessWidget {
  final Line line;

  final BoxFit boxFit;
  final Function? onLongPress;
  final BoxDecoration? ayahDecoration;
  const QuranLine(
    this.line, {
    super.key,
    this.boxFit = BoxFit.fill,
    this.onLongPress,
    this.ayahDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: line.ayahs.reversed.map((ayah) {
              return Expanded(
                child: GestureDetector(
                  onLongPress: () {
                    if (onLongPress != null) {
                      onLongPress!(ayah);
                    }
                  },
                  child: Container(
                    decoration: ayahDecoration,
                    child: Text(
                      ayah.ayah,
                      style: FlutterQuran().hafsStyle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
