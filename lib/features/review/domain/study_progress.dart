/// How well you knew a card, from worst to best.
enum Grade { again, hard, good, easy }

/// Where one card stands in the spaced-repetition schedule.
final class CardProgress {
  const CardProgress({
    required this.cardId,
    required this.reps,
    required this.lapses,
    required this.intervalDays,
    required this.ease,
    required this.due,
    required this.lastReviewed,
  });

  final String cardId;

  /// Successful reviews in a row; reset to 0 by [Grade.again].
  final int reps;

  /// Times the card was forgotten after it had been learned.
  final int lapses;

  /// Days until the next review; 0 means "again today".
  final int intervalDays;

  /// Interval multiplier (SM-2 "ease factor"), never below 1.3.
  final double ease;

  /// When the card is next due, in UTC.
  final DateTime due;

  /// When the card was last reviewed, in UTC.
  final DateTime lastReviewed;

  CardProgress copyWith({
    int? reps,
    int? lapses,
    int? intervalDays,
    double? ease,
    DateTime? due,
    DateTime? lastReviewed,
  }) => CardProgress(
    cardId: cardId,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    intervalDays: intervalDays ?? this.intervalDays,
    ease: ease ?? this.ease,
    due: due ?? this.due,
    lastReviewed: lastReviewed ?? this.lastReviewed,
  );

  @override
  bool operator ==(Object other) =>
      other is CardProgress &&
      other.cardId == cardId &&
      other.reps == reps &&
      other.lapses == lapses &&
      other.intervalDays == intervalDays &&
      other.ease == ease &&
      other.due == due &&
      other.lastReviewed == lastReviewed;

  @override
  int get hashCode =>
      Object.hash(cardId, reps, lapses, intervalDays, ease, due, lastReviewed);

  @override
  String toString() =>
      'CardProgress($cardId, reps: $reps, interval: $intervalDays, '
      'ease: $ease, due: $due)';
}

/// Everything the app remembers about your studying.
final class StudyProgress {
  StudyProgress({
    Map<String, CardProgress> cards = const {},
    Map<String, int> reviewsByDay = const {},
    Map<String, int> newCardsByDay = const {},
  }) : cards = Map.unmodifiable(cards),
       reviewsByDay = Map.unmodifiable(reviewsByDay),
       newCardsByDay = Map.unmodifiable(newCardsByDay);

  static final empty = StudyProgress();

  /// Schedule per card ID. Cards missing here are new.
  final Map<String, CardProgress> cards;

  /// Reviews per local day (`yyyy-mm-dd`), for the streak.
  final Map<String, int> reviewsByDay;

  /// New cards started per local day, for the daily new-card limit.
  final Map<String, int> newCardsByDay;

  StudyProgress copyWith({
    Map<String, CardProgress>? cards,
    Map<String, int>? reviewsByDay,
    Map<String, int>? newCardsByDay,
  }) => StudyProgress(
    cards: cards ?? this.cards,
    reviewsByDay: reviewsByDay ?? this.reviewsByDay,
    newCardsByDay: newCardsByDay ?? this.newCardsByDay,
  );

  @override
  bool operator ==(Object other) =>
      other is StudyProgress &&
      _mapEquals(other.cards, cards) &&
      _mapEquals(other.reviewsByDay, reviewsByDay) &&
      _mapEquals(other.newCardsByDay, newCardsByDay);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(cards.values),
    Object.hashAllUnordered(reviewsByDay.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(newCardsByDay.entries.map((e) => (e.key, e.value))),
  );
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) =>
    a.length == b.length &&
    a.entries.every((e) => b.containsKey(e.key) && b[e.key] == e.value);
