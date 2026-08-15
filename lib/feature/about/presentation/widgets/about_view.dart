import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/feature/about/domain/models/about_content.dart';
import 'package:tawaq/feature/about/presentation/about_strings.dart';
import 'package:tawaq/gen/assets.gen.dart';
import 'package:tawaq/theme/theme.dart';

/// The scrollable content of the about dialog.
///
/// Pure presentation over an [AboutContent]; every section is hidden when its
/// backing list is empty, so it adapts to whatever lives in `about_info.dart`.
class AboutView extends StatelessWidget {
  /// Creates an [AboutView].
  const AboutView({required this.content, super.key});

  /// The content to render.
  final AboutContent content;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    final sections = <Widget>[
      _AboutHeader(content: content),
      Text(
        content.description.resolve(context),
        textAlign: TextAlign.center,
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
      children: [
        for (final (index, section) in sections.indexed)
          AnimationEntry(
            delay: Duration(milliseconds: 40 * index),
            child: section,
          ),
      ],
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

  FTile _acknowledgementTile(
    BuildContext context,
    AboutAcknowledgement ack,
  ) => FTile(
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

const _kLogoSize = 84.0;

class _AboutHeader extends StatelessWidget {
  const _AboutHeader({required this.content});

  final AboutContent content;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: theme.radii.xl,
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.18),
                blurRadius: 28,
                spreadRadius: 1,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: theme.radii.xl,
            child: Assets.images.appIcon.image(
              width: _kLogoSize,
              height: _kLogoSize,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          content.appName,
          textAlign: TextAlign.center,
          style: typography.body.xl2.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          content.latinName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: typography.body.sm.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FBadge(
          variant: FBadgeVariant.secondary,
          child: Text(content.version),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          content.tagline.resolve(context),
          textAlign: TextAlign.center,
          style: typography.body.sm.copyWith(color: colors.mutedForeground),
        ),
      ],
    );
  }
}

Future<void> _openAboutLink(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  showFToast(
    context: context,
    title: Text(AboutStrings.linkCopied.resolve(context)),
  );
}

/// A labelled section: a small icon + heading above arbitrary [child] content.
class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.icon,
    required this.title,
    required this.child,
  });

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
  const _AboutFacts({required this.facts});

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
  const _FactChip({required this.fact});

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
