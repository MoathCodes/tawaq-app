import 'dart:async';

import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/core/utils/package_metadata_provider.dart';
import 'package:tawaq/core/utils/external_link_provider.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/about/domain/models/about_content.dart';
import 'package:tawaq/feature/about/presentation/about_strings.dart';
import 'package:tawaq/gen/assets.gen.dart';
import 'package:tawaq/theme/theme.dart';

/// The scrollable content of the about dialog.
///
/// Pure presentation over an [AboutContent]; every section is hidden when its
/// backing list is empty, so it adapts to whatever lives in `about_info.dart`.
class AboutView extends ConsumerWidget {
  /// Creates an [AboutView].
  const new({required this.content, super.key});

  /// The content to render.
  final AboutContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;

    final sections = <Widget>[
      _AboutHeader(
        content: content,
        version: content.version.isNotEmpty
            ? content.version
            : ref
                  .watch(packageMetadataProvider)
                  .when(
                    data: (info) => '${info.version}+${info.buildNumber}',
                    loading: () => AboutStrings.versionLoading.resolve(context),
                    error: (_, _) =>
                        AboutStrings.versionUnavailable.resolve(context),
                  ),
      ),
      Text(
        content.description.resolve(context),
        textAlign: TextAlign.start,
        style: theme.typography.body.sm.copyWith(
          color: colors.mutedForeground,
          height: 1.6,
        ),
      ),
      if (content.facts.isNotEmpty) _AboutFacts(facts: content.facts),
      if (content.links.isNotEmpty)
        _AboutSection(
          icon: FLucideIcons.link,
          title: AboutStrings.links.resolve(context),
          child: FTileGroup(
            children: [
              for (final link in content.links) _linkTile(context, link),
            ],
          ),
        ),
      if (content.credits.isNotEmpty)
        _AboutSection(
          icon: FLucideIcons.users,
          title: AboutStrings.credits.resolve(context),
          child: FTileGroup(
            children: [
              for (final credit in content.credits)
                _creditTile(context, credit),
            ],
          ),
        ),
      if (content.acknowledgements.isNotEmpty)
        _AboutSection(
          icon: FLucideIcons.heartHandshake,
          title: AboutStrings.acknowledgements.resolve(context),
          child: FTileGroup(
            children: [
              for (final ack in content.acknowledgements)
                _acknowledgementTile(context, ack),
            ],
          ),
        ),
      if (content.legal != null)
        Text(
          content.legal!.resolve(context),
          textAlign: TextAlign.center,
          style: theme.typography.body.xs.copyWith(
            color: colors.mutedForeground,
          ),
        ),
      const SizedBox(height: AppSpacing.xs),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xl,
      children: [...sections],
    );
  }

  FTile _linkTile(BuildContext context, AboutLink link) => FTile(
    prefix: Icon(link.icon),
    title: Text(link.label.resolve(context)),
    subtitle: link.description == null
        ? null
        : Text(link.description!.resolve(context)),
    suffix: const Icon(FLucideIcons.arrowUpRight),
    onPress: () => unawaited(_openAboutLink(context, link.url)),
  );

  FTile _creditTile(BuildContext context, AboutCredit credit) => FTile(
    prefix: Icon(credit.icon),
    title: Text(credit.name.resolve(context)),
    subtitle: credit.role == null ? null : Text(credit.role!.resolve(context)),
    suffix: credit.url == null ? null : const Icon(FLucideIcons.arrowUpRight),
    onPress: credit.url == null
        ? null
        : () => unawaited(_openAboutLink(context, credit.url!)),
  );

  FTile _acknowledgementTile(BuildContext context, AboutAcknowledgement ack) =>
      FTile(
        prefix: const Icon(FLucideIcons.layers),
        title: Text(ack.name),
        subtitle: ack.description == null
            ? null
            : Text(ack.description!.resolve(context)),
        suffix: ack.url == null ? null : const Icon(FLucideIcons.arrowUpRight),
        onPress: ack.url == null
            ? null
            : () => unawaited(_openAboutLink(context, ack.url!)),
      );
}

class _AboutHeader extends StatelessWidget {
  const new({required this.content, required this.version});
  final String version;

  final AboutContent content;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    return Row(
      spacing: AppSpacing.md,
      children: [
        ClipRRect(
          borderRadius: theme.radii.md,
          child: Assets.images.appIcon.image(width: 48, height: 48),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.appName,
                style: typography.body.lg.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                version,
                style: typography.body.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _openAboutLink(BuildContext context, String url) async {
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    if (await container.read(externalLinkLauncherProvider)(Uri.parse(url)))
      return;
  } catch (error, stack) {
    container
        .read(loggerProvider)
        .w('Could not open external link', error: error, stackTrace: stack);
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(AboutStrings.linkFailed.resolve(context)),
      content: SelectableText(url),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(AboutStrings.close.resolve(context)),
        ),
        TextButton(
          onPressed: () async {
            await _copyAboutLink(context, url);
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: Text(AboutStrings.copyLink.resolve(context)),
        ),
      ],
    ),
  );
}

Future<void> _copyAboutLink(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  showFToast(
    context: context,
    title: Text(AboutStrings.linkCopied.resolve(context)),
  );
}

/// A labelled section: a small icon + heading above arbitrary [child] content.
class _AboutSection extends StatelessWidget {
  const new({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            Icon(icon, size: 16, color: colors.mutedForeground),
            Text(
              title,
              style: theme.typography.body.sm.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }
}

/// The horizontal strip of quick-fact pills below the header.
class _AboutFacts extends StatelessWidget {
  const new({required this.facts});

  final List<AboutFact> facts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [for (final fact in facts) _FactChip(fact: fact)],
    );
  }
}

class _FactChip extends StatelessWidget {
  const new({required this.fact});

  final AboutFact fact;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: theme.radii.full,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: [
            Icon(fact.icon, size: 14, color: colors.mutedForeground),
            Text(
              fact.label.resolve(context),
              style: theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
              ),
            ),
            Text(
              fact.value.resolve(context),
              style: theme.typography.body.xs.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
