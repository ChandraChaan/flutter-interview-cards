import 'flashcard.dart';

abstract interface class DeckRepository {
  /// Loads every card. Throws a [DeckLoadException] if the deck is unreadable.
  Future<Deck> load();
}

final class DeckLoadException implements Exception {
  const DeckLoadException(this.cause);

  final Object cause;

  @override
  String toString() => 'DeckLoadException: $cause';
}
