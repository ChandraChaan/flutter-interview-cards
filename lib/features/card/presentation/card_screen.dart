import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../deck/presentation/deck_providers.dart';
import '../../deck/presentation/flashcard_view.dart';
import 'card_controller.dart';

/// A single card, opened from a shared `#/card/<id>` link or from Browse.
class CardScreen extends ConsumerWidget {
  const CardScreen({required this.cardId, super.key});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/browse'),
        ),
        title: Text(l10n.appTitle),
      ),
      body: switch (ref.watch(cardDetailProvider(cardId))) {
        AsyncValue(:final value?) => _CardBody(
          key: ValueKey(cardId),
          detail: value,
        ),
        AsyncData() => const _NotFound(),
        AsyncValue(hasError: true) => ErrorView(
          onRetry: () => ref.invalidate(deckProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _CardBody extends StatefulWidget {
  const _CardBody({required this.detail, super.key});

  final CardDetail detail;

  @override
  State<_CardBody> createState() => _CardBodyState();
}

class _CardBodyState extends State<_CardBody> {
  final _focusNode = FocusNode(debugLabel: 'card');
  var _revealed = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _revealed = !_revealed);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = widget.detail;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _toggle,
        const SingleActivator(LogicalKeyboardKey.enter): _toggle,
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            padding: contentPadding(
              constraints.maxWidth,
            ).copyWith(top: 8, bottom: 24),
            children: [
              FlashcardView(
                card: detail.card,
                chapter: detail.chapter,
                handbookUrl: detail.handbookUrl,
                revealed: _revealed,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    key: const Key('toggle-answer'),
                    onPressed: _toggle,
                    icon: Icon(
                      _revealed
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    label: Text(_revealed ? l10n.hideAnswer : l10n.showAnswer),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.school_outlined),
                    label: Text(l10n.studyToday),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ContentWidth(
          maxWidth: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.cardNotFoundTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.cardNotFoundBody,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => context.go('/browse'),
                child: Text(l10n.browseCards),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
