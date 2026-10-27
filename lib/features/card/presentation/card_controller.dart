import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deck/domain/flashcard.dart';
import '../../deck/presentation/deck_providers.dart';

final class CardDetail {
  const CardDetail({
    required this.card,
    required this.chapter,
    required this.handbookUrl,
  });

  final Flashcard card;
  final Chapter chapter;
  final Uri handbookUrl;
}

/// The card a shared link points to, or null if no card has that ID.
final cardDetailProvider = FutureProvider.family<CardDetail?, String>((
  ref,
  id,
) async {
  final deck = await ref.watch(deckProvider.future);
  final card = deck.cardById(id);
  if (card == null) return null;
  return CardDetail(
    card: card,
    chapter: deck.chapterOf(card),
    handbookUrl: deck.handbookUrl(card),
  );
});
