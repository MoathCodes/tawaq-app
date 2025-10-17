import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      footer: Row(
        children: [FButton.icon(onPress: () {}, child: const Text('Action'))],
      ),
      child: const Column(children: [Row()]),
    );
  }
}
