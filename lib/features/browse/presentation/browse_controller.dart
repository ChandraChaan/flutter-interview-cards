import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deck/domain/flashcard.dart';
import '../../deck/presentation/deck_providers.dart';
import '../../review/domain/scheduler.dart';
import '../../review/presentation/progress_controller.dart';

/// What the browse list is filtered by. Empty means "everything".
final class BrowseFilter {
  const BrowseFilter({this.chapterId, this.levels = const {}, this.query = ''});

  final String? chapterId;
  final Set<Level> levels;
  final String query;

  bool get isEmpty => chapterId == null && levels.isEmpty && query.isEmpty;

  bool matches(Flashcard card) {
    if (chapterId != null && card.chapterId != chapterId) return false;
    if (levels.isNotEmpty && !levels.contains(card.level)) return false;
    final terms = query.toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((t) => t.isEmpty);
    if (terms.isEmpty) return true;
    final text = '${card.question}\n${card.answer}'.toLowerCase();
    return terms.every(text.contains);
  }
}

final browseFilterProvider =
    NotifierProvider<BrowseFilterController, BrowseFilter>(
      BrowseFilterController.new,
    );

class BrowseFilterController extends Notifier<BrowseFilter> {
  @override
  BrowseFilter build() => const BrowseFilter();

  void setChapter(String? chapterId) => state = BrowseFilter(
    chapterId: chapterId,
    levels: state.levels,
    query: state.query,
  );

  void toggleLevel(Level level) => state = BrowseFilter(
    chapterId: state.chapterId,
    levels: state.levels.contains(level)
        ? ({...state.levels}..remove(level))
        : {...state.levels, level},
    query: state.query,
  );

  void setQuery(String query) => state = BrowseFilter(
    chapterId: state.chapterId,
    levels: state.levels,
    query: query,
  );

  void clear() => state = const BrowseFilter();
}

final class BrowseItem {
  const BrowseItem({
    required this.card,
    required this.chapter,
    required this.status,
  });

  final Flashcard card;
  final Chapter chapter;
  final CardStatus status;
}

final class BrowseResults {
  const BrowseResults({required this.chapters, required this.items});

  /// Every chapter, for the chapter filter.
  final List<Chapter> chapters;
  final List<BrowseItem> items;
}

final browseResultsProvider = FutureProvider<BrowseResults>((ref) async {
  final deck = await ref.watch(deckProvider.future);
  final progress = await ref.watch(progressControllerProvider.future);
  final scheduler = ref.watch(schedulerProvider);
  final filter = ref.watch(browseFilterProvider);
  return BrowseResults(
    chapters: deck.chapters,
    items: [
      for (final card in deck.cards)
        if (filter.matches(card))
          BrowseItem(
            card: card,
            chapter: deck.chapterOf(card),
            status: scheduler.statusOf(progress.cards[card.id]),
          ),
    ],
  );
});
