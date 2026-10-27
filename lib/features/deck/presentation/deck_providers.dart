import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/asset_deck_repository.dart';
import '../domain/flashcard.dart';

final deckProvider = FutureProvider<Deck>(
  (ref) => ref.watch(deckRepositoryProvider).load(),
);
