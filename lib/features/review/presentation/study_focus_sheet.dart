import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../deck/domain/flashcard.dart';
import '../../deck/presentation/flashcard_view.dart';
import '../domain/study_focus.dart';
import 'study_focus_controller.dart';

Future<void> showStudyFocusSheet(
  BuildContext context,
  List<Chapter> chapters,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => StudyFocusSheet(chapters: chapters),
);

/// Short description of [focus], e.g. "Focus: 2 chapters · Senior".
String focusLabel(BuildContext context, StudyFocus focus) {
  final l10n = AppLocalizations.of(context);
  if (focus.isAll) return l10n.focusAll;
  final chapters = focus.chapterIds.isEmpty
      ? l10n.allChapters
      : l10n.chapterCount(focus.chapterIds.length);
  final levels = focus.levels.isEmpty
      ? l10n.allLevels
      : [
          for (final level in Level.values)
            if (focus.levels.contains(level)) levelName(context, level),
        ].join(', ');
  return l10n.focusSome(chapters, levels);
}

/// Lets you limit today's queue to some chapters and levels, for example
/// to prepare for a senior interview or to revise one weak chapter.
class StudyFocusSheet extends ConsumerWidget {
  const StudyFocusSheet({required this.chapters, super.key});

  final List<Chapter> chapters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final focus = ref.watch(studyFocusProvider);
    final controller = ref.read(studyFocusProvider.notifier);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Text(l10n.focusTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            l10n.focusExplainer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.levels, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in Level.values)
                FilterChip(
                  label: Text(levelName(context, level)),
                  selected: focus.levels.contains(level),
                  onSelected: (_) => controller.toggleLevel(level),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(l10n.chapters, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chapter in chapters)
                FilterChip(
                  key: ValueKey('focus-${chapter.id}'),
                  label: Text(l10n.chapterLabel(chapter.number, chapter.title)),
                  selected: focus.chapterIds.contains(chapter.id),
                  onSelected: (_) => controller.toggleChapter(chapter.id),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: focus.isAll ? null : controller.clear,
                child: Text(l10n.studyEverything),
              ),
              FilledButton(
                key: const Key('focus-done'),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.done),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
