/// The handbook's three levels: 🟢 junior, 🟡 senior, 🔴 architect.
enum Level { junior, senior, architect }

final class Chapter {
  const Chapter({
    required this.id,
    required this.number,
    required this.title,
    required this.path,
  });

  final String id;
  final int number;
  final String title;

  /// Path of the chapter file in the handbook repository.
  final String path;

  @override
  bool operator ==(Object other) =>
      other is Chapter &&
      other.id == id &&
      other.number == number &&
      other.title == title &&
      other.path == path;

  @override
  int get hashCode => Object.hash(id, number, title, path);
}

final class Flashcard {
  const Flashcard({
    required this.id,
    required this.chapterId,
    required this.level,
    required this.question,
    required this.answer,
    required this.anchor,
  });

  final String id;
  final String chapterId;
  final Level level;

  /// Question text; may contain inline Markdown code spans.
  final String question;

  /// Answer as Markdown.
  final String answer;

  /// The question's heading anchor in the handbook on GitHub.
  final String anchor;

  @override
  bool operator ==(Object other) =>
      other is Flashcard &&
      other.id == id &&
      other.chapterId == chapterId &&
      other.level == level &&
      other.question == question &&
      other.answer == answer &&
      other.anchor == anchor;

  @override
  int get hashCode =>
      Object.hash(id, chapterId, level, question, answer, anchor);
}

/// Every card from the handbook, in handbook order.
final class Deck {
  Deck({
    required this.repository,
    required this.commit,
    required List<Chapter> chapters,
    required List<Flashcard> cards,
  }) : chapters = List.unmodifiable(chapters),
       cards = List.unmodifiable(cards),
       _cardsById = {for (final card in cards) card.id: card},
       _chaptersById = {for (final chapter in chapters) chapter.id: chapter};

  /// GitHub `owner/name` of the handbook.
  final String repository;

  /// Handbook commit the cards were imported from.
  final String commit;
  final List<Chapter> chapters;
  final List<Flashcard> cards;
  final Map<String, Flashcard> _cardsById;
  final Map<String, Chapter> _chaptersById;

  Flashcard? cardById(String id) => _cardsById[id];

  Chapter chapterOf(Flashcard card) => _chaptersById[card.chapterId]!;

  /// Link to the card's section of the handbook on GitHub.
  Uri handbookUrl(Flashcard card) => Uri.parse(
    'https://github.com/$repository/blob/main/${chapterOf(card).path}'
    '#${card.anchor}',
  );
}
