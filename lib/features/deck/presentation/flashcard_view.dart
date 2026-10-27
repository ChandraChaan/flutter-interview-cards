import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/links.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/flashcard.dart';

/// One card: the question, and the answer once [revealed].
class FlashcardView extends StatelessWidget {
  const FlashcardView({
    required this.card,
    required this.chapter,
    required this.handbookUrl,
    required this.revealed,
    super.key,
  });

  final Flashcard card;
  final Chapter chapter;
  final Uri handbookUrl;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 8, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                LevelChip(level: card.level),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).chapterLabel(chapter.number, chapter.title),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _CardActions(cardId: card.id, handbookUrl: handbookUrl),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Semantics(
                header: true,
                child: MarkdownText(
                  card.question,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: revealed
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16, right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          MarkdownText(
                            card.answer,
                            key: const Key('answer'),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({required this.cardId, required this.handbookUrl});

  final String cardId;
  final Uri handbookUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.copyLink,
          icon: const Icon(Icons.link),
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: cardShareUrl(cardId).toString()),
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
          },
        ),
        IconButton(
          tooltip: l10n.openInHandbook,
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: () => launchUrl(handbookUrl),
        ),
      ],
    );
  }
}

/// The level's name with its colour as a dot, e.g. "● Senior".
class LevelChip extends StatelessWidget {
  const LevelChip({required this.level, super.key});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.extension<LevelColors>()!.of(level);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: color)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 6),
            Text(levelName(context, level), style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

String levelName(BuildContext context, Level level) {
  final l10n = AppLocalizations.of(context);
  return switch (level) {
    Level.junior => l10n.levelJunior,
    Level.senior => l10n.levelSenior,
    Level.architect => l10n.levelArchitect,
  };
}

/// Renders the handbook's Markdown with the app's theme, code blocks
/// included.
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.data, {this.style, super.key});

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mono = theme.textTheme.bodyMedium?.copyWith(
      // Bundled, because the web renderer can't use system fonts.
      fontFamily: 'RobotoMono',
      fontSize: (style?.fontSize ?? 16) * 0.85,
      backgroundColor: scheme.surfaceContainerHighest,
      color: scheme.onSurface,
    );
    return MarkdownBody(
      data: data,
      selectable: true,
      onTapLink: (text, href, title) {
        final uri = href == null ? null : Uri.tryParse(href);
        if (uri != null && uri.hasScheme) launchUrl(uri);
      },
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: style,
        listBullet: style,
        strong: style?.copyWith(fontWeight: FontWeight.w700),
        code: mono,
        codeblockPadding: const EdgeInsets.all(14),
        codeblockDecoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        blockSpacing: 12,
      ),
    );
  }
}
