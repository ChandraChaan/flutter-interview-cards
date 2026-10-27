import '../../deck/domain/flashcard.dart';

/// Which cards the daily queue draws from. An empty set means "all", so a
/// new chapter in the handbook is included by default.
final class StudyFocus {
  const StudyFocus({this.chapterIds = const {}, this.levels = const {}});

  static const all = StudyFocus();

  final Set<String> chapterIds;
  final Set<Level> levels;

  bool get isAll => chapterIds.isEmpty && levels.isEmpty;

  bool includes(Flashcard card) =>
      (chapterIds.isEmpty || chapterIds.contains(card.chapterId)) &&
      (levels.isEmpty || levels.contains(card.level));

  StudyFocus toggleChapter(String id) =>
      StudyFocus(chapterIds: _toggle(chapterIds, id), levels: levels);

  StudyFocus toggleLevel(Level level) =>
      StudyFocus(chapterIds: chapterIds, levels: _toggle(levels, level));

  @override
  bool operator ==(Object other) =>
      other is StudyFocus &&
      other.chapterIds.length == chapterIds.length &&
      other.chapterIds.containsAll(chapterIds) &&
      other.levels.length == levels.length &&
      other.levels.containsAll(levels);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(chapterIds),
    Object.hashAllUnordered(levels),
  );
}

Set<T> _toggle<T>(Set<T> set, T value) =>
    set.contains(value) ? ({...set}..remove(value)) : {...set, value};
