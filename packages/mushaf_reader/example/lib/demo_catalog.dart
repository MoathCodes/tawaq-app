import 'package:example/demos/cross_page_demo.dart';
import 'package:example/demos/page_demos.dart';
import 'package:example/demos/reader_demos.dart';
import 'package:example/demos/widgets_demo.dart';
import 'package:example/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// Metadata for a showcase screen.
class MushafDemo {
  const MushafDemo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}

/// Catalog section grouping related demos.
class MushafDemoSection {
  const MushafDemoSection({
    required this.title,
    required this.demos,
  });

  final String title;
  final List<MushafDemo> demos;
}

/// All demo sections for the home screen.
List<MushafDemoSection> buildMushafDemoSections() {
  return [
    MushafDemoSection(
      title: t.catalogSections.readers,
      demos: [
        MushafDemo(
          title: t.demos.mushafReader.title,
          subtitle: t.demos.mushafReader.subtitle,
          icon: Icons.menu_book,
          builder: (context) => const FullReaderDemo(),
        ),
        MushafDemo(
          title: t.demos.twoPageSpread.title,
          subtitle: t.demos.twoPageSpread.subtitle,
          icon: Icons.view_column,
          builder: (context) => const TwoPageReaderDemo(),
        ),
      ],
    ),
    MushafDemoSection(
      title: t.catalogSections.pages,
      demos: [
        MushafDemo(
          title: t.demos.mushafPage.title,
          subtitle: t.demos.mushafPage.subtitle,
          icon: Icons.article,
          builder: (context) => const SinglePageDemo(),
        ),
        MushafDemo(
          title: t.demos.shareCard.title,
          subtitle: t.demos.shareCard.subtitle,
          icon: Icons.share,
          builder: (context) => const PageRangeShareDemo(),
        ),
        MushafDemo(
          title: t.demos.crossPageRange.title,
          subtitle: t.demos.crossPageRange.subtitle,
          icon: Icons.call_split,
          builder: (context) => const CrossPageRangeDemo(),
        ),
      ],
    ),
    MushafDemoSection(
      title: t.catalogSections.buildingBlocks,
      demos: [
        MushafDemo(
          title: t.demos.standaloneWidgets.title,
          subtitle: t.demos.standaloneWidgets.subtitle,
          icon: Icons.widgets,
          builder: (context) => const StandaloneWidgetsDemo(),
        ),
      ],
    ),
  ];
}
