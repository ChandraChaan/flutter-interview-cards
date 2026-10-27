import 'dart:math' as math;

import '../../deck/domain/flashcard.dart';
import 'study_progress.dart';

/// Where a card stands, for progress bars and the browse list.
enum CardStatus { fresh, learning, mastered }

/// Card counts for one chapter (or the whole deck).
final class Mastery {
  const Mastery({
    required this.total,
    required this.learning,
    required this.mastered,
  });

  final int total;
  final int learning;
  final int mastered;

  int get fresh => total - learning - mastered;

  /// 0 to 1: mastered cards count fully, cards being learned count half.
  double get score => total == 0 ? 0 : (mastered + learning / 2) / total;
}

/// A variant of the SM-2 spaced-repetition algorithm with four grades.
///
/// Days are local calendar days: a card due "in 1 day" is due all of
/// tomorrow, whatever time you reviewed it today. All instants are UTC.
final class Scheduler {
  const Scheduler({this.newCardsPerDay = 10});

  /// How many unseen cards a day's queue may introduce.
  final int newCardsPerDay;

  static const initialEase = 2.5;
  static const minEase = 1.3;
  static const maxIntervalDays = 365;

  /// A card whose interval reaches this many days counts as mastered.
  static const masteredAfterDays = 21;

  /// Days until the next review if [current] (null for a new card) is
  /// graded [grade]. 0 means the card comes back in today's session.
  int intervalFor(CardProgress? current, Grade grade) {
    if (grade == Grade.again) return 0;
    if (current == null || current.reps == 0) {
      return switch (grade) {
        Grade.again => 0,
        Grade.hard => 1,
        Grade.good => 2,
        Grade.easy => 4,
      };
    }
    final interval = math.max(current.intervalDays, 1);
    final hard = math.max(interval + 1, (interval * 1.2).round());
    final good = math.max(hard + 1, (interval * current.ease).round());
    final days = switch (grade) {
      Grade.again => 0,
      Grade.hard => hard,
      Grade.good => good,
      Grade.easy => math.max(good + 1, (interval * current.ease * 1.3).round()),
    };
    return math.min(days, maxIntervalDays);
  }

  /// The schedule for [cardId] after grading it [grade] at [now].
  CardProgress schedule({
    required String cardId,
    required CardProgress? current,
    required Grade grade,
    required DateTime now,
  }) {
    final nowUtc = now.toUtc();
    final ease = current?.ease ?? initialEase;
    final interval = intervalFor(current, grade);
    final reps = current?.reps ?? 0;
    return CardProgress(
      cardId: cardId,
      reps: grade == Grade.again ? 0 : reps + 1,
      lapses:
          (current?.lapses ?? 0) + (grade == Grade.again && reps > 0 ? 1 : 0),
      intervalDays: interval,
      ease: switch (grade) {
        Grade.again => math.max(minEase, ease - 0.2),
        Grade.hard => math.max(minEase, ease - 0.15),
        Grade.good => ease,
        Grade.easy => ease + 0.15,
      },
      due: nowUtc.add(Duration(days: interval)),
      lastReviewed: nowUtc,
    );
  }

  /// [progress] after reviewing [cardId]: reschedules the card and counts
  /// the review towards today's streak and new-card limit.
  StudyProgress review({
    required StudyProgress progress,
    required String cardId,
    required Grade grade,
    required DateTime now,
  }) {
    final current = progress.cards[cardId];
    final today = dayKey(now);
    return progress.copyWith(
      cards: {
        ...progress.cards,
        cardId: schedule(
          cardId: cardId,
          current: current,
          grade: grade,
          now: now,
        ),
      },
      reviewsByDay: {
        ...progress.reviewsByDay,
        today: (progress.reviewsByDay[today] ?? 0) + 1,
      },
      newCardsByDay: current == null
          ? {
              ...progress.newCardsByDay,
              today: (progress.newCardsByDay[today] ?? 0) + 1,
            }
          : null,
    );
  }

  bool isDue(CardProgress card, DateTime now) =>
      dayKey(card.due).compareTo(dayKey(now)) <= 0;

  /// Today's queue: due cards (most overdue first), then new cards in
  /// handbook order up to the daily new-card limit.
  List<Flashcard> dailyQueue({
    required List<Flashcard> cards,
    required StudyProgress progress,
    required DateTime now,
  }) {
    final due = [
      for (final card in cards)
        if (progress.cards[card.id] case final p? when isDue(p, now)) card,
    ];
    // Dart's sort isn't stable, so break ties on deck order.
    final order = {for (final (i, card) in cards.indexed) card.id: i};
    due.sort((a, b) {
      final byDue = progress.cards[a.id]!.due.compareTo(
        progress.cards[b.id]!.due,
      );
      return byDue != 0 ? byDue : order[a.id]!.compareTo(order[b.id]!);
    });
    final newToday = progress.newCardsByDay[dayKey(now)] ?? 0;
    final fresh = cards
        .where((card) => !progress.cards.containsKey(card.id))
        .take(math.max(0, newCardsPerDay - newToday));
    return [...due, ...fresh];
  }

  CardStatus statusOf(CardProgress? card) => switch (card) {
    null => CardStatus.fresh,
    CardProgress(:final intervalDays) when intervalDays >= masteredAfterDays =>
      CardStatus.mastered,
    _ => CardStatus.learning,
  };

  Mastery mastery(Iterable<Flashcard> cards, StudyProgress progress) {
    var total = 0;
    var learning = 0;
    var mastered = 0;
    for (final card in cards) {
      total++;
      switch (statusOf(progress.cards[card.id])) {
        case CardStatus.fresh:
          break;
        case CardStatus.learning:
          learning++;
        case CardStatus.mastered:
          mastered++;
      }
    }
    return Mastery(total: total, learning: learning, mastered: mastered);
  }

  /// Days in a row with at least one review, ending today. A streak isn't
  /// broken until a whole day passes without reviewing, so if you haven't
  /// reviewed yet today it counts up to yesterday.
  int streak(StudyProgress progress, DateTime now) {
    final local = now.toLocal();
    var day = DateTime(local.year, local.month, local.day);
    if ((progress.reviewsByDay[dayKey(day)] ?? 0) == 0) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while ((progress.reviewsByDay[dayKey(day)] ?? 0) > 0) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }
}

/// The local calendar day of [instant] as `yyyy-mm-dd`.
String dayKey(DateTime instant) {
  final local = instant.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}
