import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';

void main() {
  final n = 42145;
  final list = n.toString().split('')
    ..sort(
      (a, b) => int.parse(a).compareTo(int.parse(b)),
    );
  print(int.parse(list.join('')));

  test('hisn_elmoslem returns arabic titles and contents', () async {
    final client = await HisnClient.openFromDirectory(
      'packages/hisn_elmoslem/assets/database',
    );
    addTearDown(client.close);

    final titles = client.titles.all();
    expect(titles, isNotEmpty);

    final contents = client.contents.byTitleId(titles.first.id);
    expect(contents, isNotEmpty);
    expect(contents.first.source, isA<String>());
  });
}

List<dynamic> iterPi(double epsilon) {
  double current = 1.0;
  int currentOdd = 3;
  int counter = 0;
  bool isMinus = true;
  //   print((pi - (4 * current)));
  while ((pi - (4 * current)).clamp(0, 1) <= epsilon) {
    final num = isMinus ? (1 / -(currentOdd)) : 1 / (currentOdd);
    current += num;
    isMinus = !isMinus;
    currentOdd += 2;
    counter++;
    print("PI: ${current * 4}");

    print(
      "number to be added: ${isMinus ? "-1/${currentOdd}" : "1/$currentOdd"}",
    );
    print("currentOdd: $currentOdd");
    //     current += (counter % 2 == 0 ? (-1 / counter + 1) : (1 / counter));
  }
  return [counter, "${current * 4}"];
}
