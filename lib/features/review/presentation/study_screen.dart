import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../deck/presentation/deck_providers.dart';
import '../../deck/presentation/flashcard_view.dart';
import '../domain/study_progress.dart';
import 'progress_controller.dart';
import 'study_controller.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(studyControllerProvider)) {
      AsyncValue(:final value?) => _StudyView(session: value),
      AsyncValue(hasError: true) => ErrorView(
        onRetry: () => ref
          ..invalidate(deckProvider)
          ..invalidate(progressControllerProvider),
      ),
      _ => const LoadingView(),
    };
  }
}

class _StudyView extends ConsumerStatefulWidget {
  const _StudyView({required this.session});

  final StudySession session;

  @override
  ConsumerState<_StudyView> createState() => _StudyViewState();
}

class _StudyViewState extends ConsumerState<_StudyView> {
  final _focusNode = FocusNode(debugLabel: 'study');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _reveal() {
    ref.read(studyControllerProvider.notifier).reveal();
    _focusNode.requestFocus();
  }

  Future<void> _grade(Grade grade) async {
    _focusNode.requestFocus();
    await ref.read(studyControllerProvider.notifier).grade(grade);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final card = session.current;
    if (card == null) return _DoneView(session: session);

    const digits = [
      (LogicalKeyboardKey.digit1, LogicalKeyboardKey.numpad1),
      (LogicalKeyboardKey.digit2, LogicalKeyboardKey.numpad2),
      (LogicalKeyboardKey.digit3, LogicalKeyboardKey.numpad3),
      (LogicalKeyboardKey.digit4, LogicalKeyboardKey.numpad4),
    ];
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _reveal,
        const SingleActivator(LogicalKeyboardKey.enter): _reveal,
        for (final (i, (digit, numpad)) in digits.indexed) ...{
          SingleActivator(digit): () => _grade(Grade.values[i]),
          SingleActivator(numpad): () => _grade(Grade.values[i]),
        },
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                // A new scroll position per card, so each starts at the top.
                key: ValueKey(card.id),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SessionHeader(session: session),
                      const SizedBox(height: 12),
                      FlashcardView(
                        card: card,
                        chapter: session.deck.chapterOf(card),
                        handbookUrl: session.deck.handbookUrl(card),
                        revealed: session.revealed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _ActionBar(session: session, onReveal: _reveal, onGrade: _grade),
          ],
        ),
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.session});

  final StudySession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(l10n.cardsLeft(session.queue.length), style: style),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              size: 18,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 4),
            Text(l10n.streakDays(session.streak), style: style),
          ],
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.session,
    required this.onReveal,
    required this.onGrade,
  });

  final StudySession session;
  final VoidCallback onReveal;
  final ValueChanged<Grade> onGrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final showKeys = kIsWeb && MediaQuery.sizeOf(context).width >= 600;
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: ContentWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (session.revealed)
                  Row(
                    children: [
                      for (final grade in Grade.values) ...[
                        if (grade != Grade.again) const SizedBox(width: 8),
                        Expanded(
                          child: _GradeButton(
                            grade: grade,
                            days: session.nextIntervals[grade] ?? 0,
                            shortcut: showKeys ? grade.index + 1 : null,
                            onPressed: () => onGrade(grade),
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  FilledButton.icon(
                    key: const Key('show-answer'),
                    onPressed: onReveal,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(l10n.showAnswer),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                if (showKeys) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.keyboardHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.grade,
    required this.days,
    required this.shortcut,
    required this.onPressed,
  });

  final Grade grade;
  final int days;

  /// The number key for this grade, shown on keyboards.
  final int? shortcut;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (grade) {
      Grade.again => l10n.gradeAgain,
      Grade.hard => l10n.gradeHard,
      Grade.good => l10n.gradeGood,
      Grade.easy => l10n.gradeEasy,
    };
    final when = l10n.nextReview(days);
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(shortcut == null ? label : l10n.withShortcut(shortcut!, label)),
          Text(
            when,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 56)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 4),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    return Semantics(
      button: true,
      label: '$label, $when',
      excludeSemantics: true,
      child: grade == Grade.good
          ? FilledButton(
              key: Key('grade-${grade.name}'),
              onPressed: onPressed,
              style: style,
              child: child,
            )
          : FilledButton.tonal(
              key: Key('grade-${grade.name}'),
              onPressed: onPressed,
              style: style,
              child: child,
            ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.session});

  final StudySession session;

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
              Icon(Icons.task_alt, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.doneTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.doneBody(session.reviewedToday),
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/browse'),
                    icon: const Icon(Icons.search),
                    label: Text(l10n.browseCards),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/progress'),
                    icon: const Icon(Icons.insights_outlined),
                    label: Text(l10n.seeProgress),
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
