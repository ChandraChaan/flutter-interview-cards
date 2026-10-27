import 'dart:io';

import 'package:flutter_interview_cards/features/deck/data/asset_deck_repository.dart';
import 'package:flutter_interview_cards/features/deck/domain/deck_repository.dart';
import 'package:flutter_interview_cards/features/deck/domain/flashcard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes the generated asset', () {
    final deck = decodeDeck(File('assets/cards.json').readAsStringSync());
    expect(deck.cards, hasLength(67));
    expect(deck.chapters, hasLength(10));
    expect(deck.repository, 'ChandraChaan/flutter-architect-handbook');
    expect(deck.commit, matches(RegExp(r'^[0-9a-f]{40}$')));

    final card = deck.cardById('final-vs-const-vs-late')!;
    expect(card.level, Level.junior);
    expect(deck.chapterOf(card).title, 'Dart essentials');
    expect(
      deck.handbookUrl(card).toString(),
      'https://github.com/ChandraChaan/flutter-architect-handbook/blob/main/'
      'chapters/01-dart.md#-final-vs-const-vs-late',
    );
    expect(deck.cardById('nope'), isNull);
  });

  test('loads through the asset bundle', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final deck = await const AssetDeckRepository().load();
    expect(deck.cards, hasLength(67));
  });

  test('malformed JSON becomes a DeckLoadException', () {
    expect(() => decodeDeck('{'), throwsA(isA<DeckLoadException>()));
    expect(
      () => decodeDeck('{"source": {}, "chapters": [], "cards": []}'),
      throwsA(isA<DeckLoadException>()),
    );
    expect(
      () => const AssetDeckRepository(path: 'assets/missing.json').load(),
      throwsA(isA<DeckLoadException>()),
    );
  });
}
