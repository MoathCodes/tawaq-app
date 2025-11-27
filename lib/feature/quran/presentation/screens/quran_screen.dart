import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/feature/quran/presentation/widgets/hadith_card.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hadithQuery = DorarClient.use(
      (c) => c.searchHadithDetailed(
        .new(value: 'عبادي'),
      ),
    );
    return FScaffold(
      footer: Row(
        children: [FButton.icon(onPress: () {}, child: const Text('Action'))],
      ),
      child: Column(
        children: [
          FutureBuilder(
            future: hadithQuery,
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (asyncSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Error: ${asyncSnapshot.error}'),
                  ),
                );
              }

              final data = asyncSnapshot.data?.data;

              if (data == null || data.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No hadiths found'),
                  ),
                );
              }

              return Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return HadithCard(hadith: data[index]);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
