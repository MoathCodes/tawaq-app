import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_recent_search.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';

class _MockHadithRepository extends Mock implements HadithRepository {}

void main() {
  test('concurrent additions publish every persisted recent search', () async {
    final repository = _MockHadithRepository();
    final firstWrite = Completer<void>();
    final persisted = <String>[];
    var writeCount = 0;

    when(repository.getRecentSearches).thenAnswer(
      (_) async => [
        for (var i = 0; i < persisted.length; i++)
          HadithRecentSearch(
            id: i,
            query: persisted.reversed.elementAt(i),
            searchedAt: DateTime(2026),
          ),
      ],
    );
    when(() => repository.addRecentSearch(any())).thenAnswer((
      invocation,
    ) async {
      writeCount++;
      if (writeCount == 1) await firstWrite.future;
      persisted.add(invocation.positionalArguments.single as String);
    });

    final container = ProviderContainer(
      overrides: [
        hadithRepositoryProvider.overrideWith((_) async => repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(hadithRecentSearchesStoreProvider.future);

    final first = container
        .read(hadithRecentSearchesStoreProvider.notifier)
        .add('first');
    final second = container
        .read(hadithRecentSearchesStoreProvider.notifier)
        .add('second');
    await Future<void>.delayed(Duration.zero);

    expect(writeCount, 1, reason: 'the second write must wait for the first');
    firstWrite.complete();
    await Future.wait([first, second]);

    expect(
      container.read(hadithRecentSearchesStoreProvider).requireValue,
      ['second', 'first'],
    );
  });
}
