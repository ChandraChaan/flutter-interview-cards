import 'package:flutter_interview_cards/features/review/domain/scheduler.dart';
import 'package:flutter_interview_cards/features/review/domain/study_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Noon local time, so day arithmetic is the same in every time zone.
DateTime day(int d, {int hour = 12}) => DateTime(2026, 3, d, hour).toUtc();

void main() {
  const scheduler = Scheduler(newCardsPerDay: 2);

  group('intervalFor', () {
    test('a new card: again today, then 1, 2 and 4 days', () {
      expect(
        [for (final g in Grade.values) scheduler.intervalFor(null, g)],
        [0, 1, 2, 4],
      );
    });

    test('a learned card grows by its ease, and the grades stay ordered', () {
      final card = scheduler.schedule(
        cardId: 'c',
        current: null,
        grade: Grade.good,
        now: day(1),
      );
      expect(card.intervalDays, 2);
      expect(
        [for (final g in Grade.values) scheduler.intervalFor(card, g)],
        [0, 3, 5, 7],
      );
    });

    test('never schedules more than a year ahead', () {
      final card = CardProgress(
        cardId: 'c',
        reps: 9,
        lapses: 0,
        intervalDays: 300,
        ease: 3,
        due: day(1),
        lastReviewed: day(1),
      );
      expect(
        scheduler.intervalFor(card, Grade.easy),
        Scheduler.maxIntervalDays,
      );
    });
  });

  group('schedule', () {
    test('good, good, good: 2, 5, then 13 days, due in UTC', () {
      CardProgress? card;
      var now = day(1);
      final intervals = <int>[];
      for (var i = 0; i < 3; i++) {
        card = scheduler.schedule(
          cardId: 'c',
          current: card,
          grade: Grade.good,
          now: now,
        );
        intervals.add(card.intervalDays);
        expect(card.due, now.add(Duration(days: card.intervalDays)));
        expect(card.due.isUtc, isTrue);
        now = card.due;
      }
      expect(intervals, [2, 5, 13]);
      expect(card!.reps, 3);
    });

    test('again resets reps, counts a lapse and lowers ease to a floor', () {
      var card = scheduler.schedule(
        cardId: 'c',
        current: null,
        grade: Grade.good,
        now: day(1),
      );
      for (var i = 0; i < 10; i++) {
        card = scheduler.schedule(
          cardId: 'c',
          current: card,
          grade: Grade.again,
          now: day(3),
        );
      }
      expect(card.reps, 0);
      expect(card.intervalDays, 0);
      expect(card.lapses, 1, reason: 'only forgetting a learned card lapses');
      expect(card.ease, Scheduler.minEase);
      expect(scheduler.isDue(card, day(3)), isTrue);
    });

    test('easy raises ease; hard lowers it', () {
      final easy = scheduler.schedule(
        cardId: 'c',
        current: null,
        grade: Grade.easy,
        now: day(1),
      );
      final hard = scheduler.schedule(
        cardId: 'c',
        current: null,
        grade: Grade.hard,
        now: day(1),
      );
      expect(easy.ease, greaterThan(Scheduler.initialEase));
      expect(hard.ease, lessThan(Scheduler.initialEase));
    });
  });

  test('a card is due from the start of its due day', () {
    final card = scheduler.schedule(
      cardId: 'c',
      current: null,
      grade: Grade.hard,
      now: day(1, hour: 22),
    );
    expect(scheduler.isDue(card, day(1, hour: 23)), isFalse);
    expect(scheduler.isDue(card, day(2, hour: 1)), isTrue);
    expect(scheduler.isDue(card, day(9)), isTrue);
  });

  group('review', () {
    test('counts reviews per day and new cards only once', () {
      var progress = StudyProgress.empty;
      progress = scheduler.review(
        progress: progress,
        cardId: 'a',
        grade: Grade.again,
        now: day(1),
      );
      progress = scheduler.review(
        progress: progress,
        cardId: 'a',
        grade: Grade.good,
        now: day(1),
      );
      expect(progress.reviewsByDay, {dayKey(day(1)): 2});
      expect(progress.newCardsByDay, {dayKey(day(1)): 1});
      expect(progress.cards['a']!.intervalDays, 2);
    });
  });

  group('dailyQueue', () {
    final deck = testDeck();

    test('starts with new cards, up to the daily limit', () {
      final queue = scheduler.dailyQueue(
        cards: deck.cards,
        progress: StudyProgress.empty,
        now: day(1),
      );
      expect(queue.map((c) => c.id), ['card-0', 'card-1']);
    });

    test('puts due cards first, most overdue first, and respects the '
        'new cards already started today', () {
      var progress = StudyProgress.empty;
      progress = scheduler.review(
        progress: progress,
        cardId: 'card-2',
        grade: Grade.hard, // due day 2
        now: day(1),
      );
      progress = scheduler.review(
        progress: progress,
        cardId: 'card-1',
        grade: Grade.good, // due day 3
        now: day(1),
      );
      expect(
        scheduler
            .dailyQueue(cards: deck.cards, progress: progress, now: day(1))
            .map((c) => c.id),
        isEmpty,
        reason: 'both new cards for day 1 are used up',
      );
      expect(
        scheduler
            .dailyQueue(cards: deck.cards, progress: progress, now: day(3))
            .map((c) => c.id),
        ['card-2', 'card-1', 'card-0', 'card-3'],
      );
    });

    test('a card graded again stays in today\'s queue', () {
      final progress = scheduler.review(
        progress: StudyProgress.empty,
        cardId: 'card-0',
        grade: Grade.again,
        now: day(1),
      );
      expect(
        scheduler
            .dailyQueue(cards: deck.cards, progress: progress, now: day(1))
            .map((c) => c.id),
        ['card-0', 'card-1'],
      );
    });
  });

  group('streak', () {
    StudyProgress studied(List<int> days) =>
        StudyProgress(reviewsByDay: {for (final d in days) dayKey(day(d)): 3});

    test('counts consecutive days ending today', () {
      expect(scheduler.streak(studied([5, 6, 7]), day(7)), 3);
    });

    test("isn't broken until a whole day is missed", () {
      expect(scheduler.streak(studied([5, 6]), day(7)), 2);
      expect(scheduler.streak(studied([5, 6]), day(8)), 0);
    });

    test('a gap ends it', () {
      expect(scheduler.streak(studied([2, 3, 5, 6]), day(6)), 2);
      expect(scheduler.streak(StudyProgress.empty, day(6)), 0);
    });

    test('crosses month boundaries', () {
      final progress = StudyProgress(
        reviewsByDay: {
          dayKey(DateTime(2026, 2, 28, 12)): 1,
          dayKey(DateTime(2026, 3, 1, 12)): 1,
        },
      );
      expect(scheduler.streak(progress, day(1)), 2);
    });
  });

  test('mastery counts new, learning and mastered cards', () {
    final deck = testDeck();
    CardProgress withInterval(String id, int days) => CardProgress(
      cardId: id,
      reps: 3,
      lapses: 0,
      intervalDays: days,
      ease: 2.5,
      due: day(1),
      lastReviewed: day(1),
    );
    final progress = StudyProgress(
      cards: {
        'card-0': withInterval('card-0', 3),
        'card-1': withInterval('card-1', Scheduler.masteredAfterDays),
      },
    );
    final mastery = scheduler.mastery(deck.cards, progress);
    expect(
      (mastery.total, mastery.fresh, mastery.learning, mastery.mastered),
      (4, 2, 1, 1),
    );
    expect(mastery.score, closeTo(1.5 / 4, 1e-9));
    expect(scheduler.statusOf(null), CardStatus.fresh);
  });
}
