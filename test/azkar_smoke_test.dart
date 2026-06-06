import 'package:flutter_test/flutter_test.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';

void main() {
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
