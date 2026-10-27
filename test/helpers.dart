import 'package:flutter_interview_cards/features/deck/domain/deck_repository.dart';
import 'package:flutter_interview_cards/features/deck/domain/flashcard.dart';

/// A small deck: two chapters, four cards.
Deck testDeck() => Deck(
  repository: 'ChandraChaan/flutter-architect-handbook',
  commit: 'abc123',
  chapters: const [
    Chapter(id: 'dart', number: 1, title: 'Dart', path: 'chapters/01-dart.md'),
    Chapter(id: 'ui', number: 2, title: 'UI', path: 'chapters/02-ui.md'),
  ],
  cards: [
    for (final (i, (chapter, level)) in [
      ('dart', Level.junior),
      ('dart', Level.senior),
      ('ui', Level.senior),
      ('ui', Level.architect),
    ].indexed)
      Flashcard(
        id: 'card-$i',
        chapterId: chapter,
        level: level,
        question: 'Question $i about `topic$i`?',
        answer: 'Answer $i explains topic$i.\n\n```dart\nfinal x$i = $i;\n```',
        anchor: '-card-$i',
      ),
  ],
);

class FakeDeckRepository implements DeckRepository {
  FakeDeckRepository([Deck? deck]) : deck = deck ?? testDeck();

  final Deck deck;
  var fail = false;

  @override
  Future<Deck> load() async {
    if (fail) throw const DeckLoadException('offline');
    return deck;
  }
}
