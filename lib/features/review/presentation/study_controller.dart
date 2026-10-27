import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../deck/domain/flashcard.dart';
import '../../deck/presentation/deck_providers.dart';
import '../domain/scheduler.dart';
import '../domain/study_progress.dart';
import 'progress_controller.dart';

/// Today's study session.
final class StudySession {
  const StudySession({
    required this.deck,
    required this.queue,
    required this.revealed,
    required this.reviewedToday,
    required this.streak,
    required this.nextIntervals,
  });

  final Deck deck;

  /// Cards still to review today; the first is on screen.
  final List<Flashcard> queue;
  final bool revealed;
  final int reviewedToday;
  final int streak;

  /// Days until the current card comes back, for each grade.
  final Map<Grade, int> nextIntervals;

  Flashcard? get current => queue.firstOrNull;

  StudySession copyWith({bool? revealed}) => StudySession(
    deck: deck,
    queue: queue,
    revealed: revealed ?? this.revealed,
    reviewedToday: reviewedToday,
    streak: streak,
    nextIntervals: nextIntervals,
  );
}

final studyControllerProvider =
    AsyncNotifierProvider<StudyController, StudySession>(StudyController.new);

class StudyController extends AsyncNotifier<StudySession> {
  @override
  Future<StudySession> build() async {
    final deck = await ref.watch(deckProvider.future);
    final progress = await ref.watch(progressControllerProvider.future);
    final scheduler = ref.watch(schedulerProvider);
    final now = ref.watch(clockProvider)();
    final queue = scheduler.dailyQueue(
      cards: deck.cards,
      progress: progress,
      now: now,
    );
    final current = queue.firstOrNull;
    return StudySession(
      deck: deck,
      queue: queue,
      revealed: false,
      reviewedToday: progress.reviewsByDay[dayKey(now)] ?? 0,
      streak: scheduler.streak(progress, now),
      nextIntervals: {
        if (current != null)
          for (final grade in Grade.values)
            grade: scheduler.intervalFor(progress.cards[current.id], grade),
      },
    );
  }

  void reveal() {
    final session = state.value;
    if (session == null || session.current == null) return;
    state = AsyncData(session.copyWith(revealed: true));
  }

  /// Grades the card on screen. Ignored until its answer has been shown.
  Future<void> grade(Grade grade) async {
    final session = state.value;
    final card = session?.current;
    if (session == null || card == null || !session.revealed) return;
    // Hide the answer straight away so a double key press can't grade twice.
    state = AsyncData(session.copyWith(revealed: false));
    await ref.read(progressControllerProvider.notifier).grade(card.id, grade);
  }
}
