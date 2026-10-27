import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../deck/domain/flashcard.dart';
import '../../deck/presentation/deck_providers.dart';
import '../../review/domain/scheduler.dart';
import '../../review/presentation/progress_controller.dart';

final class ChapterMastery {
  const ChapterMastery({required this.chapter, required this.mastery});

  final Chapter chapter;
  final Mastery mastery;
}

final class ProgressSummary {
  const ProgressSummary({
    required this.streak,
    required this.reviewedToday,
    required this.dueToday,
    required this.overall,
    required this.chapters,
  });

  final int streak;
  final int reviewedToday;

  /// Cards in today's queue, new ones included.
  final int dueToday;
  final Mastery overall;
  final List<ChapterMastery> chapters;
}

final progressSummaryProvider = FutureProvider<ProgressSummary>((ref) async {
  final deck = await ref.watch(deckProvider.future);
  final progress = await ref.watch(progressControllerProvider.future);
  final scheduler = ref.watch(schedulerProvider);
  final now = ref.watch(clockProvider)();
  return ProgressSummary(
    streak: scheduler.streak(progress, now),
    reviewedToday: progress.reviewsByDay[dayKey(now)] ?? 0,
    dueToday: scheduler
        .dailyQueue(cards: deck.cards, progress: progress, now: now)
        .length,
    overall: scheduler.mastery(deck.cards, progress),
    chapters: [
      for (final chapter in deck.chapters)
        ChapterMastery(
          chapter: chapter,
          mastery: scheduler.mastery(
            deck.cards.where((c) => c.chapterId == chapter.id),
            progress,
          ),
        ),
    ],
  );
});
